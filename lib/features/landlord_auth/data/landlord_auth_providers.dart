import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'landlord_auth_service.dart';

final landlordAuthServiceProvider = Provider<LandlordAuthService>((ref) {
  return LandlordAuthService(ref.watch(apiClientProvider));
});
