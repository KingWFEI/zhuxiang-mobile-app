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
      'contract': {'tenantIdCard': '110101199001011234'},
    });

    expect(detail.canSign, isFalse);
    expect(detail.unavailable, isTrue);
    expect(maskIdCard(detail.contract.tenantIdCard), '1101**********1234');
  });

  test('房东业务入口都是 shell 外的绝对路径', () {
    expect(RoutePaths.landlordHouses, '/landlord/houses');
    expect(RoutePaths.landlordHouseCreate, '/landlord/houses/create');
    expect(RoutePaths.landlordContracts, '/landlord/contracts');
    expect(RoutePaths.landlordContractDetail, '/landlord/contracts/:orderId');
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
  });
}
