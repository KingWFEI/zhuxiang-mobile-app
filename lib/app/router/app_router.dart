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
import '../../features/message/presentation/pages/message_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/repair/domain/entities/repair_order.dart';
import '../../features/repair/presentation/pages/create_repair_page.dart';
import '../../features/repair/presentation/pages/repair_detail_page.dart';
import '../../features/repair/presentation/pages/repair_records_page.dart';
import '../../features/repair/presentation/pages/repair_service_page.dart';
import '../../features/rental_flow/presentation/pages/lease_contract_page.dart';
import '../../features/rental_flow/presentation/pages/move_in_complete_page.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier(ref.read(authControllerProvider));
  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authStateListenable.value = next;
  });
  ref.onDispose(authStateListenable.dispose);
  return AppRouter.createRouter(authStateListenable: authStateListenable);
});

class AppRouter {
  const AppRouter._();

  static final router = createRouter();

  static GoRouter createRouter({
    ValueListenable<AuthState>? authStateListenable,
  }) {
    return GoRouter(
      initialLocation: RoutePaths.splash,
      refreshListenable: authStateListenable,
      redirect: (context, state) =>
          _redirect(authStateListenable?.value, state),
      routes: [
        // 启动页
        GoRoute(
          name: RouteNames.splash,
          path: RoutePaths.splash,
          builder: (context, state) => const AppLoadingPage(),
        ),
        // 登录页
        GoRoute(
          name: RouteNames.login,
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),
        // 注册页
        GoRoute(
          name: RouteNames.register,
          path: RoutePaths.register,
          builder: (context, state) => const RegisterPage(),
        ),
        // 非管理员账号拦截提示页
        GoRoute(
          name: RouteNames.webAdminRequired,
          path: RoutePaths.webAdminRequired,
          builder: (context, state) => const AppPlaceholderPage(
            title: '请前往 Web 管理后台',
            description: '房东账号暂不进入移动端工作台，请使用 Web 管理后台处理房源和经营管理。',
          ),
        ),
        // 通用入口重定向
        GoRoute(
          name: RouteNames.main,
          path: RoutePaths.main,
          redirect: (context, state) =>
              _entryLocation(authStateListenable?.value),
        ),
        // 旧版首页重定向
        GoRoute(
          path: RoutePaths.legacyHome,
          redirect: (context, state) =>
              _entryLocation(authStateListenable?.value),
        ),
        // 租户端底部 Tab 壳
        _tenantShell(),
        // 管理员端底部 Tab 壳
        _staffShell(),
        // 租户端独立页面
        ..._tenantStandaloneRoutes(),
      ],
    );
  }

  // ─── 租户端底部 Tab 结构 ─────────────────────────────────────────

