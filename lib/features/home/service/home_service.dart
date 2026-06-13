import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';

import '../domain/home_model.dart';

class HomeService {
  final ApiClient _apiClient = ApiClient();

  Future<HomeData> fetchHomeData() async {
    final result = await _apiClient.get('/home/data');
    return result.unwrapData(HomeData.fromJson);
  }
}
