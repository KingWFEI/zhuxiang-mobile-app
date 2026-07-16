import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/contract_preview.dart';
import '../../domain/entities/pay_result.dart';
import '../../domain/entities/contract_signing.dart';
import '../../domain/entities/payment_info.dart';
import '../../domain/entities/rent_order.dart';
import '../models/contract_preview_model.dart';
import '../models/pay_result_model.dart';
import '../models/contract_signing_model.dart';
import '../models/payment_info_model.dart';
import '../models/real_name_model.dart';
import '../models/rent_order_model.dart';

class CreateRentOrderRequest {
  const CreateRentOrderRequest({
    required this.houseId,
    required this.houseName,
    required this.roomName,
    required this.address,
    required this.coverUrl,
    required this.startDate,
    required this.leaseMonths,
    required this.paymentMethod,
    required this.tenantCount,
    required this.monthlyRent,
    required this.deposit,
    required this.serviceFee,
  });

  final String houseId;
  final String houseName;
  final String roomName;
  final String address;
  final String coverUrl;
  final DateTime startDate;
  final int leaseMonths;
  final String paymentMethod;
  final int tenantCount;
  final int monthlyRent;
  final int deposit;
  final int serviceFee;

  int get firstPaymentAmount => monthlyRent + deposit + serviceFee;

  Map<String, dynamic> toJson() => {
    'houseId': houseId,
    'startDate': _formatDate(startDate),
    'leaseMonths': leaseMonths,
    'paymentMethod': paymentMethod,
    'tenantCount': tenantCount,
  };
}

class RentalFlowService {
  RentalFlowService(this._apiClient);

  final ApiClient _apiClient;
  final Map<String, RentOrder> _orders = {};
  final Map<String, ContractPreview> _contracts = {};

  Future<RentOrder> createRentOrder(CreateRentOrderRequest request) async {
    final result = await _apiClient.post(
      '/rent-orders',
      data: request.toJson(),
    );
    final order = await result.unwrapData(RentOrderModel.fromJson);
    _orders[order.id] = order;
    return order;
  }

  Future<RentOrder> loadRentOrder(String orderId) async {
    final result = await _apiClient.get('/rent-orders/$orderId');
    final order = await result.unwrapData(RentOrderModel.fromJson);
    _orders[order.id] = order;
    return order;
  }

  Future<List<RentOrder>> loadMyRentOrders() async {
    final result = await _apiClient.get('/rent-orders/my');
    final orders = await result.unwrapValue(_parseRentOrderList);
    for (final order in orders) {
      _orders[order.id] = order;
    }
    return orders;
  }

  Future<RentOrder> cancelRentOrder(String orderId) async {
    final result = await _apiClient.post('/rent-orders/$orderId/cancel');
    final order = await result.unwrapData(RentOrderModel.fromJson);
    _orders[order.id] = order;
    return order;
  }

  Future<void> hideRentOrder(String orderId) async {
    final result = await _apiClient.post('/rent-orders/$orderId/hide');
    await result.unwrapValue((_) => null);
    _orders.remove(orderId);
  }

  Future<RentOrder> submitRealName(
    String orderId,
    RealNameModel realName,
  ) async {
    final result = await _apiClient.post(
      '/rent-orders/$orderId/real-name',
      data: realName.toJson(),
    );
    final order = await result.unwrapData(RentOrderModel.fromJson);
    _orders[order.id] = order;
    return order;
  }

  Future<FileUploadResult> uploadIdCardImage({
    required String filePath,
    required String bizType,
  }) async {
    final formData = FormData.fromMap({
      'bizType': bizType,
      'file': await MultipartFile.fromFile(filePath),
    });
    final result = await _apiClient.post('/files/upload', data: formData);
    return result.unwrapData(FileUploadResult.fromJson);
  }

  Future<ContractPreview> loadContractPreview(String orderId) async {
    final result = await _apiClient.get(
      '/rent-orders/$orderId/contract-preview',
    );
    final contract = await result.unwrapData(ContractPreviewModel.fromJson);
    _contracts[orderId] = contract;
    return contract;
  }

  Future<RentOrder> confirmContract(String orderId) async {
    final result = await _apiClient.post(
      '/rent-orders/$orderId/confirm-contract',
    );
    final order = await result.unwrapData(RentOrderModel.fromJson);
    _orders[order.id] = order;
    return order;
  }

  Future<PaymentInfo> loadPaymentInfo(String orderId) async {
    final result = await _apiClient.get('/rent-orders/$orderId/payment-info');
    return await result.unwrapData(PaymentInfoModel.fromJson);
  }

  Future<PayResult> submitPayment(
    String orderId,
    String paymentMethod,
    String paymentChannel,
  ) async {
    final result = await _apiClient.post(
      '/rent-orders/$orderId/pay',
      data: {'paymentMethod': paymentMethod, 'paymentChannel': paymentChannel},
    );
    return result.unwrapData(PayResultModel.fromJson);
  }

  /// 主动查询支付宝订单状态并确认支付。
  /// 返回 true 表示支付已确认，false 表示暂未查到。
  Future<bool> confirmAlipayPayment(String paymentNo) async {
    final result = await _apiClient.post('/payments/alipay/$paymentNo/confirm');
    return await result.unwrapValue((data) => data == true);
  }

  Future<ContractSignEntry> getContractSignEntry(String orderId) async {
    final result = await _apiClient.post('/rent-orders/$orderId/sign');
    return result.unwrapData(ContractSignEntryModel.fromJson);
  }

  Future<ContractSigningStatus> refreshContractSigning(String orderId) async {
    final result = await _apiClient.post(
      '/rent-orders/$orderId/contract-refresh',
    );
    return result.unwrapData(ContractSigningStatusModel.fromJson);
  }

  Future<ContractDownload> getContractDownload(String orderId) async {
    final result = await _apiClient.get(
      '/rent-orders/$orderId/contract-download-url',
    );
    return result.unwrapData(ContractDownloadModel.fromJson);
  }
}

List<RentOrder> _parseRentOrderList(dynamic data) {
  final source = switch (data) {
    List<dynamic> value => value,
    Map<String, dynamic> value =>
      value['items'] ??
          value['records'] ??
          value['rows'] ??
          value['content'] ??
          value['list'] ??
          value['orders'] ??
          const <dynamic>[],
    _ => const <dynamic>[],
  };
  if (source is! List<dynamic>) return const <RentOrder>[];
  return source
      .whereType<Map<String, dynamic>>()
      .map(RentOrderModel.fromJson)
      .toList(growable: false);
}

class FileUploadResult {
  const FileUploadResult({required this.url, required this.fileId});

  final String url;
  final String fileId;

  factory FileUploadResult.fromJson(Map<String, dynamic> json) {
    return FileUploadResult(
      url: json['url'] as String? ?? '',
      fileId: json['fileId'] as String? ?? json['file_id'] as String? ?? '',
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
