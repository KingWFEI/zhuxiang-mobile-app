import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhuxiang_app/app/router/app_mode_controller.dart';
import 'package:zhuxiang_app/app/router/role_navigation_config.dart';
import 'package:zhuxiang_app/app/router/route_names.dart';
import 'package:zhuxiang_app/app/router/route_paths.dart';
import 'package:zhuxiang_app/core/storage/local_storage.dart';
import 'package:zhuxiang_app/features/auth/domain/entities/auth_user.dart';
import 'package:zhuxiang_app/features/auth/domain/entities/user_role.dart';

void main() {
  test(
    'remembers the last mode separately for each landlord account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = LocalStorage(preferences);
      final controller = AppModeController(storage)..syncUser(_landlord);

      expect(controller.state, AppMode.tenant);
      await controller.setMode(AppMode.landlord);
      expect(controller.state, AppMode.landlord);

      final restored = AppModeController(storage)..syncUser(_landlord);
      expect(restored.state, AppMode.landlord);

      restored.syncUser(_otherLandlord);
      expect(restored.state, AppMode.tenant);

      restored.syncUser(_tenant);
      await restored.setMode(AppMode.landlord);
      expect(restored.state, AppMode.tenant);
    },
  );

  test('landlord can access both tenant and landlord routes', () {
    expect(
      RoleNavigationConfig.canAccess(UserRole.landlord, RouteNames.home),
      isTrue,
    );
    expect(
      RoleNavigationConfig.canAccess(
        UserRole.landlord,
        RouteNames.landlordWorkbench,
      ),
      isTrue,
    );
    expect(
      RoleNavigationConfig.canAccess(
        UserRole.tenant,
        RouteNames.landlordWorkbench,
      ),
      isFalse,
    );
    expect(
      RoleNavigationConfig.entryLocationForSession(
        UserRole.landlord,
        AppMode.tenant,
      ),
      RoutePaths.tenant,
    );
    expect(
      RoleNavigationConfig.entryLocationForSession(
        UserRole.landlord,
        AppMode.landlord,
      ),
      RoutePaths.landlordWorkbench,
    );
  });
}

const _landlord = AuthUser(
  id: 'landlord-1',
  phone: '13800138000',
  nickname: '房东一',
  avatarUrl: '',
  isVerified: true,
  role: UserRole.landlord,
);

const _otherLandlord = AuthUser(
  id: 'landlord-2',
  phone: '13800138001',
  nickname: '房东二',
  avatarUrl: '',
  isVerified: true,
  role: UserRole.landlord,
);

const _tenant = AuthUser(
  id: 'tenant-1',
  phone: '13800138002',
  nickname: '租客',
  avatarUrl: '',
  isVerified: true,
);
