import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';

import '../domain/entities/house.dart';

class HouseService {
  final ApiClient _client = ApiClient();

  Future<House> getHouseDetail(String houseId) async {
    final result = await _client.get('/houses/$houseId');
    return result.unwrapData(House.fromJson);
  }
}
