import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/lock/application/tenant_lock_unlock_controller.dart';
import 'package:zhuxiang_app/features/lock/data/models/tenant_lock_unlock_data.dart';
import 'package:zhuxiang_app/features/lock/data/repositories/tenant_lock_repository.dart';
import 'package:zhuxiang_app/features/lock/data/providers/tenant_lock_providers.dart';
import 'package:zhuxiang_app/features/lock/presentation/pages/tenant_lock_unlock_page.dart';
import 'package:zhuxiang_app/features/staff/lock_initial/services/ttlock_ble_service.dart';

void main() {
  test('tenant lock repository requests lease-scoped unlock data', () async {
    final apiClient = _RecordingApiClient(
      ApiSuccess(
        Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          data: {'code': 200, 'message': '查询成功', 'data': _unlockDataJson},
        ),
      ),
    );

    final data = await TenantLockRepository(
      apiClient,
    ).getUnlockData('lease/001');

    expect(apiClient.requestedPath, '/leases/lease%2F001/lock/unlock-data');
    expect(data.leaseId, 'lease_001');
    expect(data.ttlockKeyId, 987654);
    expect(data.isActive, isTrue);
  });

  test(
    'controller fetches eKey data before scanning and matches exact MAC',
    () async {
      final events = <String>[];
      final bleService = _FakeBleService(
        events: events,
        scannedDevices: [_device('586fc793b6e7')],
      );
      final controller = TenantLockUnlockController(
        leaseId: 'lease_001',
        repository: _FakeRepository(events: events),
        ttlockBleService: bleService,
      );
      addTearDown(controller.dispose);

      await controller.load();
      await Future<void>.delayed(Duration.zero);

      expect(events.first, 'repository');
      expect(events, containsAllInOrder(['permissions', 'init', 'scan']));
      expect(controller.state.stage, TenantLockUnlockStage.matched);
      expect(controller.state.targetMatched, isTrue);
      expect(bleService.stopCount, greaterThanOrEqualTo(1));
    },
  );

  test(
    'controller ignores other locks and stops scanning on timeout',
    () async {
      final bleService = _FakeBleService(
        scannedDevices: [_device('AA:BB:CC:DD:EE:FF')],
      );
      final controller = TenantLockUnlockController(
        leaseId: 'lease_001',
        repository: _FakeRepository(),
        ttlockBleService: bleService,
        scanTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.state.stage, TenantLockUnlockStage.scanFailed);
      expect(controller.state.targetMatched, isFalse);
      expect(bleService.stopCount, greaterThanOrEqualTo(1));
    },
  );

  test('controller unlocks with backend eKey lockData', () async {
    final bleService = _FakeBleService(
      scannedDevices: [_device('58:6F:C7:93:B6:E7')],
      unlockResult: UnlockResult.success(lockData: 'rotated-lock-data'),
    );
    final controller = TenantLockUnlockController(
      leaseId: 'lease_001',
      repository: _FakeRepository(),
      ttlockBleService: bleService,
    );
    addTearDown(controller.dispose);

    await controller.load();
    await Future<void>.delayed(Duration.zero);
    await controller.unlock();

    expect(bleService.receivedLockData, 'tenant-ekey-lock-data');
    expect(controller.state.stage, TenantLockUnlockStage.unlockSuccess);
    expect(controller.state.unlockData?.lockData, 'rotated-lock-data');
  });

  testWidgets(
    'tenant unlock page follows the lock hero layout without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantLockRepositoryProvider.overrideWithValue(_FakeRepository()),
            tenantTtlockBleServiceProvider.overrideWithValue(
              _FakeBleService(scannedDevices: [_device('58:6F:C7:93:B6:E7')]),
            ),
          ],
          child: const MaterialApp(
            home: TenantLockUnlockPage(leaseId: 'lease_001'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('蓝牙开锁'), findsOneWidget);
      expect(find.text('蓝牙已自动连接'), findsOneWidget);
      expect(find.text('点击开锁'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('unlock-radiating-waves')),
        findsOneWidget,
      );
      expect(find.text('门锁信息'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _unlockDataJson = <String, dynamic>{
  'leaseId': 'lease_001',
  'smartLockId': 'smart-lock-001',
  'houseName': '春熙路青年公寓',
  'roomName': '3栋2单元1201',
  'lockName': 'S8503_e7b693',
  'lockMac': '58:6F:C7:93:B6:E7',
  'lockData': 'tenant-ekey-lock-data',
  'ttlockKeyId': 987654,
  'startTime': '2026-06-25 00:00:00',
  'endTime': '2026-07-25 23:59:59',
  'permissionStatus': 'ACTIVE',
  'bluetoothUnlockAvailable': true,
  'passcodeAvailable': false,
  'passcodeStatus': 'FAILED',
  'passcodeStartTime': '',
  'passcodeEndTime': '',
};

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.result);

  final ApiResult<Response<dynamic>> result;
  String? requestedPath;

  @override
  Future<ApiResult<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedPath = path;
    return result;
  }
}

