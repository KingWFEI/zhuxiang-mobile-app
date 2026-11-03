import '../../domain/entities/unlock_record.dart';

class UnlockRecordModel {
  const UnlockRecordModel(this.json);

  final Map<String, dynamic> json;

  UnlockRecord toEntity() {
    return UnlockRecord(
      id: _string(['id', 'recordId']),
      houseId: _string(['houseId']),
      houseName: _string(['houseName', 'houseTitle']),
      lockId: _string(['lockId']),
      lockName: _string(['lockName']),
      unlockMethod: _method(_string(['unlockMethod', 'method'])),
      unlockResult: _result(_string(['unlockResult', 'result', 'status'])),
      unlockTime: _requiredDate(['unlockTime', 'createdAt', 'time']),
      operatorName: _string(['operatorName']),
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
    throw FormatException('Missing unlock record date: ${keys.join(', ')}');
  }

  DateTime _requiredDate(List<String> keys) => _date(keys);

  UnlockMethod _method(String value) {
    return switch (value.toLowerCase()) {
      'bluetooth' || 'ble' => UnlockMethod.bluetooth,
      'remote' || 'remote_unlock' => UnlockMethod.remote,
      'password' || 'code' || 'temporary_password' => UnlockMethod.password,
      'admin' || 'administrator' => UnlockMethod.admin,
      'system' => UnlockMethod.system,
      _ => UnlockMethod.unknown,
    };
  }

  UnlockResult _result(String value) {
    return switch (value.toLowerCase()) {
      'success' || 'succeeded' || 'ok' || '1' => UnlockResult.success,
      'failed' || 'failure' || 'error' => UnlockResult.failed,
      _ => UnlockResult.unknown,
    };
  }

  UnlockOperatorType _operatorType(String value) {
    return switch (value.toLowerCase()) {
      'tenant' || 'user' || 'self' => UnlockOperatorType.tenant,
      'housekeeper' || 'keeper' => UnlockOperatorType.housekeeper,
      'admin' || 'administrator' => UnlockOperatorType.admin,
      'system' => UnlockOperatorType.system,
      _ => UnlockOperatorType.unknown,
    };
  }
}

class CurrentLockStatusModel {
  const CurrentLockStatusModel(this.json);

  final Map<String, dynamic> json;

  CurrentLockStatus toEntity() {
    final methods = json['supportedMethods'];
    return CurrentLockStatus(
      houseName: json['houseName']?.toString() ?? '',
      lockName: json['lockName']?.toString() ?? '',
      permissionStatus: _permission(json['permissionStatus']?.toString() ?? ''),
      lastUnlockTime: DateTime.tryParse(
        json['lastUnlockTime']?.toString() ?? '',
      ),
      supportedMethods: methods is List
          ? methods.map((item) => _method(item.toString())).toList()
          : const [],
    );
  }

  LockPermissionStatus _permission(String value) {
    return switch (value.toLowerCase()) {
      'pending' || 'inactive' => LockPermissionStatus.pending,
      'expired' || 'revoked' => LockPermissionStatus.expired,
      'active' || 'valid' => LockPermissionStatus.active,
      _ => LockPermissionStatus.unknown,
    };
  }

  UnlockMethod _method(String value) {
    return switch (value.toLowerCase()) {
      'bluetooth' || 'ble' => UnlockMethod.bluetooth,
      'remote' => UnlockMethod.remote,
      'password' || 'temporary_password' => UnlockMethod.password,
      'admin' => UnlockMethod.admin,
      'system' => UnlockMethod.system,
      _ => UnlockMethod.unknown,
    };
  }
}
