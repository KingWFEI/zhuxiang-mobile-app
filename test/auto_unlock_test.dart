import 'package:flutter_test/flutter_test.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:zhuxiang_app/core/network/api_interceptor.dart';
import 'package:zhuxiang_app/features/lock/application/auto_unlock_controller.dart';
import 'package:zhuxiang_app/features/lock/data/models/tenant_lock_unlock_data.dart';
import 'package:zhuxiang_app/features/lock/data/repositories/tenant_lock_repository.dart';
import 'package:zhuxiang_app/features/staff/lock_initial/services/ttlock_ble_service.dart';

void main() {
  test('auto unlock is disabled by default and does not scan', () async {
    final ble = _FakeBleService();
    final controller = _controller(ble: ble);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state.status, AutoUnlockState.disabled);
    expect(controller.state.enabled, isFalse);
    expect(ble.startCount, 0);
  });

  test('background stops scanning and foreground fetches fresh data', () async {
    final ble = _FakeBleService();
    final repository = _FakeAutoUnlockRepository();
    final controller = _controller(ble: ble, repository: repository);
    addTearDown(controller.dispose);

    await controller.enable();
    expect(repository.fetchCount, 1);
    expect(controller.state.status, AutoUnlockState.scanning);

    await controller.onAppBackgrounded();
    expect(controller.state.status, AutoUnlockState.stopped);
    expect(ble.stopCount, greaterThan(0));

    await controller.onAppForegrounded();
    expect(repository.fetchCount, 2);
    expect(controller.state.status, AutoUnlockState.scanning);
  });

  test('leaving lock page stops scanning immediately', () async {
    final ble = _FakeBleService();
    final controller = _controller(ble: ble);
    addTearDown(controller.dispose);
    await controller.enable();

    await controller.onPageActiveChanged(false);

    expect(ble.stopCount, greaterThan(0));
    expect(controller.state.status, AutoUnlockState.stopped);
  });

  test('bluetooth off or missing permissions blocks auto unlock', () async {
    final bluetoothOff = _FakeBleService()..bluetoothEnabled = false;
    final bluetoothController = _controller(ble: bluetoothOff);
    addTearDown(bluetoothController.dispose);
    await bluetoothController.enable();
    expect(bluetoothController.state.status, AutoUnlockState.blocked);
    expect(bluetoothController.state.message, contains('蓝牙'));

    final denied = _FakeBleService()..permissionsGranted = false;
    final permissionController = _controller(ble: denied);
    addTearDown(permissionController.dispose);
    await permissionController.enable();
    expect(permissionController.state.status, AutoUnlockState.blocked);
    expect(permissionController.state.message, contains('权限'));
  });

  test('only exact target MAC triggers scanning state update', () async {
    final ble = _FakeBleService();
    final controller = _controller(ble: ble);
    addTearDown(controller.dispose);
    await controller.enable();

    ble.emit(_device('AA:BB:CC:DD:EE:FF', -50));
    expect(controller.state.targetSeen, isFalse);

    ble.emit(_device('58-6f-c7-93-b6-e7', -55));
    expect(controller.state.targetSeen, isTrue);
  });

  test('RSSI below threshold does not trigger unlock', () async {
    final ble = _FakeBleService();
    final controller = _controller(ble: ble);
    addTearDown(controller.dispose);
    await controller.enable();

    ble.emit(_device(_targetMac, -70));
    await Future<void>.delayed(Duration.zero);

    expect(ble.unlockCount, 0);
    expect(controller.state.status, AutoUnlockState.scanning);
    expect(controller.state.message, contains('未达阈值'));
  });

  test('single RSSI above threshold triggers immediate unlock and 60s cooldown', () async {
    final ble = _FakeBleService();
    final repository = _FakeAutoUnlockRepository();
    final controller = _controller(ble: ble, repository: repository);
    addTearDown(controller.dispose);
    await controller.enable();

    ble.emit(_device(_targetMac, -55));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(ble.unlockCount, 1);
    expect(controller.state.status, AutoUnlockState.cooldown);
    // 服务端下发 cooldownSeconds=30，此处验证使用该值
    expect(controller.state.cooldownRemaining, greaterThan(0));
    expect(repository.records, hasLength(1));
    expect(repository.records.single.result, 'SUCCESS');

    // 冷却期内即使再次收到强信号也不重复开锁
    ble.emit(_device(_targetMac, -40));
    expect(ble.unlockCount, 1);
  });

  test('three consecutive failures block auto unlock immediately without cooldown', () async {
    final ble = _FakeBleService(
      unlockResult: UnlockResult.failure(
        errorCode: 'LOCK_BUSY',
        errorMessage: 'busy',
      ),
    );
    final controller = _controller(
      ble: ble,
      consecutiveFailuresThreshold: 3,
    );
    addTearDown(controller.dispose);
    await controller.enable();

    for (var attempt = 0; attempt < 3; attempt++) {
      ble.emit(_device(_targetMac, -55));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // 每次失败后状态应回到 scanning（立即重扫）
      if (attempt < 2) {
        expect(controller.state.status, AutoUnlockState.scanning,
            reason: '失败后应立即重新扫描');
      }
    }

    expect(ble.unlockCount, 3);
    expect(controller.state.status, AutoUnlockState.blocked);
    expect(controller.state.enabled, isFalse);
    expect(controller.state.consecutiveFailures, 3);
  });

  test('low battery blocks and turns off auto unlock', () async {
    final preference = _FakePreferenceStore();
    final controller = _controller(
      ble: _FakeBleService(),
      preference: preference,
      environment: const _FakeEnvironment(battery: 14),
    );
    addTearDown(controller.dispose);

    await controller.enable();

    expect(controller.state.status, AutoUnlockState.blocked);
    expect(controller.state.enabled, isFalse);
    expect(preference.enabled, isFalse);
    expect(controller.state.message, contains('15%'));
  });

  test('Dio log sanitizer redacts lock and auth secrets', () {
    final sanitized =
        ApiInterceptor.sanitizeForLog({
              'data': {
                'lockData': 'secret-lock-data',
                'accessToken': 'secret-token',
                'safe': 'visible',
              },
            })
            as Map;
    final data = sanitized['data'] as Map;

    expect(data['lockData'], '[REDACTED]');
    expect(data['accessToken'], '[REDACTED]');
    expect(data['safe'], 'visible');
    expect(sanitized.toString(), isNot(contains('secret-lock-data')));
  });
}

