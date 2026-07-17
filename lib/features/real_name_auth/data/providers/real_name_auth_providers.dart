import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../models/real_name_auth_models.dart';
import '../services/real_name_auth_api.dart';

final realNameAuthApiProvider = Provider<RealNameAuthApi>((ref) {
  return RealNameAuthApi(ref.watch(apiClientProvider));
});

final realNameAuthStatusProvider =
    FutureProvider.autoDispose<RealNameAuthStatusResponse>((ref) {
      return ref.watch(realNameAuthApiProvider).getStatus();
    });
