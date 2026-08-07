import 'package:hugeicons/hugeicons.dart';

import '../../features/auth/domain/entities/user_role.dart';
import 'app_mode_controller.dart';
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
  final List<List<dynamic>> icon;

  /// 选中时图标
  final List<List<dynamic>> selectedIcon;

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
        icon: HugeIcons.strokeRoundedHome01,
        selectedIcon: HugeIcons.strokeRoundedHome02,
      ),
      AppTabConfig(
        routeName: RouteNames.search,
        label: '找房',
        icon: HugeIcons.strokeRoundedSearch01,
        selectedIcon: HugeIcons.strokeRoundedSearch02,
      ),
      AppTabConfig(
        routeName: RouteNames.messageCenter,
        label: '消息',
        icon: HugeIcons.strokeRoundedChat01,
        selectedIcon: HugeIcons.strokeRoundedChat01,
        showBadge: true,
      ),
      AppTabConfig(
        routeName: RouteNames.profile,
        label: '我的',
        icon: HugeIcons.strokeRoundedUser02,
        selectedIcon: HugeIcons.strokeRoundedUser03,
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
      RouteNames.leaseHistory,
      RouteNames.leaseDetail,
      RouteNames.depositDetail,
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
      RouteNames.houseMap,
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
      RouteNames.rentedHomeDetail,
      RouteNames.settings,
      RouteNames.userAgreement,
      RouteNames.privacyPolicy,
      RouteNames.favoriteHouses,
      // 客服
      RouteNames.customerService,
      RouteNames.customerServiceEnter,
      RouteNames.customerServiceChat,
      // 租房流程
      RouteNames.viewingAppointment,
      RouteNames.viewingDetail,
      RouteNames.appointmentUnlock,
      RouteNames.rentalApplication,
      RouteNames.leaseContract,
      RouteNames.rentalPayment,
      RouteNames.onlineSign,
      RouteNames.waitingLandlordSign,
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
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        selectedIcon: HugeIcons.strokeRoundedDashboardSquare02,
      ),
      AppTabConfig(
        routeName: RouteNames.staffLockInit,
        label: '门锁配置',
        icon: HugeIcons.strokeRoundedHome03,
        selectedIcon: HugeIcons.strokeRoundedHome04,
      ),
      AppTabConfig(
        routeName: RouteNames.staffDebug,
        label: '系统调试',
        icon: HugeIcons.strokeRoundedBug01,
        selectedIcon: HugeIcons.strokeRoundedBug02,
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

  // ─── 房东端配置 ───────────────────────────────────────────
  static const landlord = RoleNavigationConfig(
    entryLocation: RoutePaths.landlordWorkbench,
    entryRouteName: RouteNames.landlordWorkbench,
    // 底部两个 Tab：工作台、个人中心
    tabs: [
      AppTabConfig(
        routeName: RouteNames.landlordWorkbench,
        label: '工作台',
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        selectedIcon: HugeIcons.strokeRoundedDashboardSquare02,
      ),
      AppTabConfig(
        routeName: RouteNames.landlordProfile,
        label: '个人中心',
        icon: HugeIcons.strokeRoundedUser02,
        selectedIcon: HugeIcons.strokeRoundedUser03,
      ),
    ],
    // 房东可访问的路由
    allowedRouteNames: {
      RouteNames.landlordWorkbench,
      RouteNames.landlordHouses,
      RouteNames.landlordHouseCreate,
      RouteNames.landlordHouseEdit,
      RouteNames.landlordContracts,
      RouteNames.landlordAppointments,
      RouteNames.landlordAppointmentDetail,
      RouteNames.landlordContractDetail,
      RouteNames.landlordContractWebview,
      RouteNames.landlordContractResult,
      RouteNames.landlordProfile,
      RouteNames.landlordProfileEdit,
      RouteNames.landlordVerify,
      RouteNames.settings,
      RouteNames.userAgreement,
      RouteNames.privacyPolicy,
    },
  );

  /// 根据角色获取对应的导航配置
  static RoleNavigationConfig forRole(UserRole role) {
    if (role.usesStaffShell) return staff;
    if (role.usesLandlordShell) return landlord;
    return tenant;
  }

  /// 根据角色获取登录后的入口路径
  static String entryLocationForRole(UserRole role) {
    return forRole(role).entryLocation;
  }

  /// 当前工作模式只影响房东账号的默认入口，不改变账号本身的身份能力。
  static String entryLocationForSession(UserRole role, AppMode mode) {
    if (role.usesStaffShell) return staff.entryLocation;
    if (role.usesLandlordShell && mode == AppMode.landlord) {
      return landlord.entryLocation;
    }
    return tenant.entryLocation;
  }

  /// 判断指定角色是否有权限访问某个路由
  static bool canAccess(UserRole role, String? routeName) {
    if (routeName == null) return true;
    if (role.usesLandlordShell) {
      return tenant.allowedRouteNames.contains(routeName) ||
          landlord.allowedRouteNames.contains(routeName);
    }
    return forRole(role).allowedRouteNames.contains(routeName);
  }
}
