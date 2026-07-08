import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../lease/data/models/lease_model.dart';
import '../../../lease/domain/entities/lease.dart';
import '../../domain/entities/repair_order.dart';
import '../models/repair_order_model.dart';

const noActiveRepairLeaseMessage = '暂无有效租房合同';

abstract class RepairServiceContract {
  Future<RepairOverview> fetchOverview();
  Future<RepairOrder> fetchRepairDetail(String repairId);
  Future<RepairOrder> createRepair(CreateRepairRequest request);
  Future<RepairOrder> submitReview({
    required String repairId,
    required int rating,
    required String content,
  });
  Future<RepairOrder> cancelRepair(String repairId);
}

class RepairService implements RepairServiceContract {
  RepairService(
    this._apiClient, {
    RepairServiceContract? fallback,
    this.allowMockFallback = true,
  }) : _fallback = fallback ?? MockRepairService();

  final ApiClient _apiClient;
  final RepairServiceContract _fallback;
  final bool allowMockFallback;

  @override
  Future<RepairOverview> fetchOverview() async {
    try {
      return await _fetchRemoteOverview();
    } on Object catch (error) {
      AppLoggerDebug.debug('RepairService overview load failed: $error');
      rethrow;
    }
  }

  @override
  Future<RepairOrder> fetchRepairDetail(String repairId) async {
    try {
      final response = await _request(
        () => _apiClient.get('/repairs/$repairId'),
      );
      return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
    } on Object catch (error) {
      if (!allowMockFallback) rethrow;
      AppLoggerDebug.debug('RepairService fallback to mock detail: $error');
      return _fallback.fetchRepairDetail(repairId);
    }
  }

  @override
  Future<RepairOrder> createRepair(CreateRepairRequest request) async {
    try {
      final response = await _request(
        () => _apiClient.post('/repairs', data: repairRequestToJson(request)),
      );
      return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
    } on Object catch (error) {
      if (!allowMockFallback) rethrow;
      AppLoggerDebug.debug('RepairService fallback to mock create: $error');
      return _fallback.createRepair(request);
    }
  }

  @override
  Future<RepairOrder> submitReview({
    required String repairId,
    required int rating,
    required String content,
  }) async {
    try {
      final response = await _request(
        () => _apiClient.post(
          '/repairs/$repairId/review',
          data: {'rating': rating, 'reviewContent': content},
        ),
      );
      return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
    } on Object catch (error) {
      if (!allowMockFallback) rethrow;
      AppLoggerDebug.debug('RepairService fallback to mock review: $error');
      return _fallback.submitReview(
        repairId: repairId,
        rating: rating,
        content: content,
      );
    }
  }

  @override
  Future<RepairOrder> cancelRepair(String repairId) async {
    try {
      final response = await _request(
        () => _apiClient.post('/repairs/$repairId/cancel'),
      );
      return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
    } on Object catch (error) {
      if (!allowMockFallback) rethrow;
      AppLoggerDebug.debug('RepairService fallback to mock cancel: $error');
      return _fallback.cancelRepair(repairId);
    }
  }

  Future<RepairOverview> _fetchRemoteOverview() async {
    final responses = await Future.wait([
      _request(() => _apiClient.get('/repairs/my')),
      _request(() => _apiClient.get('/leases/my')),
    ]);
    final repairsPayload = _payload(responses[0].data);
    final leasePayload = _payload(responses[1].data);
    final orders = _list(
      repairsPayload,
    ).map((json) => RepairOrderModel(json).toEntity()).toList();
    final leases = _leaseList(
      leasePayload,
    ).map((json) => LeaseModel(json).toEntity()).toList();
    final repairHouses = _repairLeases(
      leases,
    ).map(_repairHouseFromLease).toList(growable: false);
    return RepairOverview(
      currentHouse: repairHouses.first,
      availableHouses: repairHouses,
      orders: orders,
    );
  }

