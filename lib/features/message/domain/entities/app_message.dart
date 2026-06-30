enum MessageCategory {
  appointment('appointment', '预约'),
  lease('lease', '租约'),
  bill('bill', '账单'),
  repair('repair', '报修'),
  lock('lock', '门锁'),
  system('system', '系统');

  const MessageCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MessageCategory? fromApiValue(String? value) {
    for (final category in values) {
      if (category.apiValue == value) return category;
    }
    return null;
  }
}

class AppMessage {
  const AppMessage({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isRead,
    this.createdAt,
    this.iconKey,
    this.actionType,
    this.actionTarget,
  });

  factory AppMessage.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt']?.toString();
    return AppMessage(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: MessageCategory.fromApiValue(json['category']?.toString()),
      isRead: json['isRead'] == true,
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse(createdAtValue)?.toLocal(),
      iconKey: _nullableString(json['iconKey']),
      actionType: _nullableString(json['actionType']),
      actionTarget: _nullableString(json['actionTarget']),
    );
  }

  final String id;
  final String title;
  final String content;
  final MessageCategory? category;
  final bool isRead;
  final DateTime? createdAt;
  final String? iconKey;
  final String? actionType;
  final String? actionTarget;

  AppMessage copyWith({bool? isRead}) {
    return AppMessage(
      id: id,
      title: title,
      content: content,
      category: category,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      iconKey: iconKey,
      actionType: actionType,
      actionTarget: actionTarget,
    );
  }
}

class MessagePageData {
  const MessagePageData({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory MessagePageData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MessagePageData(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      AppMessage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      page: _intValue(json['page'], fallback: 1),
      pageSize: _intValue(json['pageSize'], fallback: 20),
      total: _intValue(json['total']),
      hasMore: json['hasMore'] == true,
    );
  }

  final List<AppMessage> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
}

class MessageUnreadCounts {
  const MessageUnreadCounts({
    this.appointment = 0,
    this.bill = 0,
    this.lease = 0,
    this.lock = 0,
    this.repair = 0,
    this.system = 0,
    this.total = 0,
  });

  factory MessageUnreadCounts.fromJson(Map<String, dynamic> json) {
    return MessageUnreadCounts(
      appointment: _intValue(json['appointment']),
      bill: _intValue(json['bill']),
      lease: _intValue(json['lease']),
      lock: _intValue(json['lock']),
      repair: _intValue(json['repair']),
      system: _intValue(json['system']),
      total: _intValue(json['total']),
    );
  }

  final int appointment;
  final int bill;
  final int lease;
  final int lock;
  final int repair;
  final int system;
  final int total;

  int forCategory(MessageCategory? category) {
    return switch (category) {
      null => total,
      MessageCategory.appointment => appointment,
      MessageCategory.bill => bill,
      MessageCategory.lease => lease,
      MessageCategory.lock => lock,
      MessageCategory.repair => repair,
      MessageCategory.system => system,
    };
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
