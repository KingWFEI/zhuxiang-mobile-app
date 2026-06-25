enum RepairType {
  plumbing,
  electrical,
  appliance,
  lock,
  furniture,
  network,
  other;

  String get label => switch (this) {
    RepairType.plumbing => '水电维修',
    RepairType.electrical => '电路问题',
    RepairType.appliance => '家电故障',
    RepairType.lock => '门锁问题',
    RepairType.furniture => '家具损坏',
    RepairType.network => '网络问题',
    RepairType.other => '其他问题',
  };

  String get value => name;

  static RepairType fromValue(Object? value) {
    final text = value?.toString();
    return RepairType.values.firstWhere(
      (type) => type.name == text,
      orElse: () => RepairType.other,
    );
  }
}

enum RepairStatus {
  submitted,
  accepted,
  assigned,
  processing,
  pendingReview,
  completed,
  cancelled;

  String get label => switch (this) {
    RepairStatus.submitted => '待受理',
    RepairStatus.accepted => '已受理',
    RepairStatus.assigned => '已分派',
    RepairStatus.processing => '处理中',
    RepairStatus.pendingReview => '待评价',
    RepairStatus.completed => '已完成',
    RepairStatus.cancelled => '已取消',
  };

  bool get canReview => this == RepairStatus.pendingReview;
  bool get isClosed =>
      this == RepairStatus.completed || this == RepairStatus.cancelled;

  static RepairStatus fromValue(Object? value) {
    final text = value?.toString();
    return RepairStatus.values.firstWhere(
      (status) => status.name == text,
      orElse: () => RepairStatus.submitted,
    );
  }
}

enum RepairStatusFilter {
  all,
  submitted,
  processing,
  pendingReview,
  completed,
  cancelled;

  String get label => switch (this) {
    RepairStatusFilter.all => '全部',
    RepairStatusFilter.submitted => '待受理',
    RepairStatusFilter.processing => '处理中',
    RepairStatusFilter.pendingReview => '待评价',
    RepairStatusFilter.completed => '已完成',
    RepairStatusFilter.cancelled => '已取消',
  };

  bool matches(RepairOrder order) {
    return switch (this) {
      RepairStatusFilter.all => true,
      RepairStatusFilter.submitted => order.status == RepairStatus.submitted,
      RepairStatusFilter.processing =>
        order.status == RepairStatus.accepted ||
            order.status == RepairStatus.assigned ||
            order.status == RepairStatus.processing,
      RepairStatusFilter.pendingReview =>
        order.status == RepairStatus.pendingReview,
      RepairStatusFilter.completed => order.status == RepairStatus.completed,
      RepairStatusFilter.cancelled => order.status == RepairStatus.cancelled,
    };
  }
}

class RepairHouse {
  const RepairHouse({
    required this.houseId,
    required this.houseName,
    required this.roomName,
    required this.leaseStatus,
    required this.housekeeperName,
    required this.housekeeperPhone,
  });

  final String houseId;
  final String houseName;
  final String roomName;
  final String leaseStatus;
  final String housekeeperName;
  final String housekeeperPhone;
}

class RepairTimelineItem {
  const RepairTimelineItem({
    required this.title,
    required this.description,
    required this.time,
    required this.status,
  });

  final String title;
  final String description;
  final DateTime time;
  final RepairStatus status;
}

class RepairOrder {
  const RepairOrder({
    required this.id,
    required this.orderNo,
    required this.houseId,
    required this.houseName,
    required this.roomName,
    required this.repairType,
    required this.description,
    required this.imageUrls,
    required this.contactName,
    required this.contactPhone,
    required this.expectedVisitTime,
    required this.status,
    required this.housekeeperName,
    required this.housekeeperPhone,
    required this.repairmanName,
    required this.createdAt,
    required this.updatedAt,
    required this.timeline,
    this.completedAt,
    this.rating,
    this.reviewContent,
  });

  final String id;
  final String orderNo;
  final String houseId;
  final String houseName;
  final String roomName;
  final RepairType repairType;
  final String description;
  final List<String> imageUrls;
  final String contactName;
  final String contactPhone;
  final DateTime? expectedVisitTime;
  final RepairStatus status;
  final String housekeeperName;
  final String housekeeperPhone;
  final String repairmanName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int? rating;
  final String? reviewContent;
  final List<RepairTimelineItem> timeline;

  String get repairTypeText => repairType.label;
  String get statusText => status.label;
  String get title => '$repairTypeText · $roomName';
  String get summary => description.length > 36
      ? '${description.substring(0, 36)}...'
      : description;

  RepairOrder copyWith({
    RepairStatus? status,
    int? rating,
    String? reviewContent,
    DateTime? updatedAt,
    List<RepairTimelineItem>? timeline,
  }) {
    return RepairOrder(
      id: id,
      orderNo: orderNo,
      houseId: houseId,
      houseName: houseName,
      roomName: roomName,
      repairType: repairType,
      description: description,
      imageUrls: imageUrls,
      contactName: contactName,
      contactPhone: contactPhone,
      expectedVisitTime: expectedVisitTime,
      status: status ?? this.status,
      housekeeperName: housekeeperName,
      housekeeperPhone: housekeeperPhone,
      repairmanName: repairmanName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt,
      rating: rating ?? this.rating,
      reviewContent: reviewContent ?? this.reviewContent,
      timeline: timeline ?? this.timeline,
    );
  }
}

class CreateRepairRequest {
  const CreateRepairRequest({
    required this.houseId,
    required this.houseName,
    required this.roomName,
    required this.repairType,
    required this.description,
    required this.imageUrls,
    required this.contactName,
    required this.contactPhone,
    required this.expectedVisitTime,
  });

  final String houseId;
  final String houseName;
  final String roomName;
  final RepairType repairType;
  final String description;
  final List<String> imageUrls;
  final String contactName;
  final String contactPhone;
  final DateTime? expectedVisitTime;
}

class RepairOverview {
  const RepairOverview({required this.currentHouse, required this.orders});

  final RepairHouse currentHouse;
  final List<RepairOrder> orders;
}
