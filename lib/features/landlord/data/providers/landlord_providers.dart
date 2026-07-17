import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../models/landlord_house.dart';
import '../services/landlord_house_service.dart';

final landlordHouseServiceProvider = Provider<LandlordHouseService>((ref) {
  return LandlordHouseService(ref.watch(apiClientProvider));
});

final landlordHousesProvider =
    FutureProvider.autoDispose.family<List<LandlordHouseItem>, String?>(
  (ref, status) {
    return ref.watch(landlordHouseServiceProvider).getMyHouses(status: status);
  },
);