  Future<Response<dynamic>> _request(
    Future<ApiResult<Response<dynamic>>> Function() request,
  ) async {
    final result = await request();
    return result.when(
      success: (response) => response,
      failure: (message, error) => throw error is ApiException
          ? error
          : ApiException(
              type: ApiExceptionType.unknown,
              message: message,
              cause: error,
            ),
    );
  }

  dynamic _payload(dynamic body) {
    if (body is! Map<String, dynamic>) return body;
    final code = body['code'];
    if (code is num && code != 0 && code != 200) {
      throw ApiException(
        type: ApiExceptionType.server,
        message: body['message']?.toString() ?? '报修服务请求失败',
        statusCode: code.toInt(),
      );
    }
    return body.containsKey('data') ? body['data'] : body;
  }

  Map<String, dynamic> _firstMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final source = payload['items'] ?? payload['records'] ?? payload['list'];
      if (source is List && source.isNotEmpty && source.first is Map) {
        return Map<String, dynamic>.from(source.first as Map);
      }
      return payload;
    }
    if (payload is List && payload.isNotEmpty && payload.first is Map) {
      return Map<String, dynamic>.from(payload.first as Map);
    }
    throw const ApiException(
      type: ApiExceptionType.server,
      message: '报修数据格式错误',
    );
  }

  List<Map<String, dynamic>> _list(dynamic payload) {
    dynamic source = payload;
    if (payload is Map<String, dynamic>) {
      source = payload['items'] ?? payload['records'] ?? payload['list'];
    }
    if (source is! List) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '报修列表数据格式错误',
      );
    }
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _leaseList(dynamic payload) {
    dynamic source = payload;
    if (payload is Map<String, dynamic>) {
      source =
          payload['items'] ??
          payload['records'] ??
          payload['rows'] ??
          payload['content'] ??
          payload['list'] ??
          payload['leases'];
      if (source == null) {
        final current =
            payload['current'] ??
            payload['currentLease'] ??
            payload['currentLeases'] ??
            payload['activeLease'] ??
            payload['activeLeases'];
        final history =
            payload['history'] ??
            payload['historical'] ??
            payload['historyLease'] ??
            payload['historyLeases'] ??
            payload['historicalLeases'];
        source = [
          if (current is Map<String, dynamic>) current,
          if (current is List) ...current,
          if (history is Map<String, dynamic>) history,
          if (history is List) ...history,
        ];
      }
    }
    if (source == null && payload is Map<String, dynamic>) {
      source = [payload];
    }
    if (source is! List) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '租约列表数据格式错误',
      );
    }
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Lease> _repairLeases(List<Lease> leases) {
    if (leases.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: noActiveRepairLeaseMessage,
      );
    }
    final activeLeases = leases
        .where((lease) => lease.status == LeaseStatus.active)
        .toList(growable: false);
    if (activeLeases.isNotEmpty) return activeLeases;
    throw const ApiException(
      type: ApiExceptionType.server,
      message: noActiveRepairLeaseMessage,
    );
  }

  RepairHouse _repairHouseFromLease(Lease lease) {
    return RepairHouse(
      houseId: lease.houseId,
      houseName: lease.houseName,
      roomName: lease.houseName,
      leaseStatus: lease.status.label,
      housekeeperName: lease.keeperName,
      housekeeperPhone: lease.keeperPhone,
    );
  }
}

class MockRepairService implements RepairServiceContract {
  MockRepairService() : _orders = List<RepairOrder>.of(_mockOrders);

  final List<RepairOrder> _orders;

