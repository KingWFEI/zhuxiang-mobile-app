# 首页找房消息我的及详情页实现报告

## 1. 本次任务目标

在 `feature/add_main_page` 分支实现住享 App 首页、找房页、消息页、我的页、房屋详情页，并在现有登录/注册页面基础上接入 mock 登录、注册和退出登录逻辑。本次不接入真实后端、真实地图、真实开锁、支付、推送或通通锁 SDK。

## 2. 参考 UI 设计图路径

| 页面 | 本地路径 |
| --- | --- |
| 首页 | `C:\Users\king-wang\Desktop\租房系统开发\移动端UI设计图\首页\home.png` |
| 找房页 | `C:\Users\king-wang\Desktop\租房系统开发\移动端UI设计图\findhome.png` |
| 消息页 | `C:\Users\king-wang\Desktop\租房系统开发\移动端UI设计图\messsage.png` |
| 我的页 | `C:\Users\king-wang\Desktop\租房系统开发\移动端UI设计图\my.png` |
| 房屋详情页 | `C:\Users\king-wang\Desktop\租房系统开发\移动端UI设计图\detail.png` |

## 3. Git 分支信息

| 项目 | 内容 |
| --- | --- |
| 开发分支 | `feature/add_main_page` |
| 基础分支 | `develop` |
| 提交信息 | `feat: 实现首页找房消息我的及详情页` |

## 4. 新增文件列表

| 文件路径 | 类型 | 说明 |
| --- | --- | --- |
| `lib/features/home/presentation/pages/home_page.dart` | 新增 | 首页 UI |
| `lib/features/home/presentation/widgets/home_search_bar.dart` | 新增 | 首页/找房页搜索条 |
| `lib/features/home/presentation/widgets/home_service_entry.dart` | 新增 | 首页服务入口组件 |
| `lib/features/house/domain/entities/house.dart` | 新增 | 房源实体 |
| `lib/features/house/data/datasources/mock_house_datasource.dart` | 新增 | 房源 mock 数据源 |
| `lib/features/house/presentation/pages/find_home_page.dart` | 新增 | 找房列表页 |
| `lib/features/house/presentation/pages/house_detail_page.dart` | 新增 | 房屋详情页 |
| `lib/features/house/presentation/widgets/house_card.dart` | 新增 | 房源卡片组件 |
| `lib/features/house/presentation/widgets/house_image_placeholder.dart` | 新增 | 房源图片占位组件 |
| `lib/features/message/presentation/pages/message_page.dart` | 新增 | 消息页 |
| `lib/features/message/presentation/widgets/message_item.dart` | 新增 | 消息列表项组件 |
| `lib/features/profile/presentation/pages/profile_page.dart` | 新增 | 我的页 |
| `lib/features/profile/presentation/widgets/profile_menu_tile.dart` | 新增 | 我的页服务入口组件 |
| `lib/features/auth/domain/entities/auth_user.dart` | 新增 | mock 认证用户实体 |
| `lib/features/auth/data/models/auth_user_model.dart` | 新增 | mock 认证用户模型 |
| `lib/features/auth/data/datasources/mock_auth_datasource.dart` | 新增 | mock 登录注册数据源 |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | 新增 | 认证仓储实现 |
| `lib/features/auth/domain/repositories/auth_repository.dart` | 新增 | 认证仓储接口 |
| `lib/features/auth/domain/usecases/login_usecase.dart` | 新增 | 登录用例 |
| `lib/features/auth/domain/usecases/register_usecase.dart` | 新增 | 注册用例 |
| `lib/features/auth/domain/usecases/logout_usecase.dart` | 新增 | 退出登录用例 |
| `lib/features/auth/presentation/providers/auth_controller.dart` | 新增 | Riverpod 认证状态控制器 |
| `lib/mock/message_mock.dart` | 新增 | 消息 mock 数据 |
| `docs/MAIN_PAGE_IMPLEMENTATION_REPORT.md` | 新增 | 本次实现说明文档 |

## 5. 修改文件列表

| 文件路径 | 类型 | 说明 |
| --- | --- | --- |
| `lib/app/router/app_router.dart` | 修改 | 接入首页、找房页、消息页、我的页、详情页 |
| `lib/app/router/app_shell.dart` | 修改 | 底部导航调整为贴近设计图的四 tab + 中间开锁按钮 |
| `lib/app/router/route_paths.dart` | 修改 | 找房 tab 路径改为 `/houses`，保留兼容 houseList 路由 |
| `lib/features/auth/presentation/pages/login_page.dart` | 修改 | 登录页接入 mock 认证逻辑 |
| `lib/features/auth/presentation/pages/register_page.dart` | 修改 | 注册页接入 mock 注册逻辑 |
| `test/widget_test.dart` | 修改 | 适配 Riverpod 和真实主页面 |

