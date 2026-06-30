import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/payment_record.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(apiClientProvider));
});

final paymentRecordsProvider = FutureProvider.autoDispose
    .family<PaymentRecordPageResult, PaymentRecordQuery>((ref, query) {
      return ref
          .watch(paymentServiceProvider)
          .fetchMyPayments(
            status: query.status,
            type: query.type,
            page: query.page,
            pageSize: query.pageSize,
          );
    });

final paymentDetailProvider = FutureProvider.autoDispose
    .family<PaymentRecord, String>((ref, paymentId) {
      return ref.watch(paymentServiceProvider).fetchPaymentDetail(paymentId);
    });

class PaymentRecordQuery {
  const PaymentRecordQuery({
    this.status,
    this.type,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? status;
  final String? type;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is PaymentRecordQuery &&
        other.status == status &&
        other.type == type &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(status, type, page, pageSize);
}
