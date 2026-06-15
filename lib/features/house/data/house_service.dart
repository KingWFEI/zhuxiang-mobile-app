import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../shared/models/page_result.dart';
import '../domain/entities/house.dart';

class HouseService {
  HouseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PageResult<House>> fetchHouses(Map<String, dynamic> query) async {
    final result = await _apiClient.get('/houses', queryParameters: query);
    return result.unwrapData(_pageFromJson);
  }

  Future<House> getHouseDetail(String houseId) async {
    final result = await _apiClient.get('/houses/$houseId');
    return result.unwrapData(House.fromJson);
  }

  PageResult<House> _pageFromJson(Map<String, dynamic> json) {
    return PageResult(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => House.fromJson(item as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
