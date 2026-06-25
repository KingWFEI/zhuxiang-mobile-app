import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/user_role.dart';
import 'route_names.dart';
import 'route_paths.dart';

class AppTabConfig {
  const AppTabConfig({
    required this.routeName,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.showBadge = false,
  });

  final String routeName;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool showBadge;
}

class RoleNavigationConfig {
  const RoleNavigationConfig({
    required this.entryLocation,
    required this.entryRouteName,
    required this.tabs,
    required this.allowedRouteNames,
  });

  final String entryLocation;
  final String entryRouteName;
  final List<AppTabConfig> tabs;
  final Set<String> allowedRouteNames;

  static const tenant = RoleNavigationConfig(
    entryLocation: RoutePaths.tenant,
    entryRouteName: RouteNames.home,
    tabs: [
      AppTabConfig(
        routeName: RouteNames.home,
        label: '首页',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      AppTabConfig(
        routeName: RouteNames.search,
        label: '找房',
        icon: Icons.search,
        selectedIcon: Icons.manage_search,
      ),
      AppTabConfig(
        routeName: RouteNames.messageCenter,
        label: '消息',
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        showBadge: true,
      ),
      AppTabConfig(
        routeName: RouteNames.profile,
        label: '我的',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ],
    allowedRouteNames: {
      RouteNames.home,
      RouteNames.search,
      RouteNames.messageCenter,
      RouteNames.profile,
      RouteNames.lease,
      RouteNames.leaseDetail,
      RouteNames.unlockRecords,
      RouteNames.houseList,
      RouteNames.houseSearch,
      RouteNames.houseSearchResult,
      RouteNames.houseFilter,
      RouteNames.houseDetail,
      RouteNames.appointment,
      RouteNames.realNameAuth,
      RouteNames.bill,
      RouteNames.lock,
      RouteNames.repair,
      RouteNames.repairs,
      RouteNames.createRepair,
      RouteNames.repairRecords,
      RouteNames.repairDetail,
      RouteNames.customerService,
      RouteNames.viewingAppointment,
      RouteNames.viewingDetail,
      RouteNames.rentalApplication,
      RouteNames.realNameVerify,
      RouteNames.leaseContract,
      RouteNames.rentalPayment,
      RouteNames.onlineSign,
      RouteNames.moveInComplete,
    },
  );

  static const staff = RoleNavigationConfig(
    entryLocation: RoutePaths.staff,
    entryRouteName: RouteNames.staffWorkbench,
    tabs: [
      AppTabConfig(
        routeName: RouteNames.staffWorkbench,
        label: '工作台',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      AppTabConfig(
        routeName: RouteNames.staffLockInit,
        label: '门锁配置',
        icon: Icons.add_home_work_outlined,
        selectedIcon: Icons.add_home_work,
      ),
      AppTabConfig(
        routeName: RouteNames.staffDebug,
        label: '系统调试',
        icon: Icons.bug_report_outlined,
        selectedIcon: Icons.bug_report,
      ),
    ],
    allowedRouteNames: {
      RouteNames.staffWorkbench,
      RouteNames.staffLockInit,
      RouteNames.staffLockManage,
      RouteNames.staffDebug,
    },
  );

  static RoleNavigationConfig forRole(UserRole role) {
    if (role.usesStaffShell) return staff;
    return tenant;
  }

  static String entryLocationForRole(UserRole role) {
    if (role.requiresWebAdmin) return RoutePaths.webAdminRequired;
    return forRole(role).entryLocation;
  }

  static bool canAccess(UserRole role, String? routeName) {
    if (routeName == null) return true;
    if (role.requiresWebAdmin) return routeName == RouteNames.webAdminRequired;
    return forRole(role).allowedRouteNames.contains(routeName);
  }
}
