import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/home_model.dart';
import '../../service/home_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) => HomeService());

final homeDataProvider = FutureProvider<HomeData>((ref) {
  final service = ref.watch(homeServiceProvider);
  return service.fetchHomeData();
});
