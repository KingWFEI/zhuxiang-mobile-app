import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/storage/storage_service.dart';
import 'package:zhuxiang_app/features/appointment/data/models/appointment_models.dart';
import 'package:zhuxiang_app/features/appointment/data/providers/appointment_providers.dart';
import 'package:zhuxiang_app/features/appointment/data/services/appointment_service.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/providers/house_providers.dart';
import 'package:zhuxiang_app/features/rental_flow/presentation/pages/viewing_appointment_page.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  testWidgets('appointment page follows the three-step mobile layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('选择自助看房时间'), findsOneWidget);
    expect(find.text('填写联系信息'), findsOneWidget);
    expect(find.text('智能门锁自助看房'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('appointment-time-11:00')));
    await tester.pump();
    expect(find.text('11:00–12:00'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byKey(const Key('appointment-name-field')),
            matching: find.byType(TextField),
          )
          .first,
      '张女士',
    );
    await tester.pump();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.textContaining('11:00'), findsAtLeastNWidgets(1));
    expect(find.text('张女士'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointment page has no overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();

    expect(find.byKey(const Key('confirm-appointment-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hosted appointment hides smart-lock validity', (tester) async {
    await tester.pumpWidget(
      _testApp(
        service: _FakeAppointmentService(
          viewingMode: 'LANDLORD_HOSTED',
          requiresConfirmation: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('选择陪同看房时间'), findsOneWidget);
    expect(find.text('房东陪同看房'), findsAtLeastNWidgets(1));
    expect(find.text('门锁有效'), findsNothing);
    expect(find.text('当前预约需接待方确认后生效'), findsOneWidget);
  });

  testWidgets('development smart-lock house shows next-whole-hour test slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(service: _FakeAppointmentService(includeTestSlot: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appointment-time-test')), findsOneWidget);
    expect(find.text('测试 · 最近整点'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('提交时按服务器下一个最近整点创建'), findsOneWidget);
  });
}

Widget _testApp({AppointmentService? service}) {
  return ProviderScope(
    overrides: [
      appointmentServiceProvider.overrideWithValue(
        service ?? _FakeAppointmentService(),
      ),
      houseDetailProvider.overrideWith(
        (ref, houseId) async => const ApiSuccess(_house),
      ),
    ],
    child: const MaterialApp(
      home: ViewingAppointmentPage(houseId: 'house-1', houseTitle: '绿城·晓风印月'),
    ),
  );
}

class _FakeAppointmentService extends AppointmentService {
  _FakeAppointmentService({
    this.viewingMode = 'SELF_SERVICE_LOCK',
    this.requiresConfirmation = false,
    this.includeTestSlot = false,
  }) : super(ApiClient());

  final String viewingMode;
  final bool requiresConfirmation;
  final bool includeTestSlot;

  @override
  Future<ViewingSlotResult> getViewingSlots(String houseId) async {
    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final testStart = DateTime(now.year, now.month, now.day, now.hour + 1);
    return ViewingSlotResult(
      houseId: houseId,
      viewingMode: viewingMode,
      requiresConfirmation: requiresConfirmation,
      dates: [
        ViewingSlotDay(
          date: date,
          slots: [
            if (includeTestSlot)
              ViewingSlot(
                startAt: testStart,
                endAt: testStart.add(const Duration(hours: 1)),
                available: true,
                accessValidFrom: testStart.subtract(
                  const Duration(minutes: 10),
                ),
                accessValidTo: testStart.add(const Duration(minutes: 70)),
                testSlot: true,
              ),
            ViewingSlot(
              startAt: DateTime(date.year, date.month, date.day, 10),
              endAt: DateTime(date.year, date.month, date.day, 11),
              available: true,
              accessValidFrom: DateTime(date.year, date.month, date.day, 9, 50),
              accessValidTo: DateTime(date.year, date.month, date.day, 11, 10),
            ),
            ViewingSlot(
              startAt: DateTime(date.year, date.month, date.day, 11),
              endAt: DateTime(date.year, date.month, date.day, 12),
              available: true,
              accessValidFrom: DateTime(
                date.year,
                date.month,
                date.day,
                10,
                50,
              ),
              accessValidTo: DateTime(date.year, date.month, date.day, 12, 10),
            ),
          ],
        ),
      ],
    );
  }
}

const _house = HouseDetail(
  id: 'house-1',
  title: '绿城·晓风印月',
  coverImage: '',
  location: '杭州市',
  community: '余杭区',
  address: '文一西路',
  price: 3680,
  roomType: '3室2厅1卫',
  area: 89,
  floor: '8/18层',
  orientation: '南北通透',
  tags: [],
  facilities: [],
  description: '',
  isSmartLockSupported: true,
  isFavorite: false,
  metro: '',
  decoration: '精装',
  availableDate: '',
);
