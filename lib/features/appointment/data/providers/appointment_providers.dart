import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../models/appointment_models.dart';
import '../services/appointment_service.dart';

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(ref.watch(apiClientProvider));
});

final myAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentSummary>>((ref) {
      return ref.watch(appointmentServiceProvider).listMine();
    });

final appointmentDetailProvider = FutureProvider.autoDispose
    .family<AppointmentDetail, String>((ref, appointmentId) {
      return ref.watch(appointmentServiceProvider).detail(appointmentId);
    });

final landlordAppointmentsProvider =
    FutureProvider.autoDispose<List<AppointmentSummary>>((ref) {
      return ref.watch(appointmentServiceProvider).listLandlord();
    });

final landlordAppointmentDetailProvider = FutureProvider.autoDispose
    .family<AppointmentDetail, String>((ref, appointmentId) {
      return ref
          .watch(appointmentServiceProvider)
          .landlordDetail(appointmentId);
    });
