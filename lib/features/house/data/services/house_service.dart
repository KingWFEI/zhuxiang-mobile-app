import 'package:dio/dio.dart';
import 'package:zhuxiang_app/core/network/api_exception.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/models/page_result.dart';
import '../models/hot_community.dart';
import '../models/house.dart';

/// 房源数据服务。
///
class HouseService {
  final ApiClient apiClient;
  HouseService(this.apiClient);

  //返回搜索页热门小区。
  List<HotCommunity> getHotCommunities() {
    // final result=apiClient.get(path)
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

  // 根据 ID 返回房源详情。
  Future<ApiResult<HouseDetail>> getHouseDetail(String houseId) async {
    final result = await apiClient.get('/houses/$houseId');

    if (result is ApiSuccess<Response<dynamic>>) {
      final response = result.data;
      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        return ApiFailure(message: '房源详情数据格式错误');
      }

      final detailData = responseData['data'] as Map<String, dynamic>?;
      if (detailData == null) {
        return ApiFailure(message: '房源详情数据为空');
      }

      return ApiSuccess(HouseDetail.fromJson(detailData));
    }

    if (result is ApiFailure<Response<dynamic>>) {
      return ApiFailure(message: result.message, error: result.error);
    }

    return ApiFailure(message: '获取房源详情失败');
  }
}
