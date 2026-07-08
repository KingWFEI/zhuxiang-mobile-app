class CsSession {
  const CsSession({
    required this.id,
    required this.title,
    required this.status,
    required this.messageCount,
    required this.lastMessagePreview,
    this.closedReason,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CsSession.fromJson(Map<String, dynamic> json) {
    return CsSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      messageCount: _intValue(json['messageCount']),
      lastMessagePreview: json['lastMessagePreview']?.toString(),
      closedReason: json['closedReason']?.toString(),
      lastMessageAt: _parseDateTime(json['lastMessageAt']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  final String id;
  final String? title;
  final String status;
  final int messageCount;
  final String? lastMessagePreview;
  final String? closedReason;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'ACTIVE';
  bool get isClosed => status == 'CLOSED';
}

class CsMessage {
  const CsMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.metadataJson,
    required this.status,
    required this.createdAt,
  });

  factory CsMessage.fromJson(Map<String, dynamic> json) {
    return CsMessage(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      content: json['content']?.toString() ?? '',
      metadataJson: json['metadataJson']?.toString(),
      status: json['status']?.toString() ?? 'SENT',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String sessionId;
  final String role;
  final String content;
  final String? metadataJson;
  final String status;
  final DateTime createdAt;

  bool get isUser => role == 'USER';
  bool get isAssistant => role == 'ASSISTANT';
}

class EnterSessionResponse {
  const EnterSessionResponse({
    required this.sessionId,
    required this.title,
    required this.status,
    required this.isNew,
    this.closedReason,
    required this.hint,
  });

  factory EnterSessionResponse.fromJson(Map<String, dynamic> json) {
    return EnterSessionResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      title: json['title']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      isNew: json['isNew'] == true,
      closedReason: json['closedReason']?.toString(),
      hint: json['hint']?.toString() ?? '',
    );
  }

  final String sessionId;
  final String? title;
  final String status;
  final bool isNew;
  final String? closedReason;
  final String hint;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return DateTime.tryParse(text)?.toLocal();
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
