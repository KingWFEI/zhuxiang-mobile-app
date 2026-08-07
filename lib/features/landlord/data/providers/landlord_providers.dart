import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../models/landlord_house.dart';
import '../models/landlord_profile.dart';
import '../services/landlord_contract_service.dart';
import '../services/landlord_profile_service.dart';
import '../services/community_service.dart';
import '../services/landlord_house_service.dart';

final landlordHouseServiceProvider = Provider<LandlordHouseService>((ref) {
  return LandlordHouseService(ref.watch(apiClientProvider));
});

final landlordProfileServiceProvider = Provider<LandlordProfileService>((ref) {
  return LandlordProfileService(ref.watch(apiClientProvider));
});

final myLandlordProfileProvider = FutureProvider.autoDispose<LandlordProfile>((
  ref,
) {
  return ref.watch(landlordProfileServiceProvider).getMyProfile();
});

final landlordContractServiceProvider = Provider<LandlordContractService>((
  ref,
) {
  return LandlordContractService(ref.watch(apiClientProvider));
});

final landlordPendingContractCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final page = await ref
      .watch(landlordContractServiceProvider)
      .getPendingContracts(page: 1, pageSize: 1);
  return page.total;
});

final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService(ref.watch(apiClientProvider));
});

final houseFacilitiesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(landlordHouseServiceProvider).getHouseFacilities();
});

final houseTagsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(landlordHouseServiceProvider).getHouseTags();
});

final landlordHouseRoomTypesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(landlordHouseServiceProvider).getHouseRoomTypes();
});

final landlordHousesProvider = FutureProvider.autoDispose
    .family<List<LandlordHouseItem>, String?>((ref, status) {
      return ref
          .watch(landlordHouseServiceProvider)
          .getMyHouses(status: status);
    });
