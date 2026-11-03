# 移动端功能与角色权限梳理

> 范围：`zhuxiang-mobile-app` 当前 Flutter 代码。功能以页面、路由、Provider/Service 实现为依据；不代表服务端授权策略已经核实。

## 一、系统功能结构图



## 二、角色与权限入口

| 用户状态 / 角色        | 默认入口与导航                                           | 当前移动端允许访问的功能范围                                       |
| ---------------- | ------------------------------------------------- | ---------------------------------------------------- |
| 游客               | 租客端首页；不要求登录                                       | 路由守卫按租客端路由白名单放行；涉及账号、订单、租约或设备的具体操作仍可能要求登录或有效业务数据。    |
| 租客 `TENANT`      | `/tenant`；首页、找房、消息、我的                             | 租客路由白名单，包括找房、租房流程、租约、账单、支付、报修、门锁、预约、消息、客服和个人中心。      |
| 房东 `LANDLORD`    | `/tenant` 或 `/landlord/workbench`；入口由保存的 App 模式决定 | 可访问租客端与房东端路由白名单；房东个人中心可切回租客模式。模式决定默认工作区，不是独立账号或独立角色。 |
| 管家 `HOUSEKEEPER` | `/staff`；工作台、门锁配置、系统调试                            | 当前只配置员工工作台白名单，主要业务是蓝牙门锁初始化和管理。                       |
| 管理员 `ADMIN`      | `/staff`；与管家使用同一导航                                | 当前路由白名单和员工工作台与管家一致；代码中没有单独的管理员移动端菜单或功能集。             |

角色枚举和角色归类见 `lib/features/auth/domain/entities/user_role.dart`。底部菜单、路由白名单和角色入口见 `lib/app/router/role_navigation_config.dart`；登录态、游客态和路由拦截见 `lib/app/router/app_router.dart`。

## 三、按角色整理已实现功能

### 3.1 公共与游客功能

- 登录：短信验证码、密码登录；注册：手机号、验证码、密码和昵称。
- 会话恢复、Token 持久化、退出登录；路由根据登录态和角色选择入口。
- 游客模式允许进入租客端路由范围。
- 个人资料编辑、设置、用户协议和隐私政策页面属于公共/账号相关入口。

### 3.2 租客端

| 业务域   | 当前页面能力                                                         |
| ----- | -------------------------------------------------------------- |
| 首页与找房 | 首页聚合内容与推荐；房源搜索、筛选、排序、搜索结果、地图/沉浸看房、房源详情及收藏。                     |
| 看房与租房 | 看房预约、预约详情；创建租赁订单；实名认证；合同预览与确认；支付；在线签约；等待房东签署；入住完成；我的租房订单及订单详情。 |
| 租约与退租 | 租约列表、历史记录、详情、押金详情、电子合同、退租申请、退房验收。                              |
| 账单与支付 | 账单列表/缴费页面、支付记录及支付详情。                                           |
| 报修    | 创建报修、报修记录、工单详情、取消及评价等操作。                                       |
| 门锁    | 按租约开锁、门锁状态/权限信息、开锁记录；普通 `/lock` 入口仍为占位页。                       |
| 消息与客服 | 消息列表、详情、已读/删除等操作；客服会话列表、聊天、消息流和会话反馈页面。                         |
| 我的    | 当前租住住房、租约入口、门锁快捷操作、预约、实名、收藏、个人资料、设置及账号操作。                      |

页面入口及其业务实现主要位于 `lib/features/home`、`house`、`rental_flow`、`lease`、`bill`、`payment`、`repair`、`lock`、`appointment`、`message`、`customer_service` 和 `profile`。

### 3.3 房东端

- **工作台**：展示房源管理、看房预约、合同签署入口和待办数量。
- **房源管理**：列表与状态筛选；新增/编辑；房源图片及产权材料上传；发布、下架、删除。
- **看房预约**：查看预约及详情；确认、拒绝、改期；核验租客到场；标记完成或未到场。
- **合同签署**：查看待签租赁合同/解约协议、详情，跳转电子签署，刷新签署状态；支持拒签租赁合同。
- **个人中心**：查看和编辑房东公开资料，切换到租客模式，进入账号设置。
- **房东认证**：存在申请页和服务实现，用于提交身份/产权证明和联系资料；当前入口与租客角色路由白名单存在不一致（见下文）。

