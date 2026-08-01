import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/appointment_models.dart';

class AppointmentService {
  AppointmentService(this._apiClient);

  final ApiClient _apiClient;

  Future<ViewingSlotResult> getViewingSlots(String houseId) {
    return _apiClient
        .get(
          '/houses/${Uri.encodeComponent(houseId)}/viewing-slots',
          queryParameters: {'days': 7},
        )
        .unwrapData(ViewingSlotResult.fromJson);
  }

  Future<AppointmentCreateResult> create({
    required String houseId,
    required DateTime startAt,
    required String contactName,
    required String contactPhone,
    required String remark,
  }) {
    return _apiClient
        .post(
          '/appointments',
          data: {
            'houseId': houseId,
            'appointmentStartAt': _offsetIso(startAt),
            'contactName': contactName,
            'contactPhone': contactPhone,
            'remark': remark,
          },
          options: Options(
            headers: {
              'Idempotency-Key':
                  'appointment-${DateTime.now().microsecondsSinceEpoch}',
            },
          ),
        )
        .unwrapData(AppointmentCreateResult.fromJson);
  }

  Future<List<AppointmentSummary>> listMine({String? status}) {
    return _apiClient
        .get(
          '/appointments/my',
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
            'page': 1,
            'pageSize': 100,
          },
        )
        .unwrapValue((data) {
          final json = data as Map<String, dynamic>;
          return (json['items'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AppointmentSummary.fromJson)
              .toList(growable: false);
        });
  }

  Future<AppointmentDetail> detail(String appointmentId) {
    return _apiClient
        .get('/appointments/${Uri.encodeComponent(appointmentId)}')
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> cancel(String appointmentId, String reason) {
    return _apiClient
        .post(
          '/appointments/${Uri.encodeComponent(appointmentId)}/cancel',
          data: {'reason': reason},
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> acceptReschedule(String appointmentId) {
    return _apiClient
        .post(
          '/appointments/${Uri.encodeComponent(appointmentId)}/reschedule/accept',
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> rejectReschedule(
    String appointmentId,
    String reason,
  ) {
    return _apiClient
        .post(
          '/appointments/${Uri.encodeComponent(appointmentId)}/reschedule/reject',
          data: {'reason': reason},
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentAccess> access(String appointmentId) {
    return _apiClient
        .get('/appointments/${Uri.encodeComponent(appointmentId)}/access')
        .unwrapData(AppointmentAccess.fromJson);
  }

  Future<void> reportUnlock(
    String appointmentId, {
    required bool success,
    String? errorMessage,
  }) {
    return _apiClient
        .post(
          '/appointments/${Uri.encodeComponent(appointmentId)}/unlock-attempts',
          data: {
            'method': 'BLUETOOTH',
            'success': success,
            'errorMessage': errorMessage,
            'occurredAt': _offsetIso(DateTime.now()),
          },
        )
        .unwrapValue((_) {});
  }

  Future<List<AppointmentSummary>> listLandlord({String? status}) {
    return _apiClient
        .get(
          '/landlord/appointments',
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
            'page': 1,
            'pageSize': 100,
          },
        )
        .unwrapValue((data) {
          final json = data as Map<String, dynamic>;
          return (json['items'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AppointmentSummary.fromJson)
              .toList(growable: false);
        });
  }

  Future<AppointmentDetail> landlordDetail(String appointmentId) {
    return _apiClient
        .get('/landlord/appointments/${Uri.encodeComponent(appointmentId)}')
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> landlordConfirm(
    String appointmentId, {
    required String meetingPoint,
    required String instruction,
  }) {
    return _apiClient
        .post(
          '/landlord/appointments/${Uri.encodeComponent(appointmentId)}/confirm',
          data: {
            'meetingPoint': meetingPoint,
            'viewingInstruction': instruction,
          },
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> landlordReject(
    String appointmentId,
    String reason,
  ) {
    return _apiClient
        .post(
          '/landlord/appointments/${Uri.encodeComponent(appointmentId)}/reject',
          data: {'reason': reason},
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> landlordReschedule(
    String appointmentId, {
    required DateTime proposedStartAt,
    required String reason,
  }) {
    return _apiClient
        .post(
          '/landlord/appointments/${Uri.encodeComponent(appointmentId)}/reschedule',
          data: {
            'proposedStartAt': _offsetIso(proposedStartAt),
            'reason': reason,
          },
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> landlordCheckIn(String appointmentId, String code) {
    return _apiClient
        .post(
          '/landlord/appointments/${Uri.encodeComponent(appointmentId)}/check-in',
          data: {'checkinCode': code},
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> landlordComplete(String appointmentId) {
    return _apiClient
        .post(
          '/landlord/appointments/${Uri.encodeComponent(appointmentId)}/complete',
        )
        .unwrapData(AppointmentDetail.fromJson);
  }

  Future<AppointmentDetail> landlordNoShow(String appointmentId) {
    return _apiClient
        .post(
          '/landlord/appointments/${Uri.encodeComponent(appointmentId)}/no-show',
        )
        .unwrapData(AppointmentDetail.fromJson);
  }
}

String _offsetIso(DateTime value) {
  final local = value.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absoluteMinutes = offset.inMinutes.abs();
  final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
  final base = local.toIso8601String().split('.').first;
  return '$base$sign$hours:$minutes';
}

extension _FutureApiResultUnwrap on Future<ApiResult<Response<dynamic>>> {
  Future<T> unwrapValue<T>(T Function(dynamic data) fromData) async {
    return (await this).unwrapValue(fromData);
  }

  Future<T> unwrapData<T>(
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    return (await this).unwrapData(fromJson);
  }
}
