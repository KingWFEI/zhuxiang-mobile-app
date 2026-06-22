import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/lock/data/models/unlock_record_model.dart';
import 'package:zhuxiang_app/features/lock/data/providers/lock_record_providers.dart';
import 'package:zhuxiang_app/features/lock/data/services/lock_record_service.dart';
import 'package:zhuxiang_app/features/lock/domain/entities/unlock_record.dart';
import 'package:zhuxiang_app/features/lock/presentation/pages/unlock_records_page.dart';

void main() {
  test('UnlockRecordModel adapts backend fields', () {
    final record = UnlockRecordModel({
      'recordId': 'record-api-1',
      'houseTitle': '3栋2单元1201',
      'lockName': '客厅智能门锁',
      'method': 'remote',
      'status': 'failed',
      'createdAt': '2026-06-22T14:32:00',
      'operatorType': 'housekeeper',
      'operatorName': '小住管家',
      'failReason': '网络请求超时',
    }).toEntity();

    expect(record.id, 'record-api-1');
    expect(record.unlockMethod, UnlockMethod.remote);
    expect(record.unlockResult, UnlockResult.failed);
    expect(record.operatorType, UnlockOperatorType.housekeeper);
    expect(record.failureReason, '网络请求超时');
  });

  test('mock service contains required unlock scenarios', () async {
    final overview = await const MockLockRecordService().fetchOverview();

    expect(overview.records, hasLength(8));
    expect(
      overview.records.any(
        (record) =>
            record.unlockMethod == UnlockMethod.bluetooth && record.isSuccess,
      ),
      isTrue,
    );
    expect(
      overview.records.any(
        (record) =>
            record.unlockMethod == UnlockMethod.remote && !record.isSuccess,
      ),
      isTrue,
    );
    expect(
      overview.records.any(
        (record) => record.operatorType == UnlockOperatorType.admin,
      ),
      isTrue,
    );
  });

  testWidgets('unlock records page filters and opens detail sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lockRecordServiceProvider.overrideWithValue(
            const MockLockRecordService(),
          ),
        ],
        child: const MaterialApp(home: UnlockRecordsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('开门记录'), findsOneWidget);
    expect(find.text('客厅智能门锁'), findsWidgets);
    expect(find.byKey(const ValueKey('unlock-001')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('unlock-filter-failed')));
    await tester.pumpAndSettle();
    expect(find.text('蓝牙连接超时'), findsOneWidget);
    expect(find.byKey(const ValueKey('unlock-001')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('unlock-filter-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unlock-001')));
    await tester.pumpAndSettle();
    expect(find.text('开门记录详情'), findsOneWidget);
    expect(find.text('开锁结果'), findsOneWidget);
  });

  testWidgets('unlock records page renders empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lockRecordServiceProvider.overrideWithValue(
            _FakeLockRecordService(overview: _emptyOverview),
          ),
        ],
        child: const MaterialApp(home: UnlockRecordsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂无开门记录'), findsOneWidget);
  });

  testWidgets('unlock records page renders error and retry state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lockRecordServiceProvider.overrideWithValue(
            const _FakeLockRecordService(shouldFail: true),
          ),
        ],
        child: const MaterialApp(home: UnlockRecordsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('开门记录加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}

class _FakeLockRecordService implements LockRecordServiceContract {
  const _FakeLockRecordService({this.overview, this.shouldFail = false});

  final UnlockRecordOverview? overview;
  final bool shouldFail;

  @override
  Future<UnlockRecordOverview> fetchOverview() async {
    if (shouldFail) throw Exception('服务不可用');
    return overview!;
  }
}

final _emptyOverview = UnlockRecordOverview(
  lockStatus: CurrentLockStatus(
    houseName: '3栋2单元1201',
    lockName: '客厅智能门锁',
    permissionStatus: LockPermissionStatus.active,
    lastUnlockTime: DateTime(2026, 6, 22, 14, 32),
    supportedMethods: const [UnlockMethod.bluetooth],
  ),
  records: const [],
);