页面主要位于 `lib/features/landlord`、`lib/features/landlord_auth` 和 `lib/features/appointment`。

### 3.4 管家端 / 管理员端

- **工作台**：显示员工工作台说明、门锁初始化快捷入口和退出登录。
- **门锁配置**：扫描附近蓝牙门锁；调用 TTLock 初始化；保存设备信息；选择/绑定房源；同步平台数据；进入门锁管理页。
- **系统调试**：路由和菜单已存在，目前是说明性占位页面。
- `HOUSEKEEPER` 和 `ADMIN` 共用 `RoleNavigationConfig.staff`，没有根据这两个角色再做细分菜单。

主要实现位于 `lib/features/staff/workbench` 和 `lib/features/staff/lock_initial`。

## 四、权限实现方式与边界

1. **当前权限主要在路由层按角色白名单控制。** `RoleNavigationConfig.canAccess` 负责判断路由名；`app_router.dart` 根据登录状态、角色及房东工作模式执行重定向。
2. **房东模式是工作区切换。** `AppModeController` 按用户 ID 保存最近模式；房东角色可以访问租客与房东两组路由，其他角色不能切入房东模式。
3. **未发现可用的细粒度权限系统。** `lib/core/permissions/permission_service.dart` 的 `hasPermission` 当前固定返回 `false`，代码中没有发现业务调用；因此不能据此认为页面按钮或每个业务动作具备独立 ACL。
4. **移动端路由守卫不等于服务端数据授权。** 本梳理只能确认 App 端隐藏/拦截哪些路由；不同用户能否读取或修改某套房源、合同、租约，仍需由后端接口校验，单看移动端代码无法确认服务端策略。

## 五、当前发现的入口/权限不一致

- **租客申请房东认证的入口会被角色守卫拦截。** 租客“我的”页面展示“房东认证”入口并跳转 `landlordVerify`，但 `RouteNames.landlordVerify` 只在房东白名单里，未加入租客白名单；普通租客点击后会被重定向回租客首页。相关代码：`lib/features/profile/presentation/pages/profile_page.dart`、`lib/app/router/role_navigation_config.dart`。
- **退房验收页面未加入租客白名单。** `MoveOutInspectionPage` 已注册路由，且租约详情/退租流程会跳转到该页面，但 `RouteNames.moveOutInspection` 未出现在 `RoleNavigationConfig.tenant.allowedRouteNames`；普通租客可能被守卫重定向。相关代码：`lib/app/router/app_router.dart`、`lib/app/router/role_navigation_config.dart`。
- **旧的“房东必须使用 Web 后台”提示与当前实现冲突。** 当前代码已提供房东移动端工作台和路由；`webAdminRequired` 仍保留“房东账号暂不进入移动端工作台”的占位说明，而且不在当前角色白名单中，像是历史遗留入口/文案。
- **系统调试、普通智能门锁入口是占位。** 员工的系统调试页和租客端 `/lock` 仍为占位；这不影响租客端按租约开锁、开锁记录及管家门锁初始化等独立功能。

## 六、主要代码索引

| 内容         | 代码位置                                                                    |
| ---------- | ----------------------------------------------------------------------- |
| 角色定义       | `lib/features/auth/domain/entities/user_role.dart`                      |
| Tab 与路由白名单 | `lib/app/router/role_navigation_config.dart`                            |
| 房东/租客工作模式  | `lib/app/router/app_mode_controller.dart`                               |
| 路由注册与守卫    | `lib/app/router/app_router.dart`                                        |
| 租客个人中心入口   | `lib/features/profile/presentation/pages/profile_page.dart`             |
| 房东工作台      | `lib/features/landlord/presentation/pages/landlord_workbench_page.dart` |
| 员工工作台与门锁   | `lib/features/staff/workbench`、`lib/features/staff/lock_initial`        |
