import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../services/bill_service.dart';

final billServiceProvider = Provider<BillService>((ref) {
  return BillService(ref.watch(apiClientProvider));
});

final myBillsProvider =
    FutureProvider.autoDispose<BillGroupedResponse>((ref) async {
  final service = ref.watch(billServiceProvider);
  return await service.getMyBills();
});
