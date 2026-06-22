import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zhuxiang_app/features/house/data/services/house_service_mock.dart';


final houseMockServiceProvider = Provider<HouseMockService>((ref) {
  return HouseMockService();
});
