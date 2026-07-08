class ImmersiveTourAvailability {
  const ImmersiveTourAvailability({
    required this.available,
    this.tourId = '',
    this.coverImageUrl = '',
  });

  final bool available;
  final String tourId;
  final String coverImageUrl;

  factory ImmersiveTourAvailability.fromJson(Map<String, dynamic> json) {
    return ImmersiveTourAvailability(
      available: json['available'] as bool? ?? false,
      tourId: json['tourId'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
    );
  }
}

class ImmersiveTour {
  const ImmersiveTour({
    required this.tourId,
    required this.houseId,
    required this.title,
    this.coverImageUrl = '',
    this.floorPlanUrl = '',
    this.entrySceneId = '',
    this.status = '',
    this.publishedAt = '',
    this.scenes = const [],
  });

  final String tourId;
  final String houseId;
  final String title;
  final String coverImageUrl;
  final String floorPlanUrl;
  final String entrySceneId;
  final String status;
  final String publishedAt;
  final List<ImmersiveScene> scenes;

  factory ImmersiveTour.fromJson(Map<String, dynamic> json) {
    return ImmersiveTour(
      tourId: json['tourId'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      floorPlanUrl: json['floorPlanUrl'] as String? ?? '',
      entrySceneId: json['entrySceneId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      publishedAt: json['publishedAt'] as String? ?? '',
      scenes:
          (json['scenes'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ImmersiveScene.fromJson)
              .toList(growable: false) ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId,
      'houseId': houseId,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'floorPlanUrl': floorPlanUrl,
      'entrySceneId': entrySceneId,
      'status': status,
      'publishedAt': publishedAt,
      'scenes': scenes.map((scene) => scene.toJson()).toList(),
    };
  }

  ImmersiveScene? get entryScene {
    if (scenes.isEmpty) return null;
    for (final scene in scenes) {
      if (scene.sceneId == entrySceneId) return scene;
    }
    return scenes.first;
  }
}

class ImmersiveScene {
  const ImmersiveScene({
    required this.sceneId,
    required this.tourId,
    required this.name,
    this.sceneType = '',
    this.entryImageId = '',
    this.floorPlanXRatio,
    this.floorPlanYRatio,
    this.renderMode = '',
    this.initialYaw,
    this.initialPitch,
    this.initialHfov,
    this.sortOrder = 0,
    this.images = const [],
    this.hotspots = const [],
  });

  final String sceneId;
  final String tourId;
  final String name;
  final String sceneType;
  final String entryImageId;
  final double? floorPlanXRatio;
  final double? floorPlanYRatio;
  final String renderMode;
  final double? initialYaw;
  final double? initialPitch;
  final double? initialHfov;
  final int sortOrder;
  final List<ImmersiveImage> images;
  final List<ImmersiveHotspot> hotspots;

  bool get isPanorama => renderMode.toUpperCase() == 'PANORAMA';

  ImmersiveImage? get entryImage {
    if (images.isEmpty) return null;
    for (final image in images) {
      if (image.entry || image.imageId == entryImageId) return image;
    }
    return images.first;
  }

  factory ImmersiveScene.fromJson(Map<String, dynamic> json) {
    return ImmersiveScene(
      sceneId: (json['sceneId'] ?? json['scene_id']) as String? ?? '',
      tourId: (json['tourId'] ?? json['tour_id']) as String? ?? '',
      name: json['name'] as String? ?? '',
      sceneType: (json['sceneType'] ?? json['scene_type']) as String? ?? '',
      entryImageId:
          (json['entryImageId'] ?? json['entry_image_id']) as String? ?? '',
      floorPlanXRatio: _asDouble(
        json['floorPlanXRatio'] ?? json['floor_plan_x_ratio'],
      ),
      floorPlanYRatio: _asDouble(
        json['floorPlanYRatio'] ?? json['floor_plan_y_ratio'],
      ),
      renderMode: (json['renderMode'] ?? json['render_mode']) as String? ?? '',
      initialYaw: _asDouble(json['initialYaw'] ?? json['initial_yaw']),
      initialPitch: _asDouble(json['initialPitch'] ?? json['initial_pitch']),
      initialHfov: _asDouble(json['initialHfov'] ?? json['initial_hfov']),
      sortOrder:
          (json['sortOrder'] as num?)?.toInt() ??
          (json['sort_order'] as num?)?.toInt() ??
          0,
      images:
          (json['images'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ImmersiveImage.fromJson)
              .toList(growable: false) ??
          const [],
      hotspots:
          (_firstList(json, const [
                'hotspots',
                'hotSpots',
                'imageHotspots',
                'image_hotspots',
                'hotspotList',
                'hotspot_list',
              ]))
              ?.whereType<Map<String, dynamic>>()
              .map(ImmersiveHotspot.fromJson)
              .toList(growable: false) ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sceneId': sceneId,
      'tourId': tourId,
      'name': name,
      'sceneType': sceneType,
      'entryImageId': entryImageId,
      'floorPlanXRatio': floorPlanXRatio,
      'floorPlanYRatio': floorPlanYRatio,
      'renderMode': renderMode,
      'initialYaw': initialYaw,
      'initialPitch': initialPitch,
      'initialHfov': initialHfov,
      'sortOrder': sortOrder,
      'images': images.map((image) => image.toJson()).toList(),
      'hotspots': hotspots.map((hotspot) => hotspot.toJson()).toList(),
    };
  }
}

class ImmersiveImage {
  const ImmersiveImage({
    required this.imageId,
    this.name = '',
    required this.imageUrl,
    this.projectionType = '',
    this.imageWidth,
    this.imageHeight,
    this.width,
    this.height,
    this.sortOrder = 0,
    this.entry = false,
    this.hotspots = const [],
  });

  final String imageId;
  final String name;
  final String imageUrl;
  final String projectionType;
  final int? imageWidth;
  final int? imageHeight;
  final int? width;
  final int? height;
  final int sortOrder;
  final bool entry;
  final List<ImmersiveHotspot> hotspots;

  factory ImmersiveImage.fromJson(Map<String, dynamic> json) {
    return ImmersiveImage(
      imageId: (json['imageId'] ?? json['image_id']) as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String? ?? '',
      projectionType:
          (json['projectionType'] ?? json['projection_type']) as String? ?? '',
      imageWidth:
          (json['imageWidth'] as num?)?.toInt() ??
          (json['image_width'] as num?)?.toInt(),
      imageHeight:
          (json['imageHeight'] as num?)?.toInt() ??
          (json['image_height'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      sortOrder:
          (json['sortOrder'] as num?)?.toInt() ??
          (json['sort_order'] as num?)?.toInt() ??
          0,
      entry: json['entry'] as bool? ?? false,
      hotspots:
          (_firstList(json, const [
                'hotspots',
                'hotSpots',
                'imageHotspots',
                'image_hotspots',
                'hotspotList',
                'hotspot_list',
              ]))
              ?.whereType<Map<String, dynamic>>()
              .map(ImmersiveHotspot.fromJson)
              .toList(growable: false) ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'name': name,
      'imageUrl': imageUrl,
      'projectionType': projectionType,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'width': width,
      'height': height,
      'sortOrder': sortOrder,
      'entry': entry,
      'hotspots': hotspots.map((hotspot) => hotspot.toJson()).toList(),
    };
  }
}

class ImmersiveHotspot {
  const ImmersiveHotspot({
    required this.hotspotId,
    required this.sourceImageId,
    required this.label,
    this.xRatio,
    this.yRatio,
    this.yaw,
    this.pitch,
    this.targetType = '',
    this.targetSceneId = '',
    this.targetImageId = '',
    this.targetSceneName = '',
    this.targetImageUrl = '',
  });

  final String hotspotId;
  final String sourceImageId;
  final String label;
  final double? xRatio;
  final double? yRatio;
  final double? yaw;
  final double? pitch;
  final String targetType;
  final String targetSceneId;
  final String targetImageId;
  final String targetSceneName;
  final String targetImageUrl;

  factory ImmersiveHotspot.fromJson(Map<String, dynamic> json) {
    return ImmersiveHotspot(
      hotspotId:
          (json['hotspotId'] ?? json['hotspot_id'] ?? json['id']) as String? ??
          '',
      sourceImageId:
          (json['sourceImageId'] ?? json['source_image_id']) as String? ?? '',
      label: json['label'] as String? ?? '',
      xRatio: _asDouble(json['xRatio'] ?? json['x_ratio']),
      yRatio: _asDouble(json['yRatio'] ?? json['y_ratio']),
      yaw: _asDouble(json['yaw']),
      pitch: _asDouble(json['pitch']),
      targetType: (json['targetType'] ?? json['target_type']) as String? ?? '',
      targetSceneId:
          (json['targetSceneId'] ?? json['target_scene_id']) as String? ?? '',
      targetImageId:
          (json['targetImageId'] ?? json['target_image_id']) as String? ?? '',
      targetSceneName:
          (json['targetSceneName'] ?? json['target_scene_name']) as String? ??
          '',
      targetImageUrl:
          (json['targetImageUrl'] ?? json['target_image_url']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotspotId': hotspotId,
      'sourceImageId': sourceImageId,
      'label': label,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'yaw': yaw,
      'pitch': pitch,
      'targetType': targetType,
      'targetSceneId': targetSceneId,
      'targetImageId': targetImageId,
      'targetSceneName': targetSceneName,
      'targetImageUrl': targetImageUrl,
    };
  }
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<dynamic>? _firstList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List<dynamic>) return value;
  }
  return null;
}
