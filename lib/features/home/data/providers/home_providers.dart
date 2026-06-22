import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/network/api_result.dart';
import '../models/home_data.dart';
import '../services/home_service.dart';

/// 首页服务 Provider，统一注入全局 ApiClient。
final homeServiceProvider = Provider<HomeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeService(apiClient);
});

/// 首页聚合数据 Provider，页面负责处理 ApiSuccess/ApiFailure。
final homeDataProvider = FutureProvider<ApiResult<HomeData>>((ref) {
  final service = ref.watch(homeServiceProvider);
  return service.fetchHomeData();
});
