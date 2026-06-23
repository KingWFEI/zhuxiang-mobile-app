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
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/rental_flow/presentation/pages/lease_contract_page.dart';
import '../../features/rental_flow/presentation/pages/move_in_complete_page.dart';
import '../../features/rental_flow/presentation/pages/payment_page.dart';
import '../../features/rental_flow/presentation/pages/real_name_verify_page.dart';
import '../../features/rental_flow/presentation/pages/rental_application_page.dart';
import '../../features/rental_flow/presentation/pages/viewing_appointment_page.dart';
import '../../features/rental_flow/presentation/pages/viewing_detail_page.dart';
import '../../features/staff/lock_initial/presentation/lock_initial.dart';
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
        GoRoute(
          name: RouteNames.splash,
          path: RoutePaths.splash,
          builder: (context, state) => const AppLoadingPage(),
        ),
        GoRoute(
          name: RouteNames.login,
          path: RoutePaths.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          name: RouteNames.register,
          path: RoutePaths.register,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          name: RouteNames.webAdminRequired,
          path: RoutePaths.webAdminRequired,
          builder: (context, state) => const AppPlaceholderPage(
            title: '请前往 Web 管理后台',
            description: '房东账号暂不进入移动端工作台，请使用 Web 管理后台处理房源和经营管理。',
          ),
        ),
        GoRoute(
          name: RouteNames.main,
          path: RoutePaths.main,
          redirect: (context, state) =>
              _entryLocation(authStateListenable?.value),
        ),
        GoRoute(
          path: RoutePaths.legacyHome,
          redirect: (context, state) =>
              _entryLocation(authStateListenable?.value),
        ),
        _tenantShell(),
        _staffShell(),
        ..._tenantStandaloneRoutes(),
      ],
    );
  }

  static StatefulShellRoute _tenantShell() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          navigationShell: navigationShell,
          tabs: RoleNavigationConfig.tenant.tabs,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.home,
              path: RoutePaths.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.search,
              path: RoutePaths.search,
              builder: (context, state) => const FindHomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.messageCenter,
              path: RoutePaths.messageCenter,
              builder: (context, state) => const MessagePage(),
            ),
          ],
        ),
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

  static StatefulShellRoute _staffShell() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          navigationShell: navigationShell,
          tabs: RoleNavigationConfig.staff.tabs,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffWorkbench,
              path: RoutePaths.staff,
              builder: (context, state) => const AppPlaceholderPage(
                title: '工作台',
                description: '员工工作台入口，后续承载待办任务、门锁状态和现场操作概览。',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffLockInit,
              path: RoutePaths.staffLockInit,
              builder: (context, state) => const LockInitial(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffLockBindRoom,
              path: RoutePaths.staffLockBindRoom,
              builder: (context, state) => const AppPlaceholderPage(
                title: '门锁绑定房间',
                description: '用于将已初始化门锁绑定到具体房间。',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffLockTestUnlock,
              path: RoutePaths.staffLockTestUnlock,
              builder: (context, state) => const AppPlaceholderPage(
                title: '门锁测试开锁',
                description: '用于验证门锁绑定后的开锁链路。',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.staffUnlockRecords,
              path: RoutePaths.staffUnlockRecords,
              builder: (context, state) => const UnlockRecordsPage(),
            ),
          ],
        ),
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

  static List<RouteBase> _tenantStandaloneRoutes() {
    return [
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
      GoRoute(
        name: RouteNames.unlockRecords,
        path: RoutePaths.unlockRecords,
        builder: (context, state) => const UnlockRecordsPage(),
      ),
      GoRoute(
        name: RouteNames.houseList,
        path: RoutePaths.houseList,
        redirect: (context, state) => RoutePaths.search,
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
      GoRoute(
        name: RouteNames.repair,
        path: RoutePaths.repair,
        builder: (context, state) => const AppPlaceholderPage(title: '报修'),
      ),
      GoRoute(
        name: RouteNames.customerService,
        path: RoutePaths.customerService,
        builder: (context, state) => const AppPlaceholderPage(title: '客服管家'),
      ),
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
          final houseId = state.pathParameters['houseId'] ?? '';
          return RealNameVerifyPage(houseId: houseId);
        },
      ),
      GoRoute(
        name: RouteNames.leaseContract,
        path: RoutePaths.leaseContract,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return LeaseContractPage(houseId: houseId);
        },
      ),
      GoRoute(
        name: RouteNames.rentalPayment,
        path: RoutePaths.rentalPayment,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return PaymentPage(houseId: houseId);
        },
      ),
      GoRoute(
        name: RouteNames.moveInComplete,
        path: RoutePaths.moveInComplete,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? '';
          return MoveInCompletePage(houseId: houseId);
        },
      ),
    ];
  }

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
      if (_isAuthRoute(routeName)) {
        return RoleNavigationConfig.tenant.entryLocation;
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
