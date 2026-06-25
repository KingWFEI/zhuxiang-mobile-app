import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../application/rental_flow_controller.dart';
import '../services/rental_flow_service.dart';

final rentalFlowServiceProvider = Provider<RentalFlowService>((ref) {
  return RentalFlowService(ref.watch(apiClientProvider));
});

final rentalFlowControllerProvider =
    StateNotifierProvider<RentalFlowController, RentalFlowState>((ref) {
      return RentalFlowController(ref.watch(rentalFlowServiceProvider));
    });