  static StatefulShellRoute _tenantShell() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          navigationShell: navigationShell,
          tabs: RoleNavigationConfig.tenant.tabs,
        );
      },
      branches: [
        // Tab 1: 首页
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.home,
              path: RoutePaths.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        // Tab 2: 找房
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.search,
              path: RoutePaths.search,
              builder: (context, state) => const FindHomePage(),
            ),
          ],
        ),
        // Tab 3: 消息
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.messageCenter,
              path: RoutePaths.messageCenter,
              builder: (context, state) => const MessagePage(),
            ),
          ],
        ),
        // Tab 4: 我的
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

  // ─── 管理员端底部 Tab 结构 ───────────────────────────────────────

  static StatefulShellRoute _staffShell() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          navigationShell: navigationShell,
          tabs: RoleNavigationConfig.staff.tabs,
        );
      },
      branches: [
        // Tab 1: 工作台
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffWorkbench,
              path: RoutePaths.staff,
              builder: (context, state) => const WorkbenchPage(),
            ),
          ],
        ),
        // Tab 2: 门锁配置（扫描/初始化/管理入口）
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffLockInit,
              path: RoutePaths.staffLockInit,
              builder: (context, state) => const LockInitial(),
              routes: [
                // 门锁管理详情页（从门锁配置页 push 进入）
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
        // Tab 3: 系统调试
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

  // ─── 租户端独立页面 ──────────────────────────────────────────────

  static List<RouteBase> _tenantStandaloneRoutes() {
    return [
      // 合同列表
      GoRoute(
        name: RouteNames.lease,
        path: RoutePaths.lease,
        builder: (context, state) =>
            const MyLeasesPage(enforceAuthentication: false),
      ),
      // 合同详情
      GoRoute(
        name: RouteNames.leaseDetail,
        path: RoutePaths.leaseDetail,
        builder: (context, state) =>
            LeaseDetailPage(leaseId: state.pathParameters['leaseId'] ?? ''),
      ),
      // 开锁记录
      GoRoute(
        name: RouteNames.unlockRecords,
        path: RoutePaths.unlockRecords,
        builder: (context, state) => const UnlockRecordsPage(),
      ),
      // 房源列表（重定向到找房）
      GoRoute(
        name: RouteNames.houseList,
        path: RoutePaths.houseList,
        redirect: (context, state) => RoutePaths.search,
      ),
      // 房源搜索
      GoRoute(
        name: RouteNames.houseSearch,
        path: RoutePaths.houseSearch,
        builder: (context, state) => const HouseSearchPage(),
      ),
      // 房源搜索结果
      GoRoute(
        name: RouteNames.houseSearchResult,
        path: RoutePaths.houseSearchResult,
        builder: (context, state) => HouseSearchResultPage(
          keyword: state.uri.queryParameters['keyword'] ?? '',
        ),
      ),
      // 房源筛选
      GoRoute(
        name: RouteNames.houseFilter,
        path: RoutePaths.houseFilter,
        builder: (context, state) => const HouseFilterPage(),
      ),
      // 房源详情
      GoRoute(
        name: RouteNames.houseDetail,
        path: RoutePaths.houseDetail,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? 'unknown';
          return HouseDetailPage(houseId: houseId);
        },
      ),
      // 预约看房
      GoRoute(
        name: RouteNames.appointment,
        path: RoutePaths.appointment,
        builder: (context, state) => const AppPlaceholderPage(title: '预约看房'),
      ),
      // 实名认证
      GoRoute(
        name: RouteNames.realNameAuth,
        path: RoutePaths.realNameAuth,
        builder: (context, state) => const AppPlaceholderPage(title: '实名认证'),
      ),
      // 账单
      GoRoute(
        name: RouteNames.bill,
        path: RoutePaths.bill,
        builder: (context, state) => const AppPlaceholderPage(title: '账单'),
      ),
      // 智能门锁
      GoRoute(
        name: RouteNames.lock,
        path: RoutePaths.lock,
        builder: (context, state) => const AppPlaceholderPage(title: '智能门锁'),
      ),
      // 报修
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
      // 个人信息编辑
      GoRoute(
        name: RouteNames.profileEdit,
        path: RoutePaths.profileEdit,
        builder: (context, state) => const ProfileEditPage(),
      ),
      // 客服管家
      GoRoute(
        name: RouteNames.customerService,
        path: RoutePaths.customerService,
        builder: (context, state) => const AppPlaceholderPage(title: '客服管家'),
      ),
      // 预约看房（租房流程）
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
      // 看房详情
      GoRoute(
        name: RouteNames.viewingDetail,
        path: RoutePaths.viewingDetail,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return ViewingDetailPage(houseId: houseId);
        },
      ),
      // 租房申请
      GoRoute(
        name: RouteNames.rentalApplication,
        path: RoutePaths.rentalApplication,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return RentalApplicationPage(houseId: houseId);
        },
      ),
      // 实名验证
      GoRoute(
        name: RouteNames.realNameVerify,
        path: RoutePaths.realNameVerify,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return RealNameVerifyPage(orderId: orderId);
        },
      ),
      // 租赁合同
      GoRoute(
        name: RouteNames.leaseContract,
        path: RoutePaths.leaseContract,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return LeaseContractPage(orderId: orderId);
        },
      ),
      // 支付页面
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
      // 入住完成
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

  // ─── 路由守卫 ────────────────────────────────────────────────────

  static String? _redirect(AuthState? authState, GoRouterState state) {
    final routeName = state.name;
    final location = state.uri.path;

    if (routeName == RouteNames.main || location == RoutePaths.main) {
      return _entryLocation(authState);
    }
    if (authState == null) return null;
    if (routeName == RouteNames.splash) return null;
    if (!authState.isInitialized) return RoutePaths.splash;

    if (!authState.isLoggedIn && !authState.isGuest) {
      return _isAuthRoute(routeName) ? null : RoutePaths.login;
    }

    if (authState.isGuest) {
      if (routeName == null || _isAuthRoute(routeName)) {
        return null;
      }
      return RoleNavigationConfig.tenant.allowedRouteNames.contains(routeName)
          ? null
          : RoleNavigationConfig.tenant.entryLocation;
    }

    final user = authState.user;
    if (user == null) return RoutePaths.login;

    final entryLocation = RoleNavigationConfig.entryLocationForRole(user.role);
    if (_isAuthRoute(routeName)) return entryLocation;
    if (!RoleNavigationConfig.canAccess(user.role, routeName)) {
      return entryLocation;
    }
    return null;
  }

  static String _entryLocation(AuthState? authState) {
    final user = authState?.user;
    if (user == null) return RoleNavigationConfig.tenant.entryLocation;
    return RoleNavigationConfig.entryLocationForRole(user.role);
  }

  static bool _isAuthRoute(String? routeName) {
    return routeName == RouteNames.login || routeName == RouteNames.register;
  }
}
