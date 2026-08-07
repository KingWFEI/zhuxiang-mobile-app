import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/features/appointment/data/models/appointment_models.dart';
import 'package:zhuxiang_app/features/appointment/data/providers/appointment_providers.dart';
import 'package:zhuxiang_app/features/appointment/data/services/appointment_service.dart';
import 'package:zhuxiang_app/features/appointment/presentation/pages/appointment_detail_page.dart';

void main() {
  testWidgets('租客预约详情支持下拉刷新', (tester) async {
    final service = _FakeAppointmentService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const AppointmentDetailPage(appointmentId: 'appointment-1'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appointmentServiceProvider.overrideWithValue(service)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appointment-detail-refresh')), findsOneWidget);
    expect(service.detailRequests, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.detailRequests, 2);
    expect(find.text('测试平台房源'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAppointmentService extends AppointmentService {
  _FakeAppointmentService() : super(ApiClient());

  int detailRequests = 0;

  @override
  Future<AppointmentDetail> detail(String appointmentId) async {
    detailRequests += 1;
    final startAt = DateTime.now().add(const Duration(hours: 1));
    return AppointmentDetail(
      id: appointmentId,
      status: 'CONFIRMED',
      sourceType: 'PLATFORM',
      sourceLabel: '平台自营',
      viewingMode: 'SELF_SERVICE_LOCK',
      viewingModeLabel: '智能门锁自助看房',
      appointmentStartAt: startAt,
      appointmentEndAt: startAt.add(const Duration(hours: 1)),
      proposedStartAt: null,
      proposedEndAt: null,
      rescheduleReason: '',
      house: const AppointmentHouseSummary(
        id: 'house-1',
        title: '测试平台房源',
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
      accessStatus: 'PENDING',
      availableActions: const [],
      statusLogs: const [],
    );
  }
}
