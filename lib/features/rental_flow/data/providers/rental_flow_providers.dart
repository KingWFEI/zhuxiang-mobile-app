import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../application/rental_flow_controller.dart';
import '../../domain/entities/rent_order.dart';
import '../services/rental_flow_service.dart';

final rentalFlowServiceProvider = Provider<RentalFlowService>((ref) {
  return RentalFlowService(ref.watch(apiClientProvider));
});

final rentalFlowControllerProvider =
    StateNotifierProvider<RentalFlowController, RentalFlowState>((ref) {
      return RentalFlowController(ref.watch(rentalFlowServiceProvider));
    });

final myRentOrdersProvider = FutureProvider.autoDispose<List<RentOrder>>((
  ref,
) async {
  final orders = await ref.watch(rentalFlowServiceProvider).loadMyRentOrders();
  return orders;
});

final activeRentOrdersProvider = FutureProvider.autoDispose<List<RentOrder>>((
  ref,
) async {
  final orders = await ref.watch(myRentOrdersProvider.future);
  return orders
      .where(
        (order) =>
            order.status != RentOrderStatus.completed &&
            order.status != RentOrderStatus.cancelled,
      )
      .toList(growable: false);
});
