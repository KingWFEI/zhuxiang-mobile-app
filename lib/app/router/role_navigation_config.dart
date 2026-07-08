import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/user_role.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// 底部 Tab 配置项
class AppTabConfig {
  const AppTabConfig({
    required this.routeName,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.showBadge = false,
  });

  /// 点击后跳转的路由名称
  final String routeName;

  /// Tab 显示文字
  final String label;

  /// 未选中时图标
  final IconData icon;

  /// 选中时图标
  final IconData selectedIcon;

  /// 是否显示红点角标
  final bool showBadge;
}

/// 角色导航配置 —— 定义不同角色的首页入口、底部 Tab 及可访问路由
class RoleNavigationConfig {
  const RoleNavigationConfig({
    required this.entryLocation,
    required this.entryRouteName,
    required this.tabs,
    required this.allowedRouteNames,
  });

  /// 角色登录后的默认跳转路径
  final String entryLocation;

  /// 角色登录后的默认路由名称
  final String entryRouteName;

  /// 底部导航栏 Tab 列表
  final List<AppTabConfig> tabs;

  /// 该角色允许访问的路由名称集合
  final Set<String> allowedRouteNames;

  // ─── 租户端配置 ─────────────────────────────────────────────

  static const tenant = RoleNavigationConfig(
    entryLocation: RoutePaths.tenant,
    entryRouteName: RouteNames.home,
    // 底部四个 Tab：首页、找房、消息、我的
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
    // 租户可访问的所有页面路由
    allowedRouteNames: {
      // 底部 Tab 页
      RouteNames.home,
      RouteNames.search,
      RouteNames.messageCenter,
      RouteNames.profile,
      // 租约
      RouteNames.lease,
      RouteNames.leaseDetail,
      RouteNames.leaseContractView,
      RouteNames.leaseTerminationApply,
      RouteNames.rentOrders,
      RouteNames.paymentRecords,
      RouteNames.paymentDetail,
      // 门锁
      RouteNames.unlockRecords,
      // 房源
      RouteNames.houseList,
      RouteNames.houseSearch,
      RouteNames.houseSearchResult,
      RouteNames.houseFilter,
      RouteNames.houseDetail,
      RouteNames.immersiveTour,
      // 预约 & 实名
      RouteNames.appointment,
      RouteNames.realNameAuth,
      // 账单 & 门锁详情
      RouteNames.bill,
      RouteNames.lock,
      RouteNames.tenantLockUnlock,
      // 报修
      RouteNames.repair,
      RouteNames.repairs,
      RouteNames.createRepair,
      RouteNames.repairRecords,
      RouteNames.repairDetail,
      // 个人信息 & 设置
      RouteNames.profileEdit,
      RouteNames.settings,
      RouteNames.userAgreement,
      RouteNames.privacyPolicy,
      // 客服
      RouteNames.customerService,
      // 租房流程
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

  // ─── 管理员端配置 ───────────────────────────────────────────

  static const staff = RoleNavigationConfig(
    entryLocation: RoutePaths.staff,
    entryRouteName: RouteNames.staffWorkbench,
    // 底部三个 Tab：工作台、门锁配置、系统调试
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
    // 管理员可访问的路由
    allowedRouteNames: {
      RouteNames.staffWorkbench,
      RouteNames.staffLockInit,
      RouteNames.staffLockManage,
      RouteNames.staffDebug,
    },
  );

  /// 根据角色获取对应的导航配置
  static RoleNavigationConfig forRole(UserRole role) {
    if (role.usesStaffShell) return staff;
    return tenant;
  }

  /// 根据角色获取登录后的入口路径
  static String entryLocationForRole(UserRole role) {
    // 房东账号需前往 Web 管理后台，移动端仅给提示页
    if (role.requiresWebAdmin) return RoutePaths.webAdminRequired;
    return forRole(role).entryLocation;
  }

  /// 判断指定角色是否有权限访问某个路由
  static bool canAccess(UserRole role, String? routeName) {
    if (routeName == null) return true;
    if (role.requiresWebAdmin) return routeName == RouteNames.webAdminRequired;
    return forRole(role).allowedRouteNames.contains(routeName);
  }
}
