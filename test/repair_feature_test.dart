import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_exception.dart';
import 'package:zhuxiang_app/core/storage/storage_service.dart';
import 'package:zhuxiang_app/features/repair/application/repair_controller.dart';
import 'package:zhuxiang_app/features/repair/data/models/repair_order_model.dart';
import 'package:zhuxiang_app/features/repair/data/services/repair_service.dart';
import 'package:zhuxiang_app/features/repair/domain/entities/repair_order.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  test('RepairOrderModel parses tolerant backend fields', () {
    final order = RepairOrderModel({
      'id': '1',
      'order_no': 'BX001',
      'house_id': 'house-1',
      'house_name': '3栋2单元1201',
      'room_name': '1201',
      'type': 'lock',
      'description': '智能门锁异常',
      'attachments': ['mock://1'],
      'contact_name': '王小明',
      'contact_phone': '13812342468',
      'expected_visit_time': '2026-06-24T10:00:00',
      'status': 'pendingReview',
      'housekeeper_name': '小住管家',
      'housekeeper_phone': '400-800-1234',
      'repairman_name': '李师傅',
      'created_at': '2026-06-22T09:20:00',
      'updated_at': '2026-06-22T10:20:00',
      'timeline': [
        {
          'title': '已提交',
          'description': '用户提交报修',
          'time': '2026-06-22T09:20:00',
          'status': 'submitted',
        },
      ],
    }).toEntity();

    expect(order.orderNo, 'BX001');
    expect(order.repairType, RepairType.lock);
    expect(order.status, RepairStatus.pendingReview);
    expect(order.timeline, hasLength(1));
  });

  test('MockRepairService provides required repair records', () async {
    final overview = await MockRepairService().fetchOverview();

    expect(overview.currentHouse.houseName, isNotEmpty);
    expect(overview.orders.length, greaterThanOrEqualTo(8));
    expect(
      overview.orders.map((order) => order.status).toSet(),
      containsAll([
        RepairStatus.submitted,
        RepairStatus.processing,
        RepairStatus.pendingReview,
        RepairStatus.completed,
        RepairStatus.cancelled,
      ]),
    );
  });

  test('RepairService uses active lease as repair house', () async {
    final dio = _repairOverviewDio();
    final service = RepairService(
      ApiClient(dio: dio),
      allowMockFallback: false,
    );

    final overview = await service.fetchOverview();

    expect(overview.currentHouse.houseId, 'active-house');
    expect(overview.currentHouse.houseName, '真实在租房源');
    expect(overview.currentHouse.leaseStatus, '履约中');
  });

  test(
    'RepairController shows no contract message when no active lease',
    () async {
      final controller = RepairController(_NoActiveLeaseRepairService());

      await controller.load();

      expect(controller.state.errorMessage, noActiveRepairLeaseMessage);
    },
  );

  test('RepairController filters, creates repair and submits review', () async {
    final controller = RepairController(MockRepairService());

    await controller.load();
    controller.selectFilter(RepairStatusFilter.pendingReview);
    expect(
      controller.state.filteredOrders.every(
        (order) => order.status == RepairStatus.pendingReview,
      ),
      isTrue,
    );

    final created = await controller.createRepair(
      CreateRepairRequest(
        houseId: 'house-001',
        houseName: '3栋2单元1201',
        roomName: '3栋2单元1201',
        repairType: RepairType.plumbing,
        description: '厨房水管漏水，需要尽快维修',
        imageUrls: const [],
        contactName: '王小明',
        contactPhone: '13812342468',
        expectedVisitTime: DateTime(2026, 6, 24, 10),
      ),
    );

    expect(created, isNotNull);
    expect(controller.state.orderById(created!.id), isNotNull);

    final pendingReview = controller.state.overview!.orders.firstWhere(
      (order) => order.status == RepairStatus.pendingReview,
    );
    final reviewed = await controller.submitReview(
      repairId: pendingReview.id,
      rating: 5,
      content: '维修及时',
    );

    expect(reviewed, isTrue);
    expect(
      controller.state.orderById(pendingReview.id)!.status,
      RepairStatus.completed,
    );
  });
}

Dio _repairOverviewDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final data = switch (options.path) {
          '/repairs/my' => {'code': 200, 'data': <Map<String, dynamic>>[]},
          '/leases/my' => {
            'code': 200,
            'data': [
              {
                'id': 'history-lease',
                'contractId': 'history-contract',
                'houseId': 'history-house',
                'houseName': '历史房源',
                'tenantName': '王小明',
                'tenantPhone': '13800138000',
                'startDate': '2025-01-01',
                'endDate': '2025-12-31',
                'status': 'expired',
              },
              {
                'id': 'active-lease',
                'contractId': 'active-contract',
                'houseId': 'active-house',
                'houseName': '真实在租房源',
                'tenantName': '王小明',
                'tenantPhone': '13800138000',
                'startDate': '2026-01-01',
                'endDate': '2026-12-31',
                'status': 'active',
                'keeperName': '当前管家',
                'keeperPhone': '400-000-0000',
              },
            ],
          },
          _ => {'code': 404, 'message': 'not found'},
        };
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );
  return dio;
}

class _NoActiveLeaseRepairService extends MockRepairService {
  @override
  Future<RepairOverview> fetchOverview() async {
    throw const ApiException(
      type: ApiExceptionType.server,
      message: noActiveRepairLeaseMessage,
    );
  }
}
