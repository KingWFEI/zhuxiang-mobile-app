import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/router/route_paths.dart';
import 'package:zhuxiang_app/app/router/app_router.dart';
import 'package:zhuxiang_app/app/router/route_names.dart';
import 'package:zhuxiang_app/features/landlord/data/models/landlord_contract.dart';

void main() {
  test('解析房东待签合同分页及金额', () {
    final page = LandlordContractPage.fromJson({
      'items': [
        {
          'orderId': 'order-1',
          'contractId': 'contract-1',
          'contractNo': 'ZX-001',
          'contractStatus': 'SIGNING',
          'tenantSigned': true,
          'lessorSigned': false,
          'signStage': 'WAITING_MY_SIGNATURE',
          'houseId': 'house-1',
          'houseName': '阳光花园',
          'roomName': '1栋101室',
          'address': '测试路1号',
          'tenantName': '张三',
          'tenantPhone': '138****8000',
          'startDate': '2026-08-01',
          'endDate': '2027-07-31',
          'monthlyRent': 300000,
          'deposit': 300000,
          'updatedAt': '2026-07-17T12:00:00',
        },
      ],
      'page': 1,
      'pageSize': 20,
      'hasMore': false,
      'total': 1,
    });

    expect(page.total, 1);
    expect(page.items.single.tenantSigned, isTrue);
    expect(page.items.single.lessorSigned, isFalse);
    expect(formatContractMoney(page.items.single.monthlyRent), '¥3,000.00');
  });

  test('合同不可签状态与身份证脱敏', () {
    final detail = LandlordContractDetail.fromJson({
      'orderId': 'order-1',
      'contractId': 'contract-1',
      'contractStatus': 'expired',
      'tenantSigned': false,
      'lessorSigned': false,
      'signStage': 'WAITING_MY_SIGNATURE',
      'orderStatus': 'pendingLandlordSign',
      'contract': {'tenantIdCard': '110101199001011234'},
    });

    expect(detail.canSign, isFalse);
    expect(detail.unavailable, isTrue);
    expect(maskIdCard(detail.contract.tenantIdCard), '1101**********1234');
  });

  test('房东仅可在待房东签约状态签署或拒签', () {
    Map<String, dynamic> detail(String orderStatus) => {
      'orderId': 'order-1',
      'contractId': 'contract-1',
      'orderStatus': orderStatus,
      'contractStatus': 'signing',
      'tenantSigned': true,
      'lessorSigned': false,
      'contract': <String, dynamic>{},
    };

    expect(
      LandlordContractDetail.fromJson(detail('pendingLandlordSign')).canSign,
      isTrue,
    );
    for (final status in [
      'refundPending',
      'refunded',
      'refundFailed',
      'completed',
    ]) {
      expect(
        LandlordContractDetail.fromJson(detail(status)).canSign,
        isFalse,
        reason: status,
      );
    }
    expect(
      LandlordContractDetail.fromJson(
        detail('refundPending'),
      ).operationStatusLabel,
      '已拒签/退款处理中',
    );
  });

  test('详情接口缺少订单状态时可用待我签署阶段触发立即签署', () {
    final detail = LandlordContractDetail.fromJson({
      'orderId': 'order-1',
      'contractId': 'contract-1',
      'contractStatus': 'SIGNING',
      'tenantSigned': true,
      'lessorSigned': false,
      'signStage': 'WAITING_MY_SIGNATURE',
      'contract': <String, dynamic>{},
    });

    expect(detail.orderStatus, isEmpty);
    expect(detail.canSign, isTrue);
  });

  test('详情接口兼容嵌套合同和 rentOrder 状态字段', () {
    final detail = LandlordContractDetail.fromJson({
      'orderId': 'order-1',
      'contractId': 'contract-1',
      'rentOrder': {'status': 'pendingLandlordSign'},
      'contract': {
        'status': 'SIGNING',
        'tenantSigned': true,
        'lessorSigned': false,
        'signStage': 'WAITING_MY_SIGNATURE',
      },
    });

    expect(detail.orderStatus, 'pendingLandlordSign');
    expect(detail.contractStatus, 'SIGNING');
    expect(detail.canSign, isTrue);
  });

  test('解析房东待签解约协议及签署结果', () {
    final page = LandlordTerminationPage.fromJson({
      'items': [
        {
          'applicationId': 'termination-1',
          'applicationNo': 'TZ-001',
          'status': 'rescission_signing',
          'statusText': '解约协议待签署',
          'contractId': 'contract-1',
          'contractNo': 'ZX-001',
          'houseName': '阳光花园',
          'tenantName': '张三',
          'tenantSigned': true,
          'lessorSigned': false,
        },
      ],
      'page': 1,
      'pageSize': 20,
      'hasMore': false,
      'total': 1,
    });
    final result = RescissionSignResult.fromJson({
      'action': 'sign',
      'url': 'https://example.com/sign',
      'status': 'rescission_completed',
      'lessorSigned': true,
    });

    expect(page.total, 1);
    expect(page.items.single.applicationId, 'termination-1');
    expect(page.items.single.tenantSigned, isTrue);
    expect(result.signUrl, 'https://example.com/sign');
    expect(result.currentUserSigned, isTrue);
    expect(result.completed, isTrue);
  });

  test('普通租约产生的空解约占位数据不会显示或计入待签数', () {
    final page = LandlordTerminationPage.fromJson({
      'items': [
        {
          'applicationId': '',
          'applicationNo': '',
          'status': '',
          'contractId': 'contract-1',
          'houseName': '清新治愈·原木风',
          'tenantName': '史家豪',
          'tenantSigned': true,
          'lessorSigned': false,
        },
      ],
      'page': 1,
      'pageSize': 20,
      'hasMore': false,
      'total': 1,
    });

    expect(page.items, isEmpty);
    expect(page.total, 0);
  });

  test('房东业务入口都是 shell 外的绝对路径', () {
    expect(RoutePaths.landlordHouses, '/landlord/houses');
    expect(RoutePaths.landlordHouseCreate, '/landlord/houses/create');
    expect(RoutePaths.landlordContracts, '/landlord/contracts');
    expect(RoutePaths.landlordContractDetail, '/landlord/contracts/:orderId');
    expect(
      RoutePaths.landlordTerminationDetail,
      '/landlord/termination-applications/:applicationId',
    );
    expect(RoutePaths.rentOrderDetail, '/rent-orders/:orderId');
  });

  test('房东独立页面路由可按名称生成', () {
    final router = AppRouter.createRouter();
    addTearDown(router.dispose);

    expect(router.namedLocation(RouteNames.landlordHouses), '/landlord/houses');
    expect(
      router.namedLocation(
        RouteNames.landlordContractDetail,
        pathParameters: {'orderId': 'order-1'},
      ),
      '/landlord/contracts/order-1',
    );
    expect(
      router.namedLocation(
        RouteNames.landlordContractWebview,
        pathParameters: {'orderId': 'order-1'},
      ),
      '/landlord/contracts/order-1/sign',
    );
    expect(
      router.namedLocation(
        RouteNames.landlordTerminationDetail,
        pathParameters: {'applicationId': 'termination-1'},
      ),
      '/landlord/termination-applications/termination-1',
    );
  });
}
