import 'package:dio/dio.dart';
import 'package:zhuxiang_app/core/network/api_exception.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/page_result.dart';
import '../models/hot_community.dart';
import '../models/house.dart';
import '../models/house_tag.dart';
import '../models/immersive_tour.dart';

/// 房源数据服务。
class HouseService {
  HouseService(this.apiClient);

  final ApiClient apiClient;

  /// 返回搜索页热门小区。
  List<HotCommunity> getHotCommunities() {
    return const [];
  }

  /// 获取房源快捷筛选标签列表。
  Future<List<HouseTag>> fetchTags() async {
    final result = await apiClient.get('/houses/tags');
    if (result is ApiSuccess<Response<dynamic>>) {
      final body = result.data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code != 0 && code != 200) {
          throw ApiException(
            type: ApiExceptionType.server,
            message: body['message']?.toString() ?? '获取标签失败',
          );
        }
        final data = body['data'];
        if (data is List) {
          return data
              .map((e) => HouseTag.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }
    if (result is ApiFailure<Response<dynamic>>) {
      throw result.error ??
          ApiException(type: ApiExceptionType.unknown, message: result.message);
    }
    return const [];
  }

  /// 调用后端 GET /houses 接口分页搜索房源。
  Future<PageResult<House>> fetchHouses(Map<String, dynamic> query) async {
    final result = await apiClient.get('/houses', queryParameters: query);

    if (result is ApiSuccess<Response<dynamic>>) {
      final responseData = result.data.data;
      if (responseData is! Map<String, dynamic>) {
        throw const ApiException(
          type: ApiExceptionType.unknown,
          message: '房源数据格式错误',
        );
      }

      final pageData = responseData['data'] as Map<String, dynamic>?;
      if (pageData == null) {
        throw const ApiException(
          type: ApiExceptionType.unknown,
          message: '房源数据为空',
        );
      }

      final items =
          (pageData['items'] as List<dynamic>?)
              ?.map((e) => House.fromJson(e as Map<String, dynamic>))
              .where((house) => !house.isRented)
              .toList(growable: false) ??
          const <House>[];

      return PageResult<House>(
        items: items,
        page: (pageData['page'] as int?) ?? 1,
        pageSize: (pageData['pageSize'] as int?) ?? 20,
        total: (pageData['total'] as int?) ?? 0,
        hasMore: (pageData['hasMore'] as bool?) ?? false,
      );
    }

    if (result is ApiFailure<Response<dynamic>>) {
      final error = result.error;
      throw ApiException(
        type: (error is ApiException) ? error.type : ApiExceptionType.unknown,
        message: result.message,
        cause: error,
      );
    }

    throw const ApiException(
      type: ApiExceptionType.unknown,
      message: '获取房源列表失败',
    );
  }

  /// 根据 ID 返回房源详情。
  Future<ApiResult<HouseDetail>> getHouseDetail(String houseId) async {
    final result = await apiClient.get('/houses/$houseId');

    if (result is ApiSuccess<Response<dynamic>>) {
      final responseData = result.data.data;

      if (responseData is! Map<String, dynamic>) {
        return ApiFailure(message: '房源详情数据格式错误');
      }

      if (responseData['code'] != 200) {
        return ApiFailure(
          message: responseData['message'] as String? ?? '获取房源详情失败',
        );
      }

      final data = responseData['data'];
      if (data is! Map<String, dynamic>) {
        return ApiFailure(message: '房源详情数据结构错误');
      }

      final detail = HouseDetail.fromJson(data);
      if (detail.isRented) {
        return ApiFailure(message: '该房源已出租');
      }

      return ApiSuccess(detail);
    }

    if (result is ApiFailure<Response<dynamic>>) {
      return ApiFailure(message: result.message, error: result.error);
    }

    return ApiFailure(message: '获取房源详情失败');
  }

  /// 添加收藏。
  Future<void> addFavorite(String houseId) async {
    final result = await apiClient.post('/houses/$houseId/favorite');
    _checkResult(result, '收藏失败');
  }

  /// 取消收藏。
  Future<void> removeFavorite(String houseId) async {
    final result = await apiClient.delete('/houses/$houseId/favorite');
    _checkResult(result, '取消收藏失败');
  }

  void _checkResult(ApiResult<Response<dynamic>> result, String fallbackMsg) {
    if (result is ApiSuccess<Response<dynamic>>) {
      final body = result.data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code == 200 || code == 0) return;
        throw ApiException(
            type: ApiExceptionType.server,
            message: body['message']?.toString() ?? fallbackMsg);
      }
    }
    if (result is ApiFailure<Response<dynamic>>) {
      throw result.error ??
          ApiException(type: ApiExceptionType.unknown, message: result.message);
    }
    throw ApiException(type: ApiExceptionType.unknown, message: fallbackMsg);
  }

  /// 获取我的收藏列表。
  Future<PageResult<House>> getFavoriteHouses({int page = 1, int pageSize = 20}) async {
    final result = await apiClient.get(
      '/profile/favorite-houses',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    if (result is ApiSuccess<Response<dynamic>>) {
      final body = result.data.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? -1;
        if (code != 200) {
          throw ApiException(
              type: ApiExceptionType.server,
              message: body['message']?.toString() ?? '获取收藏列表失败');
        }
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final records = (data['records'] as List<dynamic>?)
                  ?.map((e) => House.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          return PageResult(
            items: records,
            page: (data['page'] as int?) ?? 1,
            pageSize: pageSize,
            total: (data['total'] as int?) ?? 0,
            hasMore: ((data['page'] as int?) ?? 1) <
                ((data['totalPages'] as int?) ?? 1),
          );
        }
      }
    }
    throw const ApiException(
        type: ApiExceptionType.unknown, message: '获取收藏列表失败');
  }
}
