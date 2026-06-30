import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/lease/data/models/lease_model.dart';
import 'package:zhuxiang_app/features/lease/data/providers/lease_providers.dart';
import 'package:zhuxiang_app/features/lease/data/services/lease_service.dart';
import 'package:zhuxiang_app/features/lease/domain/entities/lease.dart';
import 'package:zhuxiang_app/features/lease/domain/entities/lease_contract_document.dart';
import 'package:zhuxiang_app/features/lease/domain/entities/lease_termination.dart';
import 'package:zhuxiang_app/features/lease/presentation/pages/my_leases_page.dart';

void main() {
  test('LeaseModel adapts nested backend fields', () {
    final lease = LeaseModel({
      'leaseId': 'lease-api-1',
      'contractId': 'contract-api-1',
      'house': {
        'id': 'house-1',
        'title': '中央公园1栋1201',
        'address': '重庆市渝北区中央公园',
        'roomType': '一居室',
        'area': 42,
        'orientation': '朝南',
      },
      'tenant': {
        'realName': '王小明',
        'phone': '13800138000',
        'idCard': '500101199605201234',
      },
      'leaseStartDate': '2026-03-01',
      'leaseEndDate': '2027-02-28',
      'rentAmount': 2680,
      'depositAmount': 2680,
      'paymentCycle': '押一付一',
      'leaseStatus': 'active',
      'contractStatus': 'signed',
      'billStatus': 'unpaid',
      'lockPermissionStatus': 'active',
    }).toEntity();

    expect(lease.id, 'lease-api-1');
    expect(lease.contractId, 'contract-api-1');
    expect(lease.houseName, '中央公园1栋1201');
    expect(lease.monthlyRent, 268000);
    expect(lease.status, LeaseStatus.active);
    expect(lease.lockPermissionStatus, LeaseLockPermissionStatus.active);
    expect(lease.maskedTenantPhone, '138****8000');
  });

  test('LeaseModel maps terminated lease as checked out history', () {
    final lease = LeaseModel({
      'leaseId': 'lease-api-terminated',
      'contractId': 'contract-api-terminated',
      'houseName': '中央公园1栋1201',
      'leaseStatus': 'terminated',
    }).toEntity();

    expect(lease.status, LeaseStatus.checkedOut);
    expect(lease.isCurrent, isFalse);
  });

  test('mock lease datasource moves checked out lease to history', () async {
    final service = MockLeaseService();
    final before = await service.getMyLeases();
    expect(before.where((lease) => lease.isCurrent), hasLength(1));

    await service.checkout('lease-2026-001');
    final after = await service.getMyLeases();
    expect(after.where((lease) => lease.isCurrent), isEmpty);
    expect(
      after.firstWhere((lease) => lease.id == 'lease-2026-001').status,
      LeaseStatus.checkedOut,
    );
  });

  testWidgets('my leases page renders success and history states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaseServiceProvider.overrideWithValue(_FakeLeaseService()),
        ],
        child: const MaterialApp(
          home: MyLeasesPage(enforceAuthentication: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的租约'), findsOneWidget);
    expect(find.text('3栋2单元1201'), findsOneWidget);
    expect(find.text('续租申请'), findsOneWidget);
    expect(find.text('专属管家'), findsOneWidget);
    expect(find.text('3月租金待支付'), findsOneWidget);

    await tester.tap(find.text('历史租约'));
    await tester.pumpAndSettle();
    expect(find.text('悦来公寓6栋802'), findsOneWidget);
    expect(find.text('查看详情'), findsOneWidget);
  });

  testWidgets('my leases page renders empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaseServiceProvider.overrideWithValue(
            _FakeLeaseService(leases: const []),
          ),
        ],
        child: const MaterialApp(
          home: MyLeasesPage(enforceAuthentication: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂无当前租约'), findsOneWidget);
  });

  testWidgets('my leases page renders error and retry state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaseServiceProvider.overrideWithValue(
            _FakeLeaseService(shouldFail: true),
          ),
        ],
        child: const MaterialApp(
          home: MyLeasesPage(enforceAuthentication: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('租约服务不可用'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}

class _FakeLeaseService implements LeaseServiceContract {
  _FakeLeaseService({List<Lease>? leases, this.shouldFail = false})
    : _leases = leases ?? _defaultLeases;

  final bool shouldFail;
  final List<Lease> _leases;

  @override
  Future<List<Lease>> getMyLeases() async {
    if (shouldFail) throw Exception('租约服务不可用');
    return _leases;
  }

  @override
  Future<Lease> getLeaseDetail(String leaseId) async {
    return _leases.firstWhere((lease) => lease.id == leaseId);
  }

  @override
  Future<LeaseContractDocument> getLeaseContract(String leaseId) async {
    final lease = _leases.firstWhere((lease) => lease.id == leaseId);
    return LeaseContractDocument(
      id: 'contract-$leaseId',
      contractNo: 'HT202603010001',
      houseName: lease.houseName,
      tenantName: lease.tenantName,
      startDate: lease.startDate,
      endDate: lease.endDate,
      monthlyRent: lease.monthlyRent,
      deposit: lease.deposit,
      paymentMethod: lease.paymentMethod,
      statusText: lease.contractStatus.label,
      content: '测试合同正文',
      fileUrl: '',
      clauses: const [],
      signedAt: lease.startDate,
    );
  }

  @override
  Future<void> renew(String leaseId) async {}

  @override
  Future<void> checkout(String leaseId) async {}

  @override
  Future<LeaseTerminationAttachment> uploadTerminationAttachment({
    required String filePath,
    required String fileName,
  }) async {
    return LeaseTerminationAttachment(
      url: 'mock://lease-termination/$fileName',
      type: 'image',
      name: fileName,
    );
  }

  @override
  Future<LeaseTerminationApplication> submitTerminationApplication(
    String leaseId,
    LeaseTerminationRequest request,
  ) async {
    return const LeaseTerminationApplication(
      id: 'termination-1',
      applicationNo: 'TZ202606290001',
      status: 'pending_review',
      statusText: '待审核',
    );
  }

  @override
  Future<LeaseTerminationApplication?> getCurrentTerminationApplication(
    String contractId,
  ) async {
    return null;
  }
}

final _defaultLeases = <Lease>[
  Lease(
    id: 'lease-2026-001',
    contractId: 'contract-2026-001',
    houseId: 'house-1',
    houseName: '3栋2单元1201',
    houseAddress: '重庆市渝北区中央公园',
    houseSummary: '温馨一居 · 42㎡ · 朝南',
    houseImageUrl: '',
    tenantName: '王小明',
    tenantPhone: '13800138000',
    tenantIdCard: '500101199605201234',
    startDate: DateTime(2026, 3, 1),
    endDate: DateTime(2027, 2, 28),
    monthlyRent: 268000,
    deposit: 268000,
    paymentMethod: '押一付一',
    paymentDay: 5,
    status: LeaseStatus.active,
    contractStatus: LeaseContractStatus.signed,
    billStatus: LeaseBillStatus.unpaid,
    lockPermissionStatus: LeaseLockPermissionStatus.active,
    keeperName: '小住管家',
    keeperPhone: '400-800-2026',
    pendingBillTitle: '3月租金待支付',
    pendingBillAmount: 268000,
    pendingBillDueDate: DateTime(2026, 3, 5),
  ),
  Lease(
    id: 'lease-2025-001',
    contractId: 'contract-2025-001',
    houseId: 'house-2',
    houseName: '悦来公寓6栋802',
    houseAddress: '重庆市渝北区悦来大道',
    houseSummary: '精装两居 · 68㎡ · 南北通透',
    houseImageUrl: '',
    tenantName: '王小明',
    tenantPhone: '13800138000',
    tenantIdCard: '500101199605201234',
    startDate: DateTime(2025, 3, 1),
    endDate: DateTime(2026, 2, 28),
    monthlyRent: 320000,
    deposit: 320000,
    paymentMethod: '押一付一',
    paymentDay: 5,
    status: LeaseStatus.expired,
    contractStatus: LeaseContractStatus.signed,
    billStatus: LeaseBillStatus.paid,
    lockPermissionStatus: LeaseLockPermissionStatus.expired,
    keeperName: '小住管家',
    keeperPhone: '400-800-2026',
    pendingBillTitle: '',
    pendingBillAmount: 0,
    pendingBillDueDate: DateTime(2026, 2, 5),
  ),
];
