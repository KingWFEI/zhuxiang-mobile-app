import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../models/landlord_house.dart';

class LandlordHouseService {
  LandlordHouseService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LandlordHouseItem>> getMyHouses({String? status}) async {
    final result = await _apiClient.get(
      '/landlord/houses',
      queryParameters: status != null ? {'status': status} : null,
    );
    final data = _unwrapList(result);
    return data.map((e) => LandlordHouseItem.fromJson(e)).toList();
  }

  Future<LandlordHouseItem> getHouseDetail(String houseId) async {
    final result = await _apiClient.get('/landlord/houses/$houseId');
    final data = _unwrap(result);
    return LandlordHouseItem.fromJson(data);
  }

  Future<LandlordHouseItem> createHouse(CreateHouseRequest request) async {
    final result = await _apiClient.post(
      '/landlord/houses',
      data: request.toJson(),
    );
    final data = _unwrap(result);
    return LandlordHouseItem.fromJson(data);
  }

  Future<LandlordHouseItem> updateHouse(
    String houseId,
    UpdateHouseRequest request,
  ) async {
    final result = await _apiClient.put(
      '/landlord/houses/$houseId',
      data: request.toJson(),
    );
    final data = _unwrap(result);
    return LandlordHouseItem.fromJson(data);
  }

  Future<LandlordHouseItem> publishHouse(String houseId) async {
    final result = await _apiClient.put('/landlord/houses/$houseId/publish');
    final data = _unwrap(result);
    return LandlordHouseItem.fromJson(data);
  }

  Future<LandlordHouseItem> offlineHouse(String houseId) async {
    final result = await _apiClient.put('/landlord/houses/$houseId/offline');
    final data = _unwrap(result);
    return LandlordHouseItem.fromJson(data);
  }

  Future<String> uploadImage(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final result = await _apiClient.post(
      '/landlord/files/house-images/upload',
      data: formData,
    );
    final data = _unwrap(result);
    return data['url']?.toString() ?? '';
  }

  Map<String, dynamic> _unwrap(ApiResult<Response<dynamic>> result) {
    if (result case ApiSuccess<Response<dynamic>>(:final data)) {
      final body = data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code == 200 || code == 0) {
          final payload = body['data'];
          if (payload is Map<String, dynamic>) return payload;
        }
        throw ApiException(
          type: ApiExceptionType.server,
          message: body['message']?.toString() ?? '请求失败',
        );
      }
    }
    throw const ApiException(
      type: ApiExceptionType.server,
      message: '请求失败',
    );
  }

  List<Map<String, dynamic>> _unwrapList(ApiResult<Response<dynamic>> result) {
    if (result case ApiSuccess<Response<dynamic>>(:final data)) {
      final body = data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code == 200 || code == 0) {
          final payload = body['data'];
          if (payload is List) {
            return payload.whereType<Map<String, dynamic>>().toList();
          }
          if (payload is Map && payload['items'] is List) {
            return (payload['items'] as List)
                .whereType<Map<String, dynamic>>()
                .toList();
          }
        }
        throw ApiException(
          type: ApiExceptionType.server,
          message: body['message']?.toString() ?? '请求失败',
        );
      }
    }
    throw const ApiException(
      type: ApiExceptionType.server,
      message: '请求失败',
    );
  }
}
