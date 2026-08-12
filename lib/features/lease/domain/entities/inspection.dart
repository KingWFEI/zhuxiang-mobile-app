enum MoveOutInspectionStatus { draft, submitted, locked, unknown }

MoveOutInspectionStatus parseMoveOutInspectionStatus(Object? value) {
  return switch (value?.toString().toUpperCase()) {
    'DRAFT' => MoveOutInspectionStatus.draft,
    'SUBMITTED' => MoveOutInspectionStatus.submitted,
    'LOCKED' => MoveOutInspectionStatus.locked,
    _ => MoveOutInspectionStatus.unknown,
  };
}

class MoveOutInspection {
  const MoveOutInspection({
    required this.contractId,
    required this.status,
    required this.rooms,
    this.completedAt,
    this.completionComment,
  });

  final String contractId;
  final MoveOutInspectionStatus status;
  final List<InspectionRoom> rooms;
  final DateTime? completedAt;
  final String? completionComment;

  bool get canEdit => status != MoveOutInspectionStatus.locked;

  factory MoveOutInspection.fromJson(Map<String, dynamic> json) {
    final rawRooms = json['rooms'] ?? json['roomItems'] ?? json['items'];
    final rooms = _rooms(rawRooms);
    final rawPhotos =
        json['existingMoveOutPhotos'] ??
        json['moveOutPhotos'] ??
        json['photos'];
    return MoveOutInspection(
      contractId: _string(json, ['contractId', 'contract_id']),
      status: parseMoveOutInspectionStatus(json['status']),
      completedAt: _date(json['completedAt'] ?? json['completed_at']),
      completionComment: _nullableString(
        json['completionComment'] ?? json['completion_comment'],
      ),
      rooms: _mergePhotos(rooms, rawPhotos),
    );
  }
}

class InspectionRoom {
  const InspectionRoom({
    required this.roomCode,
    required this.roomName,
    required this.items,
  });

  final String roomCode;
  final String roomName;
  final List<InspectionItem> items;

  factory InspectionRoom.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['inspectionItems'];
    return InspectionRoom(
      roomCode: _string(json, ['roomCode', 'room_code', 'code']),
      roomName: _string(json, ['roomName', 'room_name', 'name']),
      items: _items(rawItems),
    );
  }
}

class InspectionItem {
  const InspectionItem({
    required this.itemCode,
    required this.itemName,
    required this.enabled,
    required this.required,
    required this.minPhotoCount,
    required this.photos,
    this.instruction,
    this.remark,
  });

  final String itemCode;
  final String itemName;
  final bool enabled;
  final bool required;
  final int minPhotoCount;
  final List<InspectionPhoto> photos;
  final String? instruction;
  final String? remark;

  InspectionItem copyWith({List<InspectionPhoto>? photos, String? remark}) {
    return InspectionItem(
      itemCode: itemCode,
      itemName: itemName,
      enabled: enabled,
      required: required,
      minPhotoCount: minPhotoCount,
      photos: photos ?? this.photos,
      instruction: instruction,
      remark: remark ?? this.remark,
    );
  }

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] ?? json['photoList'] ?? json['photoUrls'];
    return InspectionItem(
      itemCode: _string(json, ['itemCode', 'item_code', 'code']),
      itemName: _string(json, ['itemName', 'item_name', 'name']),
      enabled: json['enabled'] as bool? ?? true,
      required: json['required'] as bool? ?? false,
      minPhotoCount: _integer(
        json['minPhotoCount'] ?? json['min_photo_count'],
        fallback: 1,
      ),
      instruction: _nullableString(json['instruction'] ?? json['description']),
      remark: _nullableString(json['remark']),
      photos: _photos(rawPhotos),
    );
  }
}

class InspectionPhoto {
  const InspectionPhoto({required this.fileId, required this.url, this.name});

  final String fileId;
  final String url;
  final String? name;

  Map<String, dynamic> toJson() => {
    if (fileId.isNotEmpty) 'fileId': fileId,
    'url': url,
  };

  factory InspectionPhoto.fromJson(Object? value) {
    if (value is String) {
      return InspectionPhoto(fileId: '', url: value);
    }
    final json = value is Map<String, dynamic>
        ? value
        : const <String, dynamic>{};
    return InspectionPhoto(
      fileId: _string(json, ['fileId', 'file_id', 'id']),
      url: _string(json, ['url', 'fileUrl', 'file_url']),
      name: _nullableString(json['name'] ?? json['fileName']),
    );
  }
}

List<InspectionRoom> _rooms(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(InspectionRoom.fromJson)
          .where((room) => room.items.isNotEmpty)
          .toList()
    : const [];

List<InspectionItem> _items(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(InspectionItem.fromJson)
          .where((item) => item.enabled)
          .toList()
    : const [];

List<InspectionPhoto> _photos(Object? value) => value is List
    ? value
          .map(InspectionPhoto.fromJson)
          .where((photo) => photo.url.isNotEmpty)
          .toList()
    : const [];

List<InspectionRoom> _mergePhotos(
  List<InspectionRoom> rooms,
  Object? rawPhotos,
) {
  final photos = rawPhotos is List
      ? rawPhotos.whereType<Map<String, dynamic>>().map((json) {
          return (
            roomCode: _string(json, ['roomCode', 'room_code']),
            itemCode: _string(json, ['itemCode', 'item_code']),
            photo: InspectionPhoto.fromJson(json),
          );
        }).toList()
      : const <({String roomCode, String itemCode, InspectionPhoto photo})>[];

  if (photos.isEmpty) return rooms;
  return rooms.map((room) {
    return InspectionRoom(
      roomCode: room.roomCode,
      roomName: room.roomName,
      items: room.items.map((item) {
        final itemPhotos = photos
            .where(
              (entry) =>
                  entry.roomCode == room.roomCode &&
                  entry.itemCode == item.itemCode,
            )
            .map((entry) => entry.photo)
            .toList();
        return itemPhotos.isEmpty ? item : item.copyWith(photos: itemPhotos);
      }).toList(),
    );
  }).toList();
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(Object? value, {required int fallback}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _date(Object? value) {
  final text = _nullableString(value);
  return text == null ? null : DateTime.tryParse(text);
}
