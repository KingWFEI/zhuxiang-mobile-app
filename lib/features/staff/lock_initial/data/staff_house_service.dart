import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import 'staff_house.dart';

class StaffHouseService {
  const StaffHouseService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StaffHouse>> fetchHouses() async {
    final result = await _apiClient.get('/admin/houses');
    return result.unwrapValue((data) {
      final list = data as List<dynamic>? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(StaffHouse.fromJson)
          .toList(growable: false);
    });
  }
}
