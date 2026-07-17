import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../models/community.dart';

class CommunityService {
  CommunityService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Community>> search(String keyword) async {
    final result = await _apiClient.get(
      '/communities/search',
      queryParameters: {'keyword': keyword.trim()},
    );
    return _unwrapList(result).map(Community.fromJson).toList();
  }

  Future<List<MapPoi>> searchMapPois({
    required String keyword,
    double? longitude,
    double? latitude,
    int radius = 3000,
  }) async {
    final query = <String, dynamic>{'keyword': keyword.trim()};
    if (longitude != null && latitude != null) {
      query
        ..['longitude'] = longitude
        ..['latitude'] = latitude
        ..['radius'] = radius;
    }
    final result = await _apiClient.get(
      '/communities/map-pois/search',
      queryParameters: query,
    );
    return _unwrapList(result)
        .map(MapPoi.fromJson)
        .where(
          (poi) =>
              poi.externalPoiId.isNotEmpty &&
              poi.name.isNotEmpty &&
              poi.longitude != 0 &&
              poi.latitude != 0,
        )
        .toList();
  }

  Future<Community> createFromMap(MapPoi poi) async {
    final result = await _apiClient.post(
      '/communities/from-map',
      data: poi.toSelectionJson(),
    );
    return Community.fromJson({
      'mapProvider': 'amap',
      'externalPoiId': poi.externalPoiId,
      'name': poi.name,
      'address': poi.address,
      'province': poi.province,
      'city': poi.city,
      'district': poi.district,
      'longitude': poi.longitude,
      'latitude': poi.latitude,
      ..._unwrap(result),
    });
  }

  Map<String, dynamic> _unwrap(ApiResult<Response<dynamic>> result) {
    if (result case ApiSuccess<Response<dynamic>>(:final data)) {
      final body = data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code == 0 || code == 200) {
          final payload = body['data'];
          if (payload is Map<String, dynamic>) return payload;
        }
        throw ApiException(
          type: ApiExceptionType.server,
          message: body['message']?.toString() ?? '请求失败',
        );
      }
    }
    throw const ApiException(type: ApiExceptionType.server, message: '请求失败');
  }

  List<Map<String, dynamic>> _unwrapList(ApiResult<Response<dynamic>> result) {
    if (result case ApiSuccess<Response<dynamic>>(:final data)) {
      final body = data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code == 0 || code == 200) {
          final payload = body['data'];
          if (payload is List) {
            return payload.whereType<Map<String, dynamic>>().toList();
          }
          if (payload is Map) {
            final items =
                payload['items'] ?? payload['records'] ?? payload['list'];
            if (items is List) {
              return items.whereType<Map<String, dynamic>>().toList();
            }
          }
        }
        throw ApiException(
          type: ApiExceptionType.server,
          message: body['message']?.toString() ?? '请求失败',
        );
      }
    }
    throw const ApiException(type: ApiExceptionType.server, message: '请求失败');
  }
}
