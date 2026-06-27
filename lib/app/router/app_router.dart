import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_placeholder_page.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/house/presentation/pages/find_house_page.dart';
import '../../features/house/presentation/pages/house_detail_page.dart';
import '../../features/house/presentation/pages/house_filter_page.dart';
import '../../features/house/presentation/pages/house_search_page.dart';
import '../../features/house/presentation/pages/house_search_result_page.dart';
import '../../features/lease/presentation/pages/lease_detail_page.dart';
import '../../features/lease/presentation/pages/my_leases_page.dart';
import '../../features/lock/presentation/pages/unlock_records_page.dart';
import '../../features/lock/presentation/pages/tenant_lock_unlock_page.dart';
import '../../features/message/presentation/pages/message_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/repair/domain/entities/repair_order.dart';
import '../../features/repair/presentation/pages/create_repair_page.dart';
import '../../features/repair/presentation/pages/repair_detail_page.dart';
import '../../features/repair/presentation/pages/repair_records_page.dart';
import '../../features/repair/presentation/pages/repair_service_page.dart';
import '../../features/rental_flow/presentation/pages/lease_contract_page.dart';
import '../../features/rental_flow/presentation/pages/move_in_complete_page.dart';
import '../../features/rental_flow/presentation/pages/my_rent_orders_page.dart';
import '../../features/rental_flow/presentation/pages/online_sign_page.dart';
import '../../features/rental_flow/presentation/pages/payment_page.dart';
import '../../features/rental_flow/presentation/pages/real_name_verify_page.dart';
import '../../features/rental_flow/presentation/pages/rental_application_page.dart';
import '../../features/rental_flow/presentation/pages/viewing_appointment_page.dart';
import '../../features/rental_flow/presentation/pages/viewing_detail_page.dart';
import '../../features/staff/lock_initial/presentation/lock_initial.dart';
import '../../features/staff/lock_initial/presentation/lock_manage_page.dart';
import '../../features/staff/workbench/presentation/workbench_page.dart';
import '../launch/app_loading_page.dart';
import 'app_shell.dart';
import 'role_navigation_config.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// GoRouter 全局实例的 Riverpod Provider
///
/// 通过监听 [authControllerProvider] 状态变化，
/// 驱动 GoRouter 的 [refreshListenable] 以实时响应登录/登出/角色切换。
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier(ref.read(authControllerProvider));
  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authStateListenable.value = next;
  });
  ref.onDispose(authStateListenable.dispose);
  return AppRouter.createRouter(authStateListenable: authStateListenable);
});

/// 应用路由配置
///
/// 包含：
/// - 启动页、登录/注册等顶层路由
/// - 租户端底部 Tab 壳（首页/找房/消息/我的）
/// - 管理员端底部 Tab 壳（工作台/门锁配置/系统调试）
/// - 租户端各业务独立页面（租约、房源、报修、租房流程等）
/// - 路由守卫：根据登录状态与角色自动拦截/重定向
class AppRouter {
  const AppRouter._();

  static final router = createRouter();

