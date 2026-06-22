import 'package:go_router/go_router.dart';

import '../../core/widgets/app_placeholder_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/house/presentation/pages/find_house_page.dart';
import '../../features/house/presentation/pages/house_filter_page.dart';
import '../../features/house/presentation/pages/house_search_page.dart';
import '../../features/house/presentation/pages/house_search_result_page.dart';
import '../../features/house/presentation/pages/house_detail_page.dart';
import '../../features/lease/presentation/pages/lease_detail_page.dart';
import '../../features/lease/presentation/pages/my_leases_page.dart';
import '../../features/message/presentation/pages/message_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/rental_flow/presentation/pages/lease_contract_page.dart';
import '../../features/rental_flow/presentation/pages/move_in_complete_page.dart';
import '../../features/rental_flow/presentation/pages/payment_page.dart';
import '../../features/rental_flow/presentation/pages/real_name_verify_page.dart';
import '../../features/rental_flow/presentation/pages/rental_application_page.dart';
import '../../features/rental_flow/presentation/pages/viewing_appointment_page.dart';
import '../../features/rental_flow/presentation/pages/viewing_detail_page.dart';
import '../launch/app_loading_page.dart';
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
              GoRoute(
                name: RouteNames.lease,
                path: RoutePaths.lease,
                // TODO: 联调完成后移除 enforceAuthentication，恢复租约登录拦截。
                builder: (context, state) =>
                    const MyLeasesPage(enforceAuthentication: false),
                routes: [
                  GoRoute(
                    name: RouteNames.leaseDetail,
                    path: RoutePaths.leaseDetail,
                    builder: (context, state) => LeaseDetailPage(
                      leaseId: state.pathParameters['leaseId'] ?? '',
                    ),
                  ),
                ],
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
    ],
  );
}
