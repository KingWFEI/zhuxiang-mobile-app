import '../../domain/entities/lease.dart';

class LeaseModel {
  const LeaseModel(this.json);

  final Map<String, dynamic> json;

  Lease toEntity() {
    final house = _map(
      json['house'] ?? json['houseInfo'] ?? json['houseSnapshot'],
    );
    final tenant = _map(
      json['tenant'] ?? json['tenantInfo'] ?? json['tenantSnapshot'],
    );
    final bill = _map(json['pendingBill'] ?? json['latestBill']);
    final keeper = _map(json['keeper'] ?? json['houseKeeper']);

    return Lease(
      id: _string(json, ['id', 'leaseId', 'lease_id']),
      houseId: _string(json, [
        'houseId',
        'house_id',
      ], fallback: _string(house, ['id', 'houseId', 'house_id'])),
      houseName: _string(
        json,
        ['houseName', 'houseTitle', 'roomName', 'title', 'house_name'],
        fallback: _string(house, [
          'name',
          'title',
          'roomNumber',
          'roomName',
        ], fallback: _buildFlatHouseName(json)),
      ),
      houseAddress: _string(
        json,
        ['houseAddress', 'address', 'fullAddress', 'house_address'],
        fallback: _string(house, [
          'address',
          'fullAddress',
        ], fallback: _buildFlatHouseName(json)),
      ),
      houseSummary: _string(json, [
        'houseSummary',
        'roomSummary',
      ], fallback: _buildHouseSummary(house)),
      houseImageUrl: _string(json, [
        'houseImageUrl',
        'houseCoverUrl',
        'coverImage',
        'coverUrl',
      ], fallback: _string(house, ['coverImage', 'imageUrl', 'coverUrl'])),
      tenantName: _string(json, [
        'tenantName',
        'tenant_name',
      ], fallback: _string(tenant, ['name', 'realName'], fallback: '住享租客')),
      tenantPhone: _string(json, [
        'tenantPhone',
        'tenant_phone',
      ], fallback: _string(tenant, ['phone', 'mobile'])),
      tenantIdCard: _string(json, [
        'tenantIdCard',
        'idCardNumber',
        'tenant_id_card',
        'id_card_number',
      ], fallback: _string(tenant, ['idCardNumber', 'idCard'])),
      startDate: _date(json, ['startDate', 'leaseStartDate', 'start_date']),
      endDate: _date(json, ['endDate', 'leaseEndDate', 'end_date']),
      monthlyRent: _money(json, [
        'monthlyRent',
        'monthly_rent',
        'rentAmount',
        'rent_amount',
        'rent',
      ]),
      deposit: _money(json, ['deposit', 'depositAmount', 'deposit_amount']),
      paymentMethod: _paymentMethodLabel(
        _string(json, [
          'paymentMethod',
          'paymentCycle',
          'payment_method',
        ], fallback: 'monthly'),
      ),
      paymentDay: _integer(json, [
        'paymentDay',
        'rentPaymentDay',
        'payment_day',
      ], fallback: 5),
      status: _leaseStatus(
        _string(json, ['status', 'leaseStatus', 'lease_status']),
      ),
      contractStatus: _contractStatus(
        _string(json, [
          'contractStatus',
          'contract_status',
        ], fallback: _string(_map(json['contract']), ['status'])),
      ),
      billStatus: _billStatus(
        _string(json, [
          'billStatus',
          'bill_status',
        ], fallback: _string(bill, ['status'])),
      ),
      lockPermissionStatus: _lockStatus(
        _string(json, [
          'lockPermissionStatus',
          'lockStatus',
          'lock_permission_status',
          'lock_status',
        ]),
      ),
      keeperName: _string(json, [
        'keeperName',
        'keeper_name',
      ], fallback: _string(keeper, ['name'], fallback: '小住管家')),
      keeperPhone: _string(json, [
        'keeperPhone',
        'keeper_phone',
      ], fallback: _string(keeper, ['phone'], fallback: '400-800-2026')),
      pendingBillTitle: _string(json, [
        'pendingBillTitle',
        'pending_bill_title',
      ], fallback: _string(bill, ['title'], fallback: '本月租金待支付')),
      pendingBillAmount: _money(json, [
        'pendingBillAmount',
        'pending_bill_amount',
      ], fallback: _money(bill, ['amount'])),
      pendingBillDueDate: _date(json, [
        'pendingBillDueDate',
        'pending_bill_due_date',
      ], fallback: _date(bill, ['dueDate', 'due_date'])),
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
    return '$roomType · ${area > 0 ? '${area}m²' : '42m²'} · $orientation';
  }

  static String _buildFlatHouseName(Map<String, dynamic> source) {
    final community = _string(source, ['community']);
    final building = _string(source, ['building']);
    final unit = _string(source, ['unit']);
    final room = _string(source, ['room']);
    final parts = [
      community,
      building,
      unit,
      room,
    ].where((part) => part.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? '租住房屋' : parts.join(' ');
  }

  static String _paymentMethodLabel(String value) {
    return switch (value) {
      'monthly' || '押一付一' || '月付' => '月付',
      'quarterly' || '押一付三' || '季付' => '季付',
      'semi_annual' || '押一付六' || '半年付' => '半年付',
      'annual' || '押一付十二' || '年付' => '年付',
      _ => value,
    };
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
      'expired' => LeaseLockPermissionStatus.expired,
      'revoked' || 'disabled' => LeaseLockPermissionStatus.revoked,
      _ => LeaseLockPermissionStatus.active,
    };
  }
}
