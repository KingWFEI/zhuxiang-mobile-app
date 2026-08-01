import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/landlord_profile.dart';

class LandlordProfileService {
  const LandlordProfileService(this._apiClient);

  final ApiClient _apiClient;

  Future<LandlordProfile> getMyProfile() async {
    final result = await _apiClient.get('/landlord/profile');
    return result.unwrapData(LandlordProfile.fromJson);
  }

  Future<LandlordProfile> updateMyProfile(
    UpdateLandlordProfileRequest request,
  ) async {
    final result = await _apiClient.put(
      '/landlord/profile',
      data: request.toJson(),
    );
    return result.unwrapData(LandlordProfile.fromJson);
  }
}