class _FakeRepository implements TenantLockRepositoryContract {
  _FakeRepository({this.events});

  final List<String>? events;

  @override
  Future<TenantLockUnlockData> getUnlockData(String leaseId) async {
    events?.add('repository');
    return TenantLockUnlockData.fromJson(_unlockDataJson);
  }

  @override
  Future<TenantPasscode> getPasscode(String leaseId) async {
    events?.add('getPasscode');
    return TenantPasscode.fromJson(const {
      'endTime': '2026-07-25 23:59:59',
      'firstUseNotice': '首次使用需激活',
      'leaseId': 'lease_001',
      'passcode': '123456',
      'passcodeType': 'PERIOD',
      'roomName': '3栋2单元1201',
      'smartLockId': 'smart-lock-001',
      'startTime': '2026-06-25 00:00:00',
      'status': 'ACTIVE',
    });
  }

  @override
  Future<TenantPasscode> retryPasscode(String leaseId) async {
    events?.add('retryPasscode');
    return TenantPasscode.fromJson(const {
      'endTime': '2026-07-25 23:59:59',
      'firstUseNotice': '首次使用需激活',
      'leaseId': 'lease_001',
      'passcode': '654321',
      'passcodeType': 'PERIOD',
      'roomName': '3栋2单元1201',
      'smartLockId': 'smart-lock-001',
      'startTime': '2026-06-25 00:00:00',
      'status': 'ACTIVE',
    });
  }
}

class _FakeBleService implements TtlockBleServiceContract {
  _FakeBleService({
    this.events,
    this.scannedDevices = const [],
    UnlockResult? unlockResult,
  }) : unlockResult =
           unlockResult ??
           UnlockResult.success(lockData: 'tenant-ekey-lock-data');

  final List<String>? events;
  final List<ScannedLockDevice> scannedDevices;
  final UnlockResult unlockResult;
  int stopCount = 0;
  String? receivedLockData;

  @override
  Future<void> init() async {
    events?.add('init');
  }

  @override
  Future<bool> requestBlePermissions() async {
    events?.add('permissions');
    return true;
  }

  @override
  Future<void> startScanning({
    required void Function(ScannedLockDevice device) onDeviceFound,
    bool requestPermissions = true,
  }) async {
    events?.add('scan');
    for (final device in scannedDevices) {
      onDeviceFound(device);
    }
  }

  @override
  Future<void> stopScanning() async {
    stopCount++;
  }

  @override
  Future<UnlockResult> unlockByLockData(String lockData) async {
    receivedLockData = lockData;
    return unlockResult;
  }
}

ScannedLockDevice _device(String mac) {
  final raw = TTLockScanModel({
    'lockName': 'S8503_e7b693',
    'lockMac': mac,
    'isInited': true,
    'isAllowUnlock': true,
    'electricQuantity': 80,
    'lockVersion': '',
    'lockSwitchState': 0,
    'rssi': -50,
    'oneMeterRssi': -40,
    'timestamp': 0,
  });
  return ScannedLockDevice.fromScanModel(raw);
}
