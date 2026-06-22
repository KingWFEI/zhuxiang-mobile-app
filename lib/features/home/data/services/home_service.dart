import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/home_data.dart';

/// 首页接口服务，通过构造函数接收统一的 ApiClient。
class HomeService {
  const HomeService(this.apiClient);

  final ApiClient apiClient;

  /// 获取首页聚合数据，并将网络结果转换成业务模型结果。
  Future<ApiResult<HomeData>> fetchHomeData() async {
    final result = await apiClient.get('/home/data');

    if (result is ApiSuccess<Response<dynamic>>) {
      final responseData = result.data.data;
      if (responseData is! Map<String, dynamic>) {
        return const ApiFailure<HomeData>(message: '首页数据格式错误');
      }

      final code = responseData['code'];
      if (code is int && code != 200) {
        return ApiFailure<HomeData>(
          message: responseData['message'] as String? ?? '首页数据加载失败',
        );
      }

      final nestedData = responseData['data'];
      final json = nestedData is Map<String, dynamic>
          ? nestedData
          : responseData;
      try {
        return ApiSuccess<HomeData>(HomeData.fromJson(json));
      } on Object catch (error) {
        return ApiFailure<HomeData>(message: '首页数据解析失败', error: error);
      }
    }

    if (result is ApiFailure<Response<dynamic>>) {
      return ApiFailure<HomeData>(message: result.message, error: result.error);
    }

    return const ApiFailure<HomeData>(message: '首页数据加载失败');
  }
}
