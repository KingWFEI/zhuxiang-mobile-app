import '../../domain/entities/lease.dart';

class LeaseModel {
  const LeaseModel(this.json);

  final Map<String, dynamic> json;

  Lease toEntity() {
    final house = _map(json['house'] ?? json['houseInfo']);
    final tenant = _map(json['tenant'] ?? json['tenantInfo']);
    final bill = _map(json['pendingBill'] ?? json['latestBill']);
    final keeper = _map(json['keeper'] ?? json['houseKeeper']);

    return Lease(
      id: _string(json, ['id', 'leaseId']),
      houseId: _string(json, ['houseId'], fallback: _string(house, ['id'])),
      houseName: _string(
        json,
        ['houseName', 'houseTitle'],
        fallback: _string(house, [
          'name',
          'title',
          'roomNumber',
        ], fallback: '租住房屋'),
      ),
      houseAddress: _string(json, [
        'houseAddress',
        'address',
      ], fallback: _string(house, ['address', 'fullAddress'])),
      houseSummary: _string(json, [
        'houseSummary',
        'roomSummary',
      ], fallback: _buildHouseSummary(house)),
      houseImageUrl: _string(json, [
        'houseImageUrl',
        'coverImage',
      ], fallback: _string(house, ['coverImage', 'imageUrl'])),
      tenantName: _string(json, [
        'tenantName',
      ], fallback: _string(tenant, ['name', 'realName'], fallback: '住享租客')),
      tenantPhone: _string(json, [
        'tenantPhone',
      ], fallback: _string(tenant, ['phone', 'mobile'])),
      tenantIdCard: _string(json, [
        'tenantIdCard',
        'idCardNumber',
      ], fallback: _string(tenant, ['idCardNumber', 'idCard'])),
      startDate: _date(json, ['startDate', 'leaseStartDate']),
      endDate: _date(json, ['endDate', 'leaseEndDate']),
      monthlyRent: _money(json, ['monthlyRent', 'rentAmount', 'rent']),
      deposit: _money(json, ['deposit', 'depositAmount']),
      paymentMethod: _string(json, [
        'paymentMethod',
        'paymentCycle',
      ], fallback: '押一付一'),
      paymentDay: _integer(json, ['paymentDay', 'rentPaymentDay'], fallback: 5),
      status: _leaseStatus(_string(json, ['status', 'leaseStatus'])),
      contractStatus: _contractStatus(
        _string(json, [
          'contractStatus',
        ], fallback: _string(_map(json['contract']), ['status'])),
      ),
      billStatus: _billStatus(
        _string(json, ['billStatus'], fallback: _string(bill, ['status'])),
      ),
      lockPermissionStatus: _lockStatus(
        _string(json, ['lockPermissionStatus', 'lockStatus']),
      ),
      keeperName: _string(json, [
        'keeperName',
      ], fallback: _string(keeper, ['name'], fallback: '小住管家')),
      keeperPhone: _string(json, [
        'keeperPhone',
      ], fallback: _string(keeper, ['phone'], fallback: '400-800-2026')),
      pendingBillTitle: _string(json, [
        'pendingBillTitle',
      ], fallback: _string(bill, ['title'], fallback: '本月租金待支付')),
      pendingBillAmount: _money(json, [
        'pendingBillAmount',
      ], fallback: _money(bill, ['amount'])),
      pendingBillDueDate: _date(json, [
        'pendingBillDueDate',
      ], fallback: _date(bill, ['dueDate'])),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map<String, dynamic> ? value : const {};
  }

  static String _string(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static int _integer(
    Map<String, dynamic> source,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static int _money(
    Map<String, dynamic> source,
    List<String> keys, {
    int fallback = 0,
  }) {
    final value = _integer(source, keys, fallback: fallback);
    if (value <= 0 || value >= 100000) return value;
    return value * 100;
  }

  static DateTime _date(
    Map<String, dynamic> source,
    List<String> keys, {
    DateTime? fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback ?? DateTime(2026, 3, 1);
  }

  static String _buildHouseSummary(Map<String, dynamic> house) {
    final roomType = _string(house, ['roomType', 'layout'], fallback: '温馨一居');
    final area = _integer(house, ['area']);
    final orientation = _string(house, ['orientation'], fallback: '朝南');
    return '$roomType · ${area > 0 ? '$area㎡' : '42㎡'} · $orientation';
  }

  static LeaseStatus _leaseStatus(String value) {
    return switch (value.toLowerCase()) {
      'pending' || 'pending_effective' => LeaseStatus.pending,
      'expired' => LeaseStatus.expired,
      'checkedout' || 'checked_out' || 'checkout' => LeaseStatus.checkedOut,
      'cancelled' || 'canceled' => LeaseStatus.cancelled,
      _ => LeaseStatus.active,
    };
  }

  static LeaseContractStatus _contractStatus(String value) {
    return switch (value.toLowerCase()) {
      'unsigned' || 'draft' || 'pending' => LeaseContractStatus.unsigned,
      'voided' || 'invalid' || 'cancelled' => LeaseContractStatus.voided,
      _ => LeaseContractStatus.signed,
    };
  }

  static LeaseBillStatus _billStatus(String value) {
    return switch (value.toLowerCase()) {
      'unpaid' || 'pending' => LeaseBillStatus.unpaid,
      'overdue' => LeaseBillStatus.overdue,
      'paid' || 'settled' => LeaseBillStatus.paid,
      _ => LeaseBillStatus.normal,
    };
  }

  static LeaseLockPermissionStatus _lockStatus(String value) {
    return switch (value.toLowerCase()) {
      'inactive' || 'pending' => LeaseLockPermissionStatus.inactive,
      'expired' => LeaseLockPermissionStatus.expired,
      'revoked' || 'disabled' => LeaseLockPermissionStatus.revoked,
      _ => LeaseLockPermissionStatus.active,
    };
  }
}
