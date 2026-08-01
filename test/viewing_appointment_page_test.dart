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

    expect(find.text('选择看房时间'), findsOneWidget);
    expect(find.text('填写联系信息'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appointment-time-11:00')));
    await tester.pump();
    expect(find.text('11:00'), findsOneWidget);

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
}

Widget _testApp() {
  return ProviderScope(
    overrides: [
      appointmentServiceProvider.overrideWithValue(_FakeAppointmentService()),
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
  _FakeAppointmentService() : super(ApiClient());

  @override
  Future<ViewingSlotResult> getViewingSlots(String houseId) async {
    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return ViewingSlotResult(
      houseId: houseId,
      viewingMode: 'SELF_SERVICE_LOCK',
      requiresConfirmation: false,
      dates: [
        ViewingSlotDay(
          date: date,
          slots: [
            ViewingSlot(
              startAt: DateTime(date.year, date.month, date.day, 10),
              endAt: DateTime(date.year, date.month, date.day, 11),
              available: true,
            ),
            ViewingSlot(
              startAt: DateTime(date.year, date.month, date.day, 11),
              endAt: DateTime(date.year, date.month, date.day, 12),
              available: true,
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