const _targetMac = '58:6F:C7:93:B6:E7';

AutoUnlockController _controller({
  required _FakeBleService ble,
  _FakeAutoUnlockRepository? repository,
  _FakePreferenceStore? preference,
  AutoUnlockEnvironment environment = const _FakeEnvironment(),
  int consecutiveFailuresThreshold = 3,
}) {
  return AutoUnlockController(
    leaseId: 'lease_001',
    repository: repository ?? _FakeAutoUnlockRepository(),
    bleService: ble,
    preferenceStore: preference ?? _FakePreferenceStore(),
    environment: environment,
    consecutiveFailuresThreshold: consecutiveFailuresThreshold,
    healthCheckInterval: const Duration(hours: 1),
    scanNotifyInterval: const Duration(milliseconds: 200),
  );
}

class _FakeAutoUnlockRepository implements AutoUnlockRepositoryContract {
  int fetchCount = 0;
  final List<UnlockRecordRequest> records = [];

  @override
  Future<TenantLockUnlockData> getUnlockData(String leaseId) async {
    fetchCount++;
    return TenantLockUnlockData.fromJson(const {
      'leaseId': 'lease_001',
      'smartLockId': 'smart-lock-001',
      'ttlockLockId': 123456,
      'lockMac': _targetMac,
      'lockData': 'memory-only-lock-data',
      'permissionStatus': 'ACTIVE',
      'leaseValid': true,
      'leaseStatus': 'ACTIVE',
      'bluetoothUnlockAvailable': true,
      'autoUnlockAvailable': true,
      'autoUnlockMinRssi': -60,
      'autoUnlockStableMillis': 2000,
      'autoUnlockCooldownSeconds': 60,
    });
  }

  @override
  Future<void> recordUnlock(
    String leaseId,
    UnlockRecordRequest request,
  ) async {
    records.add(request);
  }
}

class _FakePreferenceStore implements AutoUnlockPreferenceStore {
  bool value = false;

  @override
  bool get enabled => value;

  @override
  Future<void> setEnabled(bool value) async {
    this.value = value;
  }
}

class _FakeEnvironment implements AutoUnlockEnvironment {
  const _FakeEnvironment({this.battery = 80});

  final int battery;

  @override
  Future<String> appVersion() async => '1.0.0+1';

  @override
  Future<int> batteryLevel() async => battery;

  @override
  Future<String> deviceInfo() async => 'test-device';
}

class _FakeBleService implements TtlockBleServiceContract {
  _FakeBleService({UnlockResult? unlockResult})
    : unlockResult =
          unlockResult ?? UnlockResult.success(lockData: 'rotated-lock-data');

  final UnlockResult unlockResult;
  void Function(ScannedLockDevice device)? _callback;
  int startCount = 0;
  int stopCount = 0;
  int unlockCount = 0;
  bool bluetoothEnabled = true;
  bool permissionsGranted = true;

  void emit(ScannedLockDevice device) => _callback?.call(device);

  @override
  Future<void> init() async {}

  @override
  Future<bool> isBluetoothEnabled() async => bluetoothEnabled;

  @override
  Future<bool> requestBlePermissions() async => permissionsGranted;

  @override
  Future<void> startScanning({
    required void Function(ScannedLockDevice device) onDeviceFound,
    bool requestPermissions = true,
    Duration notifyInterval = const Duration(seconds: 1),
  }) async {
    startCount++;
    _callback = onDeviceFound;
  }

  @override
  Future<void> stopScanning() async {
    stopCount++;
    _callback = null;
  }

  @override
  Future<UnlockResult> unlockByLockData(String lockData) async {
    unlockCount++;
    return unlockResult;
  }
}

ScannedLockDevice _device(String mac, int rssi) {
  final raw = TTLockScanModel({
    'lockName': 'target-lock',
    'lockMac': mac,
    'isInited': true,
    'isAllowUnlock': true,
    'electricQuantity': 80,
    'lockVersion': '',
    'lockSwitchState': 0,
    'rssi': rssi,
    'oneMeterRssi': -40,
    'timestamp': 0,
  });
  return ScannedLockDevice.fromScanModel(raw);
}