  @override
  Future<RepairOverview> fetchOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    _sortOrders();
    return RepairOverview(
      currentHouse: _mockHouse,
      availableHouses: const [_mockHouse],
      orders: List.of(_orders),
    );
  }

  @override
  Future<RepairOrder> fetchRepairDetail(String repairId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _orders.firstWhere(
      (order) => order.id == repairId,
      orElse: () => _orders.first,
    );
  }

  @override
  Future<RepairOrder> createRepair(CreateRepairRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final now = DateTime.now();
    final order = RepairOrder(
      id: 'repair-${now.millisecondsSinceEpoch}',
      orderNo:
          'BX${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${_orders.length + 1}',
      houseId: request.houseId,
      houseName: request.houseName,
      roomName: request.roomName,
      repairType: request.repairType,
      description: request.description,
      imageUrls: request.imageUrls,
      contactName: request.contactName,
      contactPhone: request.contactPhone,
      expectedVisitTime: request.expectedVisitTime,
      status: RepairStatus.submitted,
      housekeeperName: _mockHouse.housekeeperName,
      housekeeperPhone: _mockHouse.housekeeperPhone,
      repairmanName: '',
      createdAt: now,
      updatedAt: now,
      timeline: [
        RepairTimelineItem(
          title: '已提交',
          description: '用户提交报修，等待管家受理',
          time: now,
          status: RepairStatus.submitted,
        ),
      ],
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<RepairOrder> submitReview({
    required String repairId,
    required int rating,
    required String content,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final index = _orders.indexWhere((order) => order.id == repairId);
    if (index < 0) return _orders.first;
    final now = DateTime.now();
    final order = _orders[index].copyWith(
      status: RepairStatus.completed,
      rating: rating,
      reviewContent: content,
      updatedAt: now,
      timeline: [
        ..._orders[index].timeline,
        RepairTimelineItem(
          title: '已评价',
          description: '用户已提交服务评价',
          time: now,
          status: RepairStatus.completed,
        ),
      ],
    );
    _orders[index] = order;
    return order;
  }

  @override
  Future<RepairOrder> cancelRepair(String repairId) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final index = _orders.indexWhere((order) => order.id == repairId);
    if (index < 0) return _orders.first;
    final now = DateTime.now();
    final order = _orders[index].copyWith(
      status: RepairStatus.cancelled,
      updatedAt: now,
      timeline: [
        ..._orders[index].timeline,
        RepairTimelineItem(
          title: '已取消',
          description: '用户取消报修工单',
          time: now,
          status: RepairStatus.cancelled,
        ),
      ],
    );
    _orders[index] = order;
    return order;
  }

  void _sortOrders() {
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

const _mockHouse = RepairHouse(
  houseId: 'house-001',
  houseName: '3栋2单元1201',
  roomName: '3栋2单元1201',
  leaseStatus: '履约中',
  housekeeperName: '小住管家',
  housekeeperPhone: '400-800-1234',
);

final _mockOrders = <RepairOrder>[
  _mockOrder(
    1,
    RepairType.plumbing,
    RepairStatus.submitted,
    '厨房水槽下方水管持续滴水，地面已经有积水。',
    DateTime(2026, 6, 22, 9, 20),
  ),
  _mockOrder(
    2,
    RepairType.appliance,
    RepairStatus.processing,
    '卧室空调开启后不制冷，运行十分钟仍只有自然风。',
    DateTime(2026, 6, 20, 14, 10),
    repairmanName: '李师傅',
  ),
  _mockOrder(
    3,
    RepairType.lock,
    RepairStatus.processing,
    '智能门锁偶发无法识别密码，需要多次尝试。',
    DateTime(2026, 6, 18, 18, 42),
    repairmanName: '周师傅',
  ),
  _mockOrder(
    4,
    RepairType.appliance,
    RepairStatus.pendingReview,
    '洗衣机排水异常，维修人员已完成处理。',
    DateTime(2026, 6, 12, 10, 5),
    completedAt: DateTime(2026, 6, 13, 16, 30),
    repairmanName: '王师傅',
  ),
  _mockOrder(
    5,
    RepairType.network,
    RepairStatus.completed,
    '客厅网络无法连接，路由器重启无效。',
    DateTime(2026, 6, 8, 20, 15),
    completedAt: DateTime(2026, 6, 9, 11, 0),
    repairmanName: '赵师傅',
    rating: 5,
    reviewContent: '处理很及时，网络恢复正常。',
  ),
  _mockOrder(
    6,
    RepairType.furniture,
    RepairStatus.completed,
    '衣柜门铰链松动，开合有异响。',
    DateTime(2026, 5, 29, 15, 40),
    completedAt: DateTime(2026, 5, 30, 17, 10),
    repairmanName: '陈师傅',
    rating: 4,
    reviewContent: '维修完成，整体满意。',
  ),
  _mockOrder(
    7,
    RepairType.electrical,
    RepairStatus.cancelled,
    '卫生间插座使用时跳闸，后续自行排查为电器问题。',
    DateTime(2026, 5, 22, 8, 30),
  ),
  _mockOrder(
    8,
    RepairType.appliance,
    RepairStatus.completed,
    '热水器水温忽冷忽热，需要检查。',
    DateTime(2026, 5, 16, 19, 12),
    completedAt: DateTime(2026, 5, 17, 15, 0),
    repairmanName: '孙师傅',
    rating: 5,
    reviewContent: '师傅专业，已恢复正常。',
  ),
];

RepairOrder _mockOrder(
  int index,
  RepairType type,
  RepairStatus status,
  String description,
  DateTime createdAt, {
  DateTime? completedAt,
  String repairmanName = '',
  int? rating,
  String? reviewContent,
}) {
  final timeline = <RepairTimelineItem>[
    RepairTimelineItem(
      title: '已提交',
      description: '用户提交报修',
      time: createdAt,
      status: RepairStatus.submitted,
    ),
  ];
  if (status.index >= RepairStatus.accepted.index &&
      status != RepairStatus.cancelled) {
    timeline.add(
      RepairTimelineItem(
        title: '已受理',
        description: '管家已受理工单',
        time: createdAt.add(const Duration(hours: 1)),
        status: RepairStatus.accepted,
      ),
    );
  }
  if (status.index >= RepairStatus.processing.index &&
      status != RepairStatus.cancelled) {
    timeline.add(
      RepairTimelineItem(
        title: '处理中',
        description: repairmanName.isEmpty ? '维修人员处理中' : '$repairmanName处理中',
        time: createdAt.add(const Duration(hours: 4)),
        status: RepairStatus.processing,
      ),
    );
  }
  if (status == RepairStatus.pendingReview ||
      status == RepairStatus.completed) {
    timeline.add(
      RepairTimelineItem(
        title: '已完成',
        description: '维修已完成，等待用户评价',
        time: completedAt ?? createdAt.add(const Duration(days: 1)),
        status: RepairStatus.pendingReview,
      ),
    );
  }
  if (status == RepairStatus.completed && rating != null) {
    timeline.add(
      RepairTimelineItem(
        title: '已评价',
        description: '用户已完成评价',
        time: (completedAt ?? createdAt.add(const Duration(days: 1))).add(
          const Duration(hours: 2),
        ),
        status: RepairStatus.completed,
      ),
    );
  }
  if (status == RepairStatus.cancelled) {
    timeline.add(
      RepairTimelineItem(
        title: '已取消',
        description: '用户取消报修',
        time: createdAt.add(const Duration(minutes: 40)),
        status: RepairStatus.cancelled,
      ),
    );
  }

  return RepairOrder(
    id: 'repair-${index.toString().padLeft(3, '0')}',
    orderNo: 'BX202606${index.toString().padLeft(3, '0')}',
    houseId: _mockHouse.houseId,
    houseName: _mockHouse.houseName,
    roomName: _mockHouse.roomName,
    repairType: type,
    description: description,
    imageUrls: const [],
    contactName: '王小明',
    contactPhone: '138****2468',
    expectedVisitTime: createdAt.add(const Duration(days: 1, hours: 2)),
    status: status,
    housekeeperName: _mockHouse.housekeeperName,
    housekeeperPhone: _mockHouse.housekeeperPhone,
    repairmanName: repairmanName,
    createdAt: createdAt,
    updatedAt: completedAt ?? createdAt,
    completedAt: completedAt,
    rating: rating,
    reviewContent: reviewContent,
    timeline: timeline,
  );
}
