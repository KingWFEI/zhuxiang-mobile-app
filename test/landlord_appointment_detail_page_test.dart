import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/features/appointment/data/models/appointment_models.dart';
import 'package:zhuxiang_app/features/appointment/data/providers/appointment_providers.dart';
import 'package:zhuxiang_app/features/appointment/data/services/appointment_service.dart';
import 'package:zhuxiang_app/features/appointment/presentation/pages/landlord_appointment_detail_page.dart';

void main() {
  testWidgets('landlord reschedule submits a server-provided available slot', (
    tester,
  ) async {
    final service = _FakeAppointmentService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appointmentServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: LandlordAppointmentDetailPage(appointmentId: 'appointment-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('建议改期'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('仅展示服务端开放且尚未被预约的时间'), findsOneWidget);
    expect(find.text('10:00-11:00'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '租客希望调整时间');
    await tester.pump();
    await tester.tap(find.text('提交改期'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(service.proposedStartAt, service.slotStart);
    expect(service.reason, '租客希望调整时间');
    expect(find.text('操作成功'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

class _FakeAppointmentService extends AppointmentService {
  _FakeAppointmentService() : super(ApiClient());

  final slotStart = DateTime.now()
      .add(const Duration(days: 1))
      .copyWith(hour: 10, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  DateTime? proposedStartAt;
  String? reason;

  late final AppointmentDetail appointmentDetail = AppointmentDetail(
    id: 'appointment-1',
    status: 'PENDING_CONFIRMATION',
    sourceType: 'LANDLORD',
    sourceLabel: '个人房源',
    viewingMode: 'LANDLORD_HOSTED',
    viewingModeLabel: '房东陪同',
    appointmentStartAt: slotStart,
    appointmentEndAt: slotStart.add(const Duration(hours: 1)),
    proposedStartAt: null,
    proposedEndAt: null,
    rescheduleReason: '',
    house: const AppointmentHouseSummary(
      id: 'house-1',
      title: '测试房源',
      coverImage: '',
      address: '测试地址',
    ),
    host: null,
    contactName: '测试租客',
    contactPhone: '13800138000',
    remark: '',
    meetingPoint: '',
    viewingInstruction: '',
    rejectReason: '',
    cancelReason: '',
    checkinCode: '',
    accessStatus: 'NOT_REQUIRED',
    availableActions: const ['RESCHEDULE'],
    statusLogs: const [],
  );

  @override
  Future<AppointmentDetail> landlordDetail(String appointmentId) async {
    return appointmentDetail;
  }

  @override
  Future<ViewingSlotResult> getViewingSlots(String houseId) async {
    return ViewingSlotResult(
      houseId: houseId,
      viewingMode: 'LANDLORD_HOSTED',
      requiresConfirmation: true,
      dates: [
        ViewingSlotDay(
          date: DateTime(slotStart.year, slotStart.month, slotStart.day),
          slots: [
            ViewingSlot(
              startAt: slotStart,
              endAt: slotStart.add(const Duration(hours: 1)),
              available: true,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<AppointmentDetail> landlordReschedule(
    String appointmentId, {
    required DateTime proposedStartAt,
    required String reason,
  }) async {
    this.proposedStartAt = proposedStartAt;
    this.reason = reason;
    return appointmentDetail;
  }
}
