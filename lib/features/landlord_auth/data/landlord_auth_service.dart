import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import 'landlord_auth_models.dart';

class LandlordAuthService {
  const LandlordAuthService(this._client);
  final ApiClient _client;

  Future<LandlordAuthStatus> getStatus() async {
    final result = await _client.get('/landlord-auth/status');
    return result.unwrapData(LandlordAuthStatus.fromJson);
  }

  Future<UploadedAuthFile> upload(String path, String bizType) async {
    final data = FormData.fromMap({
      'bizType': bizType,
      'file': await MultipartFile.fromFile(path),
    });
    final result = await _client.post('/files/upload', data: data);
    return result.unwrapData(UploadedAuthFile.fromJson);
  }

  Future<LandlordAuthApplication> submit({
    required String realName,
    required String idCardNo,
    required String idCardFrontUrl,
    required String idCardBackUrl,
    required List<LandlordAuthProof> proofs,
    required String contactPhone,
    required bool replaceExisting,
    String? contactWechat,
    String? contactEmail,
    String? contactAddress,
    String? preferredContactTime,
    String? applicantNote,
  }) async {
    final result = await _client.post(
      '/landlord-auth/applications',
      data: {
        'realName': realName,
        'idCardNo': idCardNo,
        'idCardFrontUrl': idCardFrontUrl,
        'idCardBackUrl': idCardBackUrl,
        'proofs': proofs.map((item) => item.toJson()).toList(),
        'contactPhone': contactPhone,
        'contactWechat': contactWechat,
        'contactEmail': contactEmail,
        'contactAddress': contactAddress,
        'preferredContactTime': preferredContactTime,
        'applicantNote': applicantNote,
        'replaceExisting': replaceExisting,
      },
    );
    return result.unwrapData(LandlordAuthApplication.fromJson);
  }
}
