import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/rental_flow_notifier.dart';
import '../../data/rental_flow_repository.dart';
import '../../data/rental_flow_service.dart';
import '../../domain/rental_flow_models.dart';

final rentalFlowServiceProvider = Provider<RentalFlowService>((ref) {
  return RentalFlowService();
});

final rentalFlowRepositoryProvider = Provider<RentalFlowRepository>((ref) {
  return RentalFlowRepository(service: ref.watch(rentalFlowServiceProvider));
});

final rentalFlowProvider =
    StateNotifierProvider<RentalFlowNotifier, RentalFlowState>((ref) {
      return RentalFlowNotifier(
        repository: ref.watch(rentalFlowRepositoryProvider),
      );
    });
