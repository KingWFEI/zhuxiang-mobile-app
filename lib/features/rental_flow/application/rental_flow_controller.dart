import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/real_name_model.dart';
import '../data/services/rental_flow_service.dart';
import '../domain/entities/contract_preview.dart';
import '../domain/entities/payment_info.dart';
import '../domain/entities/rent_order.dart';

class RentalFlowState {
  const RentalFlowState({
    this.order,
    this.contractPreview,
    this.paymentInfo,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final RentOrder? order;
  final ContractPreview? contractPreview;
  final PaymentInfo? paymentInfo;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  RentalFlowState copyWith({
    RentOrder? order,
    ContractPreview? contractPreview,
    PaymentInfo? paymentInfo,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RentalFlowState(
      order: order ?? this.order,
      contractPreview: contractPreview ?? this.contractPreview,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RentalFlowController extends StateNotifier<RentalFlowState> {
  RentalFlowController(this._service) : super(const RentalFlowState());

  final RentalFlowService _service;

  Future<RentOrder?> createRentOrder(CreateRentOrderRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final order = await _service.createRentOrder(request);
      state = state.copyWith(order: order, isSubmitting: false);
      return order;
    } on Object catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<void> loadRentOrder(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _service.loadRentOrder(orderId);
      state = state.copyWith(order: order, isLoading: false);
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<bool> submitRealName({
    required String orderId,
    required String name,
    required String idCardNumber,
    required String phone,
    required String idCardFrontUrl,
    required String idCardBackUrl,
  }) async {
    return _submit(() async {
      final order = await _service.submitRealName(
        orderId,
        RealNameModel(
          name: name,
          idCardNumber: idCardNumber,
          phone: phone,
          idCardFrontUrl: idCardFrontUrl,
          idCardBackUrl: idCardBackUrl,
        ),
      );
      state = state.copyWith(order: order);
    });
  }

  Future<FileUploadResult?> uploadIdCardImage({
    required String filePath,
    required String bizType,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _service.uploadIdCardImage(
        filePath: filePath,
        bizType: bizType,
      );
      state = state.copyWith(isSubmitting: false);
      return result;
    } on Object catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<void> loadContractPreview(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _service.loadRentOrder(orderId);
      final contract = await _service.loadContractPreview(orderId);
      state = state.copyWith(
        order: order,
        contractPreview: contract,
        isLoading: false,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<bool> confirmContract(String orderId) async {
    return _submit(() async {
      final order = await _service.confirmContract(orderId);
      state = state.copyWith(order: order);
    });
  }

  Future<void> loadPaymentInfo(String orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final order = await _service.loadRentOrder(orderId);
      final payment = await _service.loadPaymentInfo(orderId);
      state = state.copyWith(
        order: order,
        paymentInfo: payment,
        isLoading: false,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  void selectPaymentMethod(String method) {
    final payment = state.paymentInfo;
    if (payment == null) return;
    state = state.copyWith(
      paymentInfo: payment.copyWith(selectedPaymentMethod: method),
    );
  }

  Future<bool> submitPayment(String orderId, String paymentMethod) async {
    return _submit(() async {
      final order = await _service.submitPayment(orderId, paymentMethod);
      state = state.copyWith(order: order);
    });
  }

  Future<bool> submitOnlineSign(String orderId) async {
    return _submit(() async {
      final order = await _service.submitOnlineSign(orderId);
      state = state.copyWith(order: order);
    });
  }

  Future<bool> _submit(Future<void> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isSubmitting: false);
      return true;
    } on Object catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return '租约流程请求失败，请稍后重试';
  }
}
