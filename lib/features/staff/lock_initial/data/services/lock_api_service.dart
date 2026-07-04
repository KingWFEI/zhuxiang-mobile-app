import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_result.dart';

class LockLocalInitRequest {
  const LockLocalInitRequest({
    required this.lockName,
    required this.lockMac,
    required this.lockData,
    required this.rssi,
    required this.battery,
  });

  final String lockName;
  final String lockMac;
  final String lockData;
  final int rssi;
  final int battery;

  Map<String, dynamic> toJson() => {
    'lockName': lockName,
    'lockMac': lockMac,
    'lockData': lockData,
    'rssi': rssi,
    'battery': battery,
  };
}

class LockLocalInitResponse {
  const LockLocalInitResponse({
    required this.smartLockId,
    required this.lockName,
    required this.lockMac,
    required this.status,
  });

  final String smartLockId;
  final String lockName;
  final String lockMac;
  final String status;

  factory LockLocalInitResponse.fromJson(Map<String, dynamic> json) {
    return LockLocalInitResponse(
      smartLockId: json['smartLockId'] as String? ?? '',
      lockName: json['lockName'] as String? ?? '',
      lockMac: json['lockMac'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class LockBindRoomRequest {
  const LockBindRoomRequest({required this.houseId, this.roomId});

  final String houseId;
  final String? roomId;

  Map<String, dynamic> toJson() => {
    'houseId': houseId,
    if (roomId != null) 'roomId': roomId,
  };
}

class LockBindRoomResponse {
  const LockBindRoomResponse({
    required this.id,
    required this.houseId,
    this.roomId,
    required this.lockName,
    required this.lockMac,
    required this.status,
    this.lockId,
    this.keyId,
    this.platformErrorCode,
    this.platformErrorMessage,
  });

  final String id;
  final String houseId;
  final String? roomId;
  final int? lockId;
  final int? keyId;
  final String lockName;
  final String lockMac;
  final String status;
  final String? platformErrorCode;
  final String? platformErrorMessage;

  factory LockBindRoomResponse.fromJson(Map<String, dynamic> json) {
    return LockBindRoomResponse(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      roomId: json['roomId'] as String?,
      lockId: json['lockId'] as int?,
      keyId: json['keyId'] as int?,
      lockName: json['lockName'] as String? ?? '',
      lockMac: json['lockMac'] as String? ?? '',
      status: json['status'] as String? ?? '',
      platformErrorCode: json['platformErrorCode'] as String?,
      platformErrorMessage: json['platformErrorMessage'] as String?,
    );
  }
}

class LockSyncPlatformResponse {
  const LockSyncPlatformResponse({
    required this.id,
    required this.houseId,
    this.roomId,
    required this.lockId,
    required this.keyId,
    required this.lockName,
    required this.lockMac,
    required this.status,
    this.platformErrorCode,
    this.platformErrorMessage,
  });

  final String id;
  final String houseId;
  final String? roomId;
  final int lockId;
  final int keyId;
  final String lockName;
  final String lockMac;
  final String status;
  final String? platformErrorCode;
  final String? platformErrorMessage;

  factory LockSyncPlatformResponse.fromJson(Map<String, dynamic> json) {
    return LockSyncPlatformResponse(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      roomId: json['roomId'] as String?,
      lockId: json['lockId'] as int? ?? 0,
      keyId: json['keyId'] as int? ?? 0,
      lockName: json['lockName'] as String? ?? '',
      lockMac: json['lockMac'] as String? ?? '',
      status: json['status'] as String? ?? '',
      platformErrorCode: json['platformErrorCode'] as String?,
      platformErrorMessage: json['platformErrorMessage'] as String?,
    );
  }
}

class LockApiService {
  const LockApiService(this._apiClient);

  final ApiClient _apiClient;

  /// 步骤1：保存门锁本地初始化数据
  Future<LockLocalInitResponse> saveLocalInit(
    LockLocalInitRequest request,
  ) async {
    final result = await _apiClient.post(
      '/admin/locks/local-initialized',
      data: request.toJson(),
    );
    return result.unwrapData(LockLocalInitResponse.fromJson);
  }

  /// 步骤2：绑定门锁到房源/房间
  Future<LockBindRoomResponse> bindRoom(
    String smartLockId,
    LockBindRoomRequest request,
  ) async {
    final result = await _apiClient.post(
      '/admin/locks/$smartLockId/bind-room',
      data: request.toJson(),
    );
    return result.unwrapData(LockBindRoomResponse.fromJson);
  }

  /// 步骤3：同步门锁到开放平台，获取 lockId / keyId
  Future<LockSyncPlatformResponse> syncPlatform(String smartLockId) async {
    final result = await _apiClient.post(
      '/admin/locks/$smartLockId/sync-platform',
    );
    return result.unwrapData(LockSyncPlatformResponse.fromJson);
  }

  /// 回滚：删除门锁与房源/房间的绑定关系（syncPlatform 失败时调用）
  Future<LockBindRoomResponse> deleteBindRoom(String smartLockId) async {
    final result = await _apiClient.delete(
      '/admin/locks/$smartLockId/bind-room',
    );
    return result.unwrapData(LockBindRoomResponse.fromJson);
  }

  /// 根据 lockMac 查询后端是否已有该门锁记录
  Future<LockByMacResponse?> getByMac(String lockMac) async {
    final result = await _apiClient.get(
      '/admin/locks/by-mac',
      queryParameters: {'lockMac': lockMac},
    );
    return result.when(
      success: (response) {
        final body = response.data as Map<String, dynamic>?;
        final code = body?['code'] as int? ?? 0;
        if (code == 404 || body?['data'] == null) return null;
        if (code == 200 && body!['data'] != null) {
          return LockByMacResponse.fromJson(
            body['data'] as Map<String, dynamic>,
          );
        }
        return null;
      },
      failure: (_, _) => null,
    );
  }

  /// 查询门锁管理详情
  Future<LockDetailResponse> getDetail(String smartLockId) async {
    final result = await _apiClient.get('/admin/locks/$smartLockId/detail');
    return result.unwrapData(LockDetailResponse.fromJson);
  }

  /// 上传蓝牙状态
  Future<void> bleStatus(String smartLockId, int battery, int rssi) async {
    await _apiClient.post(
      '/admin/locks/$smartLockId/ble-status',
      data: {'battery': battery, 'rssi': rssi},
    );
  }

  /// 标记恢复出厂
  Future<void> markReset(String smartLockId) async {
    await _apiClient.post('/admin/locks/$smartLockId/mark-reset');
  }

  /// 获取蓝牙开锁数据
  Future<UnlockDataResponse> getUnlockData(String smartLockId) async {
    final result = await _apiClient.get(
      '/admin/locks/$smartLockId/unlock-data',
    );
    return result.unwrapData(UnlockDataResponse.fromJson);
  }
}

class UnlockDataResponse {
  const UnlockDataResponse({
    required this.smartLockId,
    required this.lockName,
    required this.lockMac,
    required this.lockData,
    this.roomName,
    this.status,
  });

  final String smartLockId;
  final String lockName;
  final String lockMac;
  final String lockData;
  final String? roomName;
  final String? status;

  factory UnlockDataResponse.fromJson(Map<String, dynamic> json) {
    return UnlockDataResponse(
      smartLockId: json['smartLockId']?.toString() ?? '',
      lockName: json['lockName'] as String? ?? '',
      lockMac: json['lockMac'] as String? ?? '',
      lockData: json['lockData'] as String? ?? '',
      roomName: json['roomName'] as String?,
      status: json['status'] as String?,
    );
  }
}

class LockDetailResponse {
  const LockDetailResponse({
    required this.smartLockId,
    required this.lockName,
    required this.lockMac,
    required this.status,
    this.houseId,
    this.roomId,
    this.houseName,
    this.roomName,
    this.battery,
    this.rssi,
    this.batterySource,
    this.lastBleSyncTime,
    this.lockId,
    this.keyId,
    this.lastPlatformSyncTime,
    this.platformErrorMessage,
    this.createdAt,
  });

  final String smartLockId;
  final String lockName;
  final String lockMac;
  final String status;
  final String? houseId;
  final String? roomId;
  final String? houseName;
  final String? roomName;
  final int? battery;
  final int? rssi;
  final String? batterySource;
  final String? lastBleSyncTime;
  final int? lockId;
  final int? keyId;
  final String? lastPlatformSyncTime;
  final String? platformErrorMessage;
  final String? createdAt;

  factory LockDetailResponse.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return LockDetailResponse(
      smartLockId: json['smartLockId']?.toString() ?? '',
      lockName: json['lockName'] as String? ?? '',
      lockMac: json['lockMac'] as String? ?? '',
      status: json['status'] as String? ?? '',
      houseId: json['houseId']?.toString(),
      roomId: json['roomId']?.toString(),
      houseName: json['houseName'] as String?,
      roomName: json['roomName'] as String?,
      battery: parseInt(json['battery']),
      rssi: parseInt(json['rssi']),
      batterySource: json['batterySource'] as String?,
      lastBleSyncTime: json['lastBleSyncTime'] as String?,
      lockId: parseInt(json['lockId']),
      keyId: parseInt(json['keyId']),
      lastPlatformSyncTime: json['lastPlatformSyncTime'] as String?,
      platformErrorMessage: json['platformErrorMessage'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class LockByMacResponse {
  const LockByMacResponse({
    required this.smartLockId,
    required this.lockName,
    required this.lockMac,
    required this.status,
    this.houseId,
    this.roomId,
    this.houseName,
    this.roomName,
  });

  final String smartLockId;
  final String lockName;
  final String lockMac;
  final String status;
  final String? houseId;
  final String? roomId;
  final String? houseName;
  final String? roomName;

  factory LockByMacResponse.fromJson(Map<String, dynamic> json) {
    return LockByMacResponse(
      smartLockId: json['smartLockId']?.toString() ?? '',
      lockName: json['lockName'] as String? ?? '',
      lockMac: json['lockMac'] as String? ?? '',
      status: json['status'] as String? ?? '',
      houseId: json['houseId']?.toString(),
      roomId: json['roomId']?.toString(),
      houseName: json['houseName'] as String?,
      roomName: json['roomName'] as String?,
    );
  }
}
