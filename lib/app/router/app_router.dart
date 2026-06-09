import 'package:go_router/go_router.dart';

import '../../core/widgets/app_placeholder_page.dart';
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
        builder: (context, state) => const AppPlaceholderPage(
          title: '住享',
          description: 'App 启动页占位',
          actions: [
            AppPlaceholderAction(label: '进入首页', routeName: RouteNames.main),
            AppPlaceholderAction(label: '登录入口', routeName: RouteNames.login),
          ],
        ),
      ),
      GoRoute(
        name: RouteNames.login,
        path: RoutePaths.login,
        builder: (context, state) => const AppPlaceholderPage(
          title: '登录',
          description: '登录模块占位，暂不实现真实登录业务',
          actions: [
            AppPlaceholderAction(label: '游客浏览', routeName: RouteNames.main),
          ],
        ),
      ),
      GoRoute(
        name: RouteNames.main,
        path: RoutePaths.main,
        builder: (context, state) => const AppPlaceholderPage(
          title: '主框架',
          description: '主导航容器占位，后续承载底部导航或标签页',
          actions: [
            AppPlaceholderAction(label: '首页', routeName: RouteNames.home),
            AppPlaceholderAction(label: '找房', routeName: RouteNames.search),
            AppPlaceholderAction(
              label: '房源列表',
              routeName: RouteNames.houseList,
            ),
            AppPlaceholderAction(label: '个人中心', routeName: RouteNames.profile),
            AppPlaceholderAction(label: '租约', routeName: RouteNames.lease),
            AppPlaceholderAction(label: '账单', routeName: RouteNames.bill),
            AppPlaceholderAction(label: '门锁', routeName: RouteNames.lock),
            AppPlaceholderAction(label: '报修', routeName: RouteNames.repair),
            AppPlaceholderAction(
              label: '消息',
              routeName: RouteNames.messageCenter,
            ),
            AppPlaceholderAction(
              label: '客服',
              routeName: RouteNames.customerService,
            ),
          ],
        ),
      ),
      GoRoute(
        name: RouteNames.home,
        path: RoutePaths.home,
        builder: (context, state) => const AppPlaceholderPage(title: '首页'),
      ),
      GoRoute(
        name: RouteNames.search,
        path: RoutePaths.search,
        builder: (context, state) => const AppPlaceholderPage(title: '找房'),
      ),
      GoRoute(
        name: RouteNames.houseList,
        path: RoutePaths.houseList,
        builder: (context, state) => const AppPlaceholderPage(
          title: '房源列表',
          actions: [
            AppPlaceholderAction(
              label: '查看房源详情',
              routeName: RouteNames.houseDetail,
              pathParameters: {'houseId': 'mock-house-001'},
            ),
          ],
        ),
      ),
      GoRoute(
        name: RouteNames.houseDetail,
        path: RoutePaths.houseDetail,
        builder: (context, state) {
          final houseId = state.pathParameters['houseId'] ?? 'unknown';
          return AppPlaceholderPage(
            title: '房源详情',
            description: '当前房源 ID: $houseId',
            actions: const [
              AppPlaceholderAction(
                label: '预约看房',
                routeName: RouteNames.appointment,
              ),
            ],
          );
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
        name: RouteNames.profile,
        path: RoutePaths.profile,
        builder: (context, state) => const AppPlaceholderPage(
          title: '个人中心',
          actions: [
            AppPlaceholderAction(
              label: '实名认证',
              routeName: RouteNames.realNameAuth,
            ),
          ],
        ),
      ),
      GoRoute(
        name: RouteNames.lease,
        path: RoutePaths.lease,
        builder: (context, state) => const AppPlaceholderPage(title: '租约'),
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
        name: RouteNames.messageCenter,
        path: RoutePaths.messageCenter,
        builder: (context, state) => const AppPlaceholderPage(title: '消息中心'),
      ),
      GoRoute(
        name: RouteNames.customerService,
        path: RoutePaths.customerService,
        builder: (context, state) => const AppPlaceholderPage(title: '客服管家'),
      ),
    ],
  );
}
