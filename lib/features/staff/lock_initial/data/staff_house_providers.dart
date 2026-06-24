import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import 'staff_house.dart';
import 'staff_house_service.dart';

final staffHouseServiceProvider = Provider<StaffHouseService>((ref) {
  return StaffHouseService(ref.watch(apiClientProvider));
});

final unboundSmartLockHousesProvider = FutureProvider<List<StaffHouse>>((
  ref,
) async {
  final houses = await ref.watch(staffHouseServiceProvider).fetchHouses();
  return houses
      .where((house) => house.isSmartLockUnbound)
      .toList(growable: false);
});
