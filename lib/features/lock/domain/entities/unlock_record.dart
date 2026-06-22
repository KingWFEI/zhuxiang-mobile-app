enum UnlockMethod {
  bluetooth('蓝牙开锁'),
  remote('远程开锁'),
  password('密码开锁'),
  admin('管理员开锁'),
  system('系统开锁');

  const UnlockMethod(this.label);
  final String label;
}

enum UnlockResult {
  success('成功'),
  failed('失败');

  const UnlockResult(this.label);
  final String label;
}

enum UnlockOperatorType {
  tenant('本人操作'),
  housekeeper('管家操作'),
  admin('管理员操作'),
  system('系统记录');

  const UnlockOperatorType(this.label);
  final String label;
}

enum LockPermissionStatus {
  active('已授权'),
  pending('待授权'),
  expired('已过期');

  const LockPermissionStatus(this.label);
  final String label;
}

enum UnlockRecordFilter {
  all('全部'),
  success('成功'),
  failed('失败'),
  bluetooth('蓝牙'),
  remote('远程'),
  password('密码');

  const UnlockRecordFilter(this.label);
  final String label;
}

class UnlockRecord {
  const UnlockRecord({
    required this.id,
    required this.houseId,
    required this.houseName,
    required this.lockId,
    required this.lockName,
    required this.unlockMethod,
    required this.unlockResult,
    required this.unlockTime,
    required this.operatorName,
    required this.operatorType,
    required this.failureReason,
    required this.deviceName,
    required this.remark,
  });

  final String id;
  final String houseId;
  final String houseName;
  final String lockId;
  final String lockName;
  final UnlockMethod unlockMethod;
  final UnlockResult unlockResult;
  final DateTime unlockTime;
  final String operatorName;
  final UnlockOperatorType operatorType;
  final String failureReason;
  final String deviceName;
  final String remark;

  bool get isSuccess => unlockResult == UnlockResult.success;
}

class CurrentLockStatus {
  const CurrentLockStatus({
    required this.houseName,
    required this.lockName,
    required this.permissionStatus,
    required this.lastUnlockTime,
    required this.supportedMethods,
  });

  final String houseName;
  final String lockName;
  final LockPermissionStatus permissionStatus;
  final DateTime lastUnlockTime;
  final List<UnlockMethod> supportedMethods;
}

class UnlockRecordOverview {
  const UnlockRecordOverview({required this.lockStatus, required this.records});

  final CurrentLockStatus lockStatus;
  final List<UnlockRecord> records;
}
