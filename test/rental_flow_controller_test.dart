import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_exception.dart';
import 'package:zhuxiang_app/features/rental_flow/application/rental_flow_controller.dart';
import 'package:zhuxiang_app/features/rental_flow/data/services/rental_flow_service.dart';
import 'package:zhuxiang_app/features/rental_flow/domain/entities/contract_preview.dart';
import 'package:zhuxiang_app/features/rental_flow/domain/entities/contract_signing.dart';
import 'package:zhuxiang_app/features/rental_flow/domain/entities/rent_order.dart';

void main() {
  test(
    'loading a contract clears signing state from the previous order',
    () async {
      final service = _SigningStateService();
      final controller = RentalFlowController(service);
      addTearDown(controller.dispose);

      await controller.refreshContractSigning('old-order');
      expect(controller.state.signingStatus?.isCompleted, isTrue);
      expect(controller.state.signingStatus?.tenantSigned, isTrue);
      expect(controller.state.signingStatus?.lessorSigned, isTrue);

      final loadFuture = controller.loadContractPreview('new-order');
      expect(controller.state.signingStatus, isNull);

      service.completeOrderLoad();
      await loadFuture;
      expect(controller.state.order?.id, 'new-order');
      expect(controller.state.signingStatus, isNull);
    },
  );

  test(
    'missing signing flow is treated as not started instead of page error',
    () async {
      final controller = RentalFlowController(_MissingSigningFlowService());
      addTearDown(controller.dispose);

      final status = await controller.refreshContractSigning('new-order');

      expect(status?.contractStatus, 'NOT_STARTED');
      expect(status?.tenantSigned, isFalse);
      expect(status?.lessorSigned, isFalse);
      expect(controller.state.errorMessage, isNull);
    },
  );
}

class _SigningStateService extends RentalFlowService {
  _SigningStateService() : super(ApiClient());

  final _orderCompleter = Completer<RentOrder>();

  @override
  Future<ContractSigningStatus> refreshContractSigning(String orderId) async {
    return const ContractSigningStatus(
      contractStatus: 'COMPLETED',
      currentUserSigned: true,
      lessorSigned: true,
      tenantSigned: true,
      downloadAvailable: true,
    );
  }

  @override
  Future<RentOrder> loadRentOrder(String orderId) => _orderCompleter.future;

  void completeOrderLoad() => _orderCompleter.complete(_order('new-order'));

  @override
  Future<ContractPreview> loadContractPreview(String orderId) async {
    return _contract(orderId);
  }
}

class _MissingSigningFlowService extends RentalFlowService {
  _MissingSigningFlowService() : super(ApiClient());

  @override
  Future<ContractSigningStatus> refreshContractSigning(String orderId) {
    throw const ApiException(
      type: ApiExceptionType.server,
      statusCode: 404,
      message: '合同签署流程不存在',
    );
  }
}

RentOrder _order(String id) {
  return RentOrder(
    id: id,
    orderNo: 'NO-$id',
    houseId: 'house-1',
    houseName: '测试房源',
    roomName: '101',
    address: '测试地址',
    coverUrl: '',
    startDate: DateTime(2026, 8, 1),
    leaseMonths: 12,
    paymentMethod: '押一付一',
    tenantCount: 1,
    monthlyRent: 300000,
    deposit: 300000,
    serviceFee: 0,
    firstPaymentAmount: 600000,
    status: RentOrderStatus.pendingSign,
  );
}

ContractPreview _contract(String orderId) {
  return ContractPreview(
    orderId: orderId,
    contractNo: 'HT-001',
    houseName: '测试房源',
    tenantName: '租客',
    landlordName: '房东',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2027, 7, 31),
    monthlyRent: 300000,
    deposit: 300000,
    paymentMethod: '押一付一',
    clauses: const [],
  );
}
