import '../../domain/entities/unlock_record.dart';

class UnlockRecordModel {
  const UnlockRecordModel(this.json);

  final Map<String, dynamic> json;

  UnlockRecord toEntity() {
    return UnlockRecord(
      id: _string(['id', 'recordId']),
      houseId: _string(['houseId']),
      houseName: _string(['houseName', 'houseTitle'], fallback: '3栋2单元1201'),
      lockId: _string(['lockId']),
      lockName: _string(['lockName'], fallback: '客厅智能门锁'),
      unlockMethod: _method(_string(['unlockMethod', 'method'])),
      unlockResult: _result(_string(['unlockResult', 'result', 'status'])),
      unlockTime: _date(['unlockTime', 'createdAt', 'time']),
      operatorName: _string(['operatorName'], fallback: '本人'),
      operatorType: _operatorType(_string(['operatorType', 'source'])),
      failureReason: _string(['failureReason', 'failReason']),
      deviceName: _string(['deviceName']),
      remark: _string(['remark']),
    );
  }

  String _string(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  DateTime _date(List<String> keys) {
    for (final key in keys) {
      final value = DateTime.tryParse(json[key]?.toString() ?? '');
      if (value != null) return value;
    }
    return DateTime.now();
  }

  UnlockMethod _method(String value) {
    return switch (value.toLowerCase()) {
      'remote' || 'remote_unlock' => UnlockMethod.remote,
      'password' || 'code' || 'temporary_password' => UnlockMethod.password,
      'admin' || 'administrator' => UnlockMethod.admin,
      'system' => UnlockMethod.system,
      _ => UnlockMethod.bluetooth,
    };
  }

  UnlockResult _result(String value) {
    return switch (value.toLowerCase()) {
      'failed' || 'failure' || 'error' => UnlockResult.failed,
      _ => UnlockResult.success,
    };
  }

  UnlockOperatorType _operatorType(String value) {
    return switch (value.toLowerCase()) {
      'housekeeper' || 'keeper' => UnlockOperatorType.housekeeper,
      'admin' || 'administrator' => UnlockOperatorType.admin,
      'system' => UnlockOperatorType.system,
      _ => UnlockOperatorType.tenant,
    };
  }
}

class CurrentLockStatusModel {
  const CurrentLockStatusModel(this.json);

  final Map<String, dynamic> json;

  CurrentLockStatus toEntity() {
    final methods = json['supportedMethods'];
    return CurrentLockStatus(
      houseName: json['houseName']?.toString() ?? '3栋2单元1201',
      lockName: json['lockName']?.toString() ?? '客厅智能门锁',
      permissionStatus: _permission(json['permissionStatus']?.toString() ?? ''),
      lastUnlockTime:
          DateTime.tryParse(json['lastUnlockTime']?.toString() ?? '') ??
          DateTime.now(),
      supportedMethods: methods is List
          ? methods.map((item) => _method(item.toString())).toList()
          : const [
              UnlockMethod.bluetooth,
              UnlockMethod.remote,
              UnlockMethod.password,
            ],
    );
  }

  LockPermissionStatus _permission(String value) {
    return switch (value.toLowerCase()) {
      'pending' || 'inactive' => LockPermissionStatus.pending,
      'expired' || 'revoked' => LockPermissionStatus.expired,
      _ => LockPermissionStatus.active,
    };
  }

  UnlockMethod _method(String value) {
    return switch (value.toLowerCase()) {
      'remote' => UnlockMethod.remote,
      'password' || 'temporary_password' => UnlockMethod.password,
      'admin' => UnlockMethod.admin,
      'system' => UnlockMethod.system,
      _ => UnlockMethod.bluetooth,
    };
  }
}
