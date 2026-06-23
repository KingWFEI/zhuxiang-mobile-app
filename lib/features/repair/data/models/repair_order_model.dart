import '../../domain/entities/repair_order.dart';

class RepairTimelineItemModel {
  const RepairTimelineItemModel(this.json);

  final Map<String, dynamic> json;

  RepairTimelineItem toEntity() {
    return RepairTimelineItem(
      title: _string(json['title'], fallback: '进度更新'),
      description: _string(json['description']),
      time: _date(json['time']) ?? DateTime.now(),
      status: RepairStatus.fromValue(json['status']),
    );
  }
}

class RepairOrderModel {
  const RepairOrderModel(this.json);

  final Map<String, dynamic> json;

  RepairOrder toEntity() {
    final type = RepairType.fromValue(json['repairType'] ?? json['type']);
    final status = RepairStatus.fromValue(json['status']);
    return RepairOrder(
      id: _string(json['id']),
      orderNo: _string(json['orderNo'] ?? json['order_no']),
      houseId: _string(json['houseId'] ?? json['house_id']),
      houseName: _string(json['houseName'] ?? json['house_name']),
      roomName: _string(json['roomName'] ?? json['room_name']),
      repairType: type,
      description: _string(json['description']),
      imageUrls: _stringList(json['imageUrls'] ?? json['attachments']),
      contactName: _string(json['contactName'] ?? json['contact_name']),
      contactPhone: _string(json['contactPhone'] ?? json['contact_phone']),
      expectedVisitTime: _date(
        json['expectedVisitTime'] ?? json['expected_visit_time'],
      ),
      status: status,
      housekeeperName: _string(
        json['housekeeperName'] ?? json['housekeeper_name'],
      ),
      housekeeperPhone: _string(
        json['housekeeperPhone'] ?? json['housekeeper_phone'],
      ),
      repairmanName: _string(json['repairmanName'] ?? json['repairman_name']),
      createdAt:
          _date(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt:
          _date(json['updatedAt'] ?? json['updated_at']) ?? DateTime.now(),
      completedAt: _date(json['completedAt'] ?? json['completed_at']),
      rating: _int(json['rating']),
      reviewContent: _nullableString(
        json['reviewContent'] ?? json['review_content'],
      ),
      timeline: _timeline(json['timeline']),
    );
  }
}

class RepairHouseModel {
  const RepairHouseModel(this.json);

  final Map<String, dynamic> json;

  RepairHouse toEntity() {
    return RepairHouse(
      houseId: _string(
        json['houseId'] ?? json['house_id'],
        fallback: 'house-001',
      ),
      houseName: _string(
        json['houseName'] ?? json['house_name'],
        fallback: '3栋2单元1201',
      ),
      roomName: _string(
        json['roomName'] ?? json['room_name'],
        fallback: '3栋2单元1201',
      ),
      leaseStatus: _string(
        json['leaseStatus'] ?? json['lease_status'],
        fallback: '履约中',
      ),
      housekeeperName: _string(
        json['housekeeperName'] ?? json['housekeeper_name'],
        fallback: '小住管家',
      ),
      housekeeperPhone: _string(
        json['housekeeperPhone'] ?? json['housekeeper_phone'],
        fallback: '400-800-1234',
      ),
    );
  }
}

Map<String, dynamic> repairRequestToJson(CreateRepairRequest request) {
  return {
    'houseId': request.houseId,
    'houseName': request.houseName,
    'roomName': request.roomName,
    'repairType': request.repairType.value,
    'description': request.description,
    'imageUrls': request.imageUrls,
    'contactName': request.contactName,
    'contactPhone': request.contactPhone,
    'expectedVisitTime': request.expectedVisitTime?.toIso8601String(),
  };
}

List<RepairTimelineItem> _timeline(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            RepairTimelineItemModel(Map<String, dynamic>.from(item)).toEntity(),
      )
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