## 6. 首页实现说明

首页包含品牌区、通知/扫码入口、欢迎语、搜索框、我的家智能门锁卡、推荐房源和便捷服务。房源推荐复用 mock 房源数据，点击卡片通过 `go_router` 进入房屋详情页。门锁相关按钮仅展示 UI 和 mock 提示。

## 7. 找房页实现说明

找房页包含品牌头部、搜索框、区域/租金/户型/更多筛选入口、推荐横幅和房源列表。房源卡片展示封面占位、标题、标签、户型面积楼层、地铁信息、租金和收藏状态，点击进入详情页。

## 8. 消息页实现说明

消息页包含消息中心标题、分类筛选和消息列表。mock 数据覆盖预约消息、租约消息、账单消息、开锁消息、报修消息、系统通知，并展示未读数量红点。

## 9. 我的页实现说明

我的页根据登录状态展示不同内容。未登录时展示登录入口；已登录时展示头像、昵称、手机号、安心住户状态、当前居住房屋、门锁状态、常用服务、更多服务和退出登录按钮。

## 10. 房屋详情页实现说明

房屋详情页包含顶部图片占位、返回/分享/收藏按钮、价格、标题、地址、小区、标签、房屋信息、设施配置、房东信息、智能门锁说明、房源描述和底部操作栏。预约看房、立即租住、联系房东等按钮暂时只展示 mock 提示。

## 11. 登录注册 mock 逻辑说明

mock 认证逻辑位于 `lib/features/auth/`，调用链为页面 -> `AuthController` -> usecase -> `AuthRepository` -> `MockAuthDatasource`。默认测试账号为手机号 `13800138000`、验证码 `123456`。注册成功会将用户写入内存 mock 数据源并跳转登录页。

## 12. 退出登录逻辑说明

我的页面点击“退出登录”后弹出确认框，确认后调用 `AuthController.logout()`，该方法通过 `LogoutUseCase` 调用仓储和 datasource 清除内存登录状态，然后跳转到登录页。

## 13. 路由修改说明

主页面继续使用 `StatefulShellRoute.indexedStack`。四个主 tab 为首页 `/home`、找房 `/houses`、消息 `/messages`、我的 `/profile`。房屋详情页通过 `/houses/:houseId` 接收房屋 id。旧 `houseList` 路由保留为兼容入口并重定向到 `/houses`。

## 14. Mock 数据说明

房源 mock 数据放在 `MockHouseDatasource`，包含 id、标题、封面占位、位置、小区、租金、户型、面积、楼层、朝向、标签、设施、描述、智能门锁支持状态、收藏状态、地铁信息、装修和入住时间。消息 mock 数据放在 `lib/mock/message_mock.dart`。

## 15. 当前未实现内容

- 真实登录、注册、短信验证码、Token 持久化
- 真实房源接口、图片接口、收藏接口
- 真实地图 SDK 和筛选查询
- 真实预约看房、立即租住、合同、账单、支付
- 蓝牙开锁、远程开锁、通通锁 SDK
- 推送通知、客服聊天、图片上传
- 正式房源图片、头像、门锁和运营插画切图

## 16. 后续需要接入的真实接口

| 接口能力 | 说明 |
| --- | --- |
| 登录/注册/退出 | 用户认证与 token 管理 |
| 房源列表/详情 | 获取真实房源、图片、价格和状态 |
| 收藏 | 收藏/取消收藏房源 |
| 消息中心 | 获取通知、未读数量和消息分类 |
| 用户中心 | 获取个人资料、当前租约、账单、门锁 |
| 预约/租住 | 预约看房、立即租住、合同流程 |
| 门锁服务 | 蓝牙开锁、远程开锁、开门记录 |

## 17. 执行过的命令

```bash
git status
git checkout develop
git pull origin develop
git checkout -b feature/add_main_page
dart format lib test
flutter analyze
flutter test
```

## 18. `flutter analyze` 结果

```text
No issues found!
```

## 19. `flutter test` 结果

```text
All tests passed!
```

## 20. 是否存在未解决问题

当前没有 analyzer error 或 test failure。已知限制是页面内图片、头像、门锁和建筑插画均为 Flutter 原生占位实现，后续需要替换为正式切图或远程图片资源。
