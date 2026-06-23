import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../application/repair_controller.dart';
import '../services/repair_service.dart';

final repairServiceProvider = Provider<RepairServiceContract>((ref) {
  return RepairService(ref.watch(apiClientProvider));
});

final repairControllerProvider =
    StateNotifierProvider<RepairController, RepairState>((ref) {
      final controller = RepairController(ref.watch(repairServiceProvider));
      controller.load();
      return controller;
    });
