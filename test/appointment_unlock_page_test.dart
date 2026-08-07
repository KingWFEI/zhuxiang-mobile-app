import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/features/appointment/data/models/appointment_models.dart';
import 'package:zhuxiang_app/features/appointment/data/providers/appointment_providers.dart';
import 'package:zhuxiang_app/features/appointment/data/services/appointment_service.dart';
import 'package:zhuxiang_app/features/appointment/presentation/pages/appointment_unlock_page.dart';

void main() {
  testWidgets('预约开门页展示期限密码的独立整点有效时间', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentServiceProvider.overrideWithValue(
            _FakeAppointmentService(),
          ),
        ],
        child: const MaterialApp(
          home: AppointmentUnlockPage(appointmentId: 'appointment-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('临时开门密码'), findsOneWidget);
    expect(find.text('839204'), findsOneWidget);
    expect(find.text('密码有效时间'), findsOneWidget);
    expect(find.text('2026-08-03 10:00–11:00'), findsOneWidget);
    expect(find.text('到达门锁后输入密码，并按 # 键确认'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAppointmentService extends AppointmentService {
  _FakeAppointmentService() : super(ApiClient());

  @override
  Future<AppointmentAccess> access(String appointmentId) async {
    return AppointmentAccess(
      status: 'ACTIVE',
      validFrom: DateTime(2026, 8, 3, 9, 50),
      validTo: DateTime(2026, 8, 3, 11, 10),
      bluetoothEnabled: false,
      lockMac: '',
      lockData: '',
      passcodeAvailable: true,
      passcode: '839204',
      passcodeValidFrom: DateTime(2026, 8, 3, 10),
      passcodeValidTo: DateTime(2026, 8, 3, 11),
    );
  }
}