  /// 创建 GoRouter 实例
  ///
  /// [authStateListenable] 用于在认证状态变化时刷新路由守卫。
  static GoRouter createRouter({
    ValueListenable<AuthState>? authStateListenable,
  }) {
    return GoRouter(
      initialLocation: RoutePaths.splash,
      refreshListenable: authStateListenable,
      redirect: (context, state) =>
          _redirect(authStateListenable?.value, state),
      routes: [
        // ── 启动页 ──
        GoRoute(
          name: RouteNames.splash,
          path: RoutePaths.splash,
          builder: (context, state) => const AppLoadingPage(),
        ),
        // ── 登录页 ──
        GoRoute(
          name: RouteNames.login,
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),
        // ── 注册页 ──
        GoRoute(
          name: RouteNames.register,
          path: RoutePaths.register,
          builder: (context, state) => const RegisterPage(),
        ),
        // ── 房东被拦截提示页（房东账号无法使用移动端工作台）──
        GoRoute(
          name: RouteNames.webAdminRequired,
          path: RoutePaths.webAdminRequired,
          builder: (context, state) => const AppPlaceholderPage(
            title: '请前往 Web 管理后台',
            description: '房东账号暂不进入移动端工作台，请使用 Web 管理后台处理房源和经营管理。',
          ),
        ),
        // ── 通用入口重定向（/main → 根据角色跳转到对应首页）──
        GoRoute(
          name: RouteNames.main,
          path: RoutePaths.main,
          redirect: (context, state) =>
              _entryLocation(authStateListenable?.value),
        ),
        // ── 旧版首页重定向（/home → 根据角色跳转到对应首页）──
        GoRoute(
          path: RoutePaths.legacyHome,
          redirect: (context, state) =>
              _entryLocation(authStateListenable?.value),
        ),
        // ── 租户端底部 Tab 壳（首页/找房/消息/我的）──
        _tenantShell(),
        // ── 管理员端底部 Tab 壳（工作台/门锁配置/系统调试）──
        _staffShell(),
        // ── 租户端各业务独立页面（从 Tab 页 push 进入）──
        ..._tenantStandaloneRoutes(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 租户端底部 Tab 结构（StatefulShellRoute.indexedStack）
  // 四个 Tab 页面同时保持存活状态，切换时不丢失滚动位置
  // ═══════════════════════════════════════════════════════════════════

  static StatefulShellRoute _tenantShell() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          navigationShell: navigationShell,
          tabs: RoleNavigationConfig.tenant.tabs,
        );
      },
      branches: [
        // Tab 1：首页
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.home,
              path: RoutePaths.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Tab 2：找房
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.search,
              path: RoutePaths.search,
              builder: (context, state) => const FindHomePage(),
            ),
          ],
        ),
        // Tab 3：消息
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.messageCenter,
              path: RoutePaths.messageCenter,
              builder: (context, state) => const MessagePage(),
            ),
          ],
        ),
        // Tab 4：我的
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.profile,
              path: RoutePaths.profile,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 管理员端底部 Tab 结构（StatefulShellRoute.indexedStack）
  // ═══════════════════════════════════════════════════════════════════

  static StatefulShellRoute _staffShell() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          navigationShell: navigationShell,
          tabs: RoleNavigationConfig.staff.tabs,
        );
      },
      branches: [
        // Tab 1：工作台
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffWorkbench,
              path: RoutePaths.staff,
              builder: (context, state) => const WorkbenchPage(),
            ),
          ],
        ),
        // Tab 2：门锁配置（含扫描/初始化/管理子页面）
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffLockInit,
              path: RoutePaths.staffLockInit,
              builder: (context, state) => const LockInitial(),
              routes: [
                // 门锁管理详情页（需从配置页携带设备参数 push 进入）
                GoRoute(
                  name: RouteNames.staffLockManage,
                  path: RoutePaths.staffLockManage,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    if (extra == null) {
                      return const AppPlaceholderPage(
                        title: '门锁管理',
                        description: '请从门锁配置页面进入。',
                      );
                    }
                    return LockManagePage(
                      smartLockId: extra['smartLockId'] as String? ?? '',
                      lockName: extra['lockName'] as String? ?? '',
                      lockMac: extra['lockMac'] as String? ?? '',
                      lockData: extra['lockData'] as String? ?? '',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab 3：系统调试
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffDebug,
              path: RoutePaths.staffDebug,
              builder: (context, state) => const AppPlaceholderPage(
                title: '系统调试',
                description: '用于内部排查接口、设备和运行状态。',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 租户端独立页面（从 Tab 页通过 pushNamed 进入，不在底部 Tab 中）
  // ═══════════════════════════════════════════════════════════════════

  static List<RouteBase> _tenantStandaloneRoutes() {
    return [
      // ── 租约 ──
      GoRoute(
        name: RouteNames.lease,
        path: RoutePaths.lease,
        builder: (context, state) =>
            const MyLeasesPage(enforceAuthentication: false),
      ),
      GoRoute(
        name: RouteNames.leaseDetail,
        path: RoutePaths.leaseDetail,
        builder: (context, state) =>
            LeaseDetailPage(leaseId: state.pathParameters['leaseId'] ?? ''),
      ),

      // ── 门锁记录 ──
      GoRoute(
        name: RouteNames.rentOrders,
        path: RoutePaths.rentOrders,
        builder: (context, state) => const MyRentOrdersPage(),
      ),
      GoRoute(
        name: RouteNames.unlockRecords,
        path: RoutePaths.unlockRecords,
        builder: (context, state) => const UnlockRecordsPage(),
      ),
      GoRoute(
        name: RouteNames.tenantLockUnlock,
        path: RoutePaths.tenantLockUnlock,
        builder: (context, state) => TenantLockUnlockPage(
          leaseId: state.pathParameters['leaseId'] ?? '',
        ),
      ),

      // ── 房源 ──
      GoRoute(
        name: RouteNames.houseList,
        path: RoutePaths.houseList,
        redirect: (context, state) => RoutePaths.search, // 重定向到找房页
      ),
      GoRoute(
        name: RouteNames.houseSearch,
        path: RoutePaths.houseSearch,
        builder: (context, state) => const HouseSearchPage(),
      ),
      GoRoute(
        name: RouteNames.houseSearchResult,
        path: RoutePaths.houseSearchResult,
        builder: (context, state) => HouseSearchResultPage(
          keyword: state.uri.queryParameters['keyword'] ?? '',
        ),
      ),
      GoRoute(
        name: RouteNames.houseFilter,
        path: RoutePaths.houseFilter,
        builder: (context, state) => const HouseFilterPage(),
      ),
      GoRoute(
        name: RouteNames.houseDetail,
        path: RoutePaths.houseDetail,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? 'unknown';
          return HouseDetailPage(houseId: houseId);
        },
      ),

      // ── 预约 & 实名 ──
      GoRoute(
        name: RouteNames.appointment,
        path: RoutePaths.appointment,
        builder: (context, state) => const AppPlaceholderPage(title: '预约看房'),
      ),
      GoRoute(
        name: RouteNames.realNameAuth,
        path: RoutePaths.realNameAuth,
        builder: (context, state) => const AppPlaceholderPage(title: '实名认证'),
      ),

      // ── 账单 & 门锁（占位页面，待开发）──
      GoRoute(
        name: RouteNames.bill,
        path: RoutePaths.bill,
        builder: (context, state) => const AppPlaceholderPage(title: '账单'),
      ),
      GoRoute(
        name: RouteNames.lock,
        path: RoutePaths.lock,
        builder: (context, state) => const AppPlaceholderPage(title: '智能门锁'),
      ),

      // ── 报修 ──
      GoRoute(
        name: RouteNames.repairs,
        path: RoutePaths.repairs,
        builder: (context, state) => const RepairServicePage(),
      ),
      GoRoute(
        name: RouteNames.createRepair,
        path: RoutePaths.createRepair,
        builder: (context, state) => CreateRepairPage(
          initialType: RepairType.fromValue(state.uri.queryParameters['type']),
        ),
      ),
      GoRoute(
        name: RouteNames.repairRecords,
        path: RoutePaths.repairRecords,
        builder: (context, state) => const RepairRecordsPage(),
      ),
      GoRoute(
        name: RouteNames.repairDetail,
        path: RoutePaths.repairDetail,
        builder: (context, state) =>
            RepairDetailPage(repairId: state.pathParameters['repairId'] ?? ''),
      ),
      GoRoute(
        name: RouteNames.repair,
        path: RoutePaths.repair,
        redirect: (context, state) => RoutePaths.repairs,
      ),

      // ── 个人信息 & 设置 ──
      GoRoute(
        name: RouteNames.profileEdit,
        path: RoutePaths.profileEdit,
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        name: RouteNames.settings,
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),

      // ── 客服 ──
      GoRoute(
        name: RouteNames.customerService,
        path: RoutePaths.customerService,
        builder: (context, state) => const AppPlaceholderPage(title: '客服管家'),
      ),

      // ── 租房流程（预约看房 → 看房 → 申请 → 实名 → 签约 → 支付 → 入住）──
      GoRoute(
        name: RouteNames.viewingAppointment,
        path: RoutePaths.viewingAppointment,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          final houseTitle = state.uri.queryParameters['houseTitle'] ?? '房源';
          return ViewingAppointmentPage(
            houseId: houseId,
            houseTitle: houseTitle,
          );
        },
      ),
      GoRoute(
        name: RouteNames.viewingDetail,
        path: RoutePaths.viewingDetail,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return ViewingDetailPage(houseId: houseId);
        },
      ),
      GoRoute(
        name: RouteNames.rentalApplication,
        path: RoutePaths.rentalApplication,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return RentalApplicationPage(houseId: houseId);
        },
      ),
      GoRoute(
        name: RouteNames.realNameVerify,
        path: RoutePaths.realNameVerify,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return RealNameVerifyPage(orderId: orderId);
        },
      ),
      GoRoute(
        name: RouteNames.leaseContract,
        path: RoutePaths.leaseContract,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return LeaseContractPage(orderId: orderId);
        },
      ),
      GoRoute(
        name: RouteNames.rentalPayment,
        path: RoutePaths.rentalPayment,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return PaymentPage(orderId: orderId);
        },
      ),
      GoRoute(
        name: RouteNames.onlineSign,
        path: RoutePaths.onlineSign,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OnlineSignPage(orderId: orderId);
        },
      ),
      GoRoute(
        name: RouteNames.moveInComplete,
        path: RoutePaths.moveInComplete,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return MoveInCompletePage(orderId: orderId);
        },
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════
  // 路由守卫
  //
  // 每次导航都会调用此函数，根据当前认证状态决定是否放行。
  // 返回 null 表示放行；返回路径字符串表示重定向到该路径。
  //
  // 判断优先级：
  //   1. 未初始化 → 启动页
  //   2. 未登录且非游客 → 只能访问登录/注册页
  //   3. 游客 → 只能访问租户端允许的路由
  //   4. 已登录 → 不能访问登录/注册页；按角色权限控制
  // ═══════════════════════════════════════════════════════════════════

  static String? _redirect(AuthState? authState, GoRouterState state) {
    final routeName = state.name;
    final location = state.uri.path;

    // /main 路径直接分发到对应角色首页
    if (routeName == RouteNames.main || location == RoutePaths.main) {
      return _entryLocation(authState);
    }

    // authState 为 null（初始状态）时暂不拦截
    if (authState == null) return null;

    // 启动页始终放行
    if (routeName == RouteNames.splash) return null;

    // 尚未完成会话恢复 → 回到启动页等待
    if (!authState.isInitialized) return RoutePaths.splash;

    // ── 未登录且非游客 ──
    // 只能访问登录/注册等认证页面，其他页面重定向到登录页
    if (!authState.isLoggedIn && !authState.isGuest) {
      if (routeName == null) return null;
      return _isAuthRoute(routeName) ? null : RoutePaths.login;
    }

    // ── 游客模式 ──
    // 只能访问租户端允许的路由，不能访问登录/注册页和管理端
    if (authState.isGuest) {
      if (routeName == null || _isAuthRoute(routeName)) {
        return null;
      }
      return RoleNavigationConfig.tenant.allowedRouteNames.contains(routeName)
          ? null
          : RoleNavigationConfig.tenant.entryLocation;
    }

    // ── 已登录用户 ──
    final user = authState.user;
    if (user == null) return RoutePaths.login;

    // 登录/注册页对已登录用户不可见，重定向到角色首页
    final entryLocation = RoleNavigationConfig.entryLocationForRole(user.role);
    if (_isAuthRoute(routeName)) return entryLocation;

    // 超出角色权限范围的页面重定向到角色首页
    if (!RoleNavigationConfig.canAccess(user.role, routeName)) {
      return entryLocation;
    }

    return null; // 放行
  }

  /// 根据认证状态返回对应的首页路径
  static String _entryLocation(AuthState? authState) {
    final user = authState?.user;
    if (user == null) return RoleNavigationConfig.tenant.entryLocation;
    return RoleNavigationConfig.entryLocationForRole(user.role);
  }

  /// 判断是否为认证相关页面（登录/注册）
  static bool _isAuthRoute(String? routeName) {
    return routeName == RouteNames.login || routeName == RouteNames.register;
  }
}
