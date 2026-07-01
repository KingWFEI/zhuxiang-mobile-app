import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/tenant_lock_unlock_data.dart';

/// 租客门锁数据仓库接口。
abstract interface class TenantLockRepositoryContract {
  Future<TenantLockUnlockData> getUnlockData(String leaseId);
  Future<TenantPasscode> getPasscode(String leaseId);
  Future<TenantPasscode> retryPasscode(String leaseId);
}

class TenantLockRepository implements TenantLockRepositoryContract {
  const TenantLockRepository(this.apiClient);

  final ApiClient apiClient;

  /// 按租约 ID 获取当前登录租客的 eKey 开锁数据。
  @override
  Future<TenantLockUnlockData> getUnlockData(String leaseId) async {
    final encodedLeaseId = Uri.encodeComponent(leaseId);
    final result = await apiClient.get(
      '/leases/$encodedLeaseId/lock/unlock-data',
    );
    return result.unwrapData(TenantLockUnlockData.fromJson);
  }

  /// 获取当前租约期限线下开门密码。
  @override
  Future<TenantPasscode> getPasscode(String leaseId) async {
    final encodedLeaseId = Uri.encodeComponent(leaseId);
    final result = await apiClient.get(
      '/leases/$encodedLeaseId/lock/passcode',
    );
    return result.unwrapData(TenantPasscode.fromJson);
  }

  /// 重新生成当前租约期限开门密码。
  @override
  Future<TenantPasscode> retryPasscode(String leaseId) async {
    final encodedLeaseId = Uri.encodeComponent(leaseId);
    final result = await apiClient.post(
      '/leases/$encodedLeaseId/lock/passcode/retry',
    );
    return result.unwrapData(TenantPasscode.fromJson);
  }
}
