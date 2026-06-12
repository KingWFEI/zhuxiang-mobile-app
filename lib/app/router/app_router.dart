import 'package:go_router/go_router.dart';

import '../launch/app_loading_page.dart';
import '../../core/widgets/app_placeholder_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/house/presentation/pages/find_home_page.dart';
import '../../features/house/presentation/pages/house_detail_page.dart';
import '../../features/message/presentation/pages/message_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'app_shell.dart';
import 'route_names.dart';
import 'route_paths.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
    initialLocation: RoutePaths.splash,
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
        name: RouteNames.main,
        path: RoutePaths.main,
        redirect: (context, state) => RoutePaths.home,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
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
      ),
      GoRoute(
        name: RouteNames.houseList,
        path: RoutePaths.houseList,
        redirect: (context, state) => RoutePaths.search,
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
        name: RouteNames.lease,
        path: RoutePaths.lease,
        builder: (context, state) => const AppPlaceholderPage(
          title: '租约',
          actions: [
            AppPlaceholderAction(label: '账单', routeName: RouteNames.bill),
          ],
        ),
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
    ],
  );
}
