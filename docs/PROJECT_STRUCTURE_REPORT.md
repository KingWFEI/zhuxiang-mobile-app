# 住享 Flutter 项目基础结构搭建报告

## 1. 本次任务目标

本次将默认 `flutter create` 项目整理为企业级租房 App 的基础架构。范围仅包含目录分层、路由、主题、环境配置、网络封装、本地存储、错误模型、通用组件、Mock 数据、README 和结构说明文档，不实现真实业务页面、不接真实接口、不修改平台目录配置。

## 2. 本次新增依赖

### dependencies

| 依赖 | 版本约束 | 作用 |
| --- | --- | --- |
| go_router | ^17.3.0 | 路由管理 |
| dio | ^5.9.2 | 网络请求 |
| flutter_riverpod | ^2.6.1 | 状态管理基础能力 |
| flutter_secure_storage | ^10.3.1 | Token 安全存储 |
| shared_preferences | ^2.5.5 | 本地轻量配置 |
| freezed_annotation | ^3.1.0 | 不可变模型扩展预留 |
| json_annotation | ^4.9.0 | JSON 序列化注解预留 |
| equatable | ^2.0.8 | 实体比较能力 |
| intl | ^0.20.2 | 日期格式化 |

### dev_dependencies

| 依赖 | 版本约束 | 作用 |
| --- | --- | --- |
| build_runner | ^2.4.15 | 代码生成入口 |
| freezed | ^3.0.0 | 不可变模型代码生成预留 |
| json_serializable | ^6.9.5 | JSON 序列化代码生成预留 |
| flutter_lints | ^6.0.0 | 继续使用 Flutter 默认 lint |

说明：初次自动解析到 `flutter_riverpod 3.x` 与当前 `flutter_test`、`json_serializable` 组合存在依赖冲突，因此改用稳定兼容的 `flutter_riverpod 2.6.1`，并将 `json_annotation` 固定在 `^4.9.0`。

## 3. 本次新增目录结构

```text
lib/
├── app/
│   ├── config/
│   ├── router/
│   └── theme/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── permissions/
│   ├── storage/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── appointment/
│   ├── auth/
│   ├── bill/
│   ├── customer_service/
│   ├── home/
│   ├── house/
│   ├── lease/
│   ├── lock/
│   ├── message/
│   ├── profile/
│   ├── real_name_auth/
│   ├── repair/
│   └── search/
├── mock/
└── shared/
    ├── extensions/
    ├── models/
    └── widgets/
```

每个 feature 目录下均预留 `data`、`domain`、`presentation` 三层，并使用 `.gitkeep` 保持空目录可进入版本控制。

## 4. 本次新增文件列表

| 文件路径 | 类型 | 作用 |
| --- | --- | --- |
| lib/app/app.dart | 新增 | App 根组件，配置 `MaterialApp.router` |
| lib/app/config/app_env.dart | 新增 | 定义 dev、staging、prod 环境 |
| lib/app/config/app_config.dart | 新增 | 根据环境提供 baseUrl 和超时配置 |
| lib/app/router/app_router.dart | 新增 | GoRouter 路由配置 |
| lib/app/router/route_names.dart | 新增 | 路由名称常量 |
| lib/app/router/route_paths.dart | 新增 | 路由路径常量 |
| lib/app/theme/app_colors.dart | 新增 | App 颜色系统 |
| lib/app/theme/app_radius.dart | 新增 | 圆角规格 |
| lib/app/theme/app_shadows.dart | 新增 | 阴影规格 |
| lib/app/theme/app_spacing.dart | 新增 | 间距规格 |
| lib/app/theme/app_text_styles.dart | 新增 | 文本样式规格 |
| lib/app/theme/app_theme.dart | 新增 | Material 3 浅色主题 |
| lib/core/constants/app_constants.dart | 新增 | App 通用常量 |
| lib/core/constants/storage_keys.dart | 新增 | 本地存储 key 常量 |
| lib/core/errors/app_error.dart | 新增 | App 级错误模型 |
| lib/core/errors/failure.dart | 新增 | 业务失败模型 |
| lib/core/network/api_client.dart | 新增 | Dio 网络请求封装 |
| lib/core/network/api_endpoints.dart | 新增 | API 路径常量 |
| lib/core/network/api_exception.dart | 新增 | 网络异常模型 |
| lib/core/network/api_interceptor.dart | 新增 | Token、401、日志拦截预留 |
| lib/core/network/api_result.dart | 新增 | 统一接口返回结果模型 |
| lib/core/permissions/permission_service.dart | 新增 | 权限服务占位 |
| lib/core/storage/local_storage.dart | 新增 | SharedPreferences 封装 |
| lib/core/storage/secure_token_storage.dart | 新增 | flutter_secure_storage Token 封装 |
| lib/core/storage/storage_service.dart | 新增 | 本地存储统一初始化入口 |
| lib/core/utils/date_time_utils.dart | 新增 | 日期格式化工具 |
| lib/core/utils/logger.dart | 新增 | debug 日志封装 |
| lib/core/widgets/app_button.dart | 新增 | 通用按钮 |
| lib/core/widgets/app_empty_view.dart | 新增 | 空状态组件 |
| lib/core/widgets/app_error_view.dart | 新增 | 错误状态组件 |
| lib/core/widgets/app_loading_view.dart | 新增 | 加载状态组件 |
| lib/core/widgets/app_placeholder_page.dart | 新增 | 路由占位页 |
| lib/core/widgets/app_text_field.dart | 新增 | 通用输入框 |
| lib/shared/extensions/context_extensions.dart | 新增 | BuildContext 扩展 |
| lib/shared/extensions/string_extensions.dart | 新增 | String 扩展 |
| lib/shared/models/page_result.dart | 新增 | 分页结果模型 |
| lib/shared/widgets/section_header.dart | 新增 | 通用区块标题 |
| lib/mock/houses_mock.dart | 新增 | 房源 Mock 数据 |
| lib/mock/user_mock.dart | 新增 | 用户 Mock 数据 |
| lib/mock/lease_mock.dart | 新增 | 租约 Mock 数据 |
| lib/mock/bill_mock.dart | 新增 | 账单 Mock 数据 |
| lib/mock/lock_mock.dart | 新增 | 门锁 Mock 数据 |
| docs/PROJECT_STRUCTURE_REPORT.md | 新增 | 本次结构搭建报告 |
| lib/features/**/.gitkeep | 新增 | 保留 feature-first 空目录 |

## 5. 本次修改文件列表

| 文件路径 | 类型 | 作用 |
| --- | --- | --- |
| lib/main.dart | 修改 | 改为初始化配置、存储并启动 `ZhuxiangApp` |
| pubspec.yaml | 修改 | 添加架构基础依赖 |
| pubspec.lock | 修改 | 依赖解析后更新锁定版本 |
| README.md | 修改 | 更新项目说明、目录、命令、规范和阶段说明 |
| test/widget_test.dart | 修改 | 适配新的 App 根组件和启动占位页 |
| linux/flutter/generated_plugin_registrant.cc | 自动修改 | Flutter 工具为插件依赖生成 Linux 注册代码 |
| linux/flutter/generated_plugins.cmake | 自动修改 | Flutter 工具为插件依赖生成 Linux 插件列表 |
| macos/Flutter/GeneratedPluginRegistrant.swift | 自动修改 | Flutter 工具为插件依赖生成 macOS 注册代码 |
| windows/flutter/generated_plugin_registrant.cc | 自动修改 | Flutter 工具为插件依赖生成 Windows 注册代码 |
| windows/flutter/generated_plugins.cmake | 自动修改 | Flutter 工具为插件依赖生成 Windows 插件列表 |

## 6. 核心文件作用说明

- `lib/main.dart`：只负责 Flutter 绑定初始化、配置初始化、存储初始化和启动 App。
- `lib/app/app.dart`：承载 `MaterialApp.router`，接入主题和路由。
- `lib/app/router/app_router.dart`：集中声明当前所有占位路由。
- `lib/app/theme/app_theme.dart`：统一输出浅色 Material 3 主题，并配置 Button、Input、Card、AppBar。
- `lib/core/network/api_client.dart`：封装 Dio 的 get、post、put、delete 方法。
- `lib/core/storage/storage_service.dart`：统一初始化 SharedPreferences，并暴露本地存储入口。
- `lib/core/widgets/app_placeholder_page.dart`：为当前阶段的路由提供可跳转占位页。

## 7. 路由系统说明

路由使用 `go_router`。当前提供以下占位路由：

`splash`、`login`、`main`、`home`、`search`、`houseList`、`houseDetail`、`appointment`、`realNameAuth`、`profile`、`lease`、`bill`、`lock`、`repair`、`messageCenter`、`customerService`。

`route_names.dart` 管理路由名称，`route_paths.dart` 管理路径，`app_router.dart` 负责创建 `GoRouter`。占位页只用于验证基础跳转，不实现业务逻辑。

## 8. 主题系统说明

主题系统拆分为颜色、文字、间距、圆角、阴影和 ThemeData。当前使用浅色主题，主色为干净可信赖的蓝色，并配合绿色辅助色。业务页面后续应优先使用主题和规格文件，避免在 Widget 中散落硬编码样式。

## 9. 网络层封装说明

网络层基于 Dio：

- `ApiClient`：封装基础请求方法和异常转换。
- `ApiInterceptor`：预留 Token 注入、401 处理和 debug 日志。
- `ApiResult`：定义 success、failure 两种结果。
- `ApiException`：区分 timeout、unauthorized、server、network、unknown。
- `ApiEndpoints`：仅保存路径常量，不接真实接口。

## 10. 本地存储封装说明

- `SecureTokenStorage` 使用 `flutter_secure_storage` 保存、读取、清理 access token。
- `LocalStorage` 使用 `shared_preferences` 提供 setString、getString、remove。
- `StorageService` 作为统一初始化入口，便于后续扩展依赖注入。

## 11. Mock 数据说明

`lib/mock` 下提供少量 Map/List 数据，覆盖房源、用户、租约、账单、门锁。当前只用于后续页面调试预留，不包含业务计算逻辑。

## 12. 当前项目如何运行

```bash
flutter pub get
flutter run
```

启动后进入 `splash` 占位页，可通过按钮跳转到主框架占位页和其他占位模块。

## 13. 执行过的命令

```bash
flutter pub add go_router dio flutter_riverpod flutter_secure_storage shared_preferences freezed_annotation json_annotation equatable intl
flutter pub add --dev build_runner freezed json_serializable
flutter pub get
dart format lib test
flutter analyze
flutter test
```

说明：第二条自动添加 dev 依赖时曾因依赖版本冲突失败，随后手动调整 `pubspec.yaml` 版本约束并执行 `flutter pub get` 成功。`flutter pub get` 同时自动更新了 desktop 平台的 generated plugin registrant 文件，用于注册 `flutter_secure_storage`、`shared_preferences` 等插件；未手动修改平台包名或业务配置。

## 14. flutter analyze 结果

```text
No issues found! (ran in 17.0s)
```

## 15. 是否存在未解决问题

当前没有 analyzer error 或 test failure。已知说明：`AppConfig` 中 staging、prod 地址均为占位地址，不代表真实生产接口；当前路由页均为架构占位，不包含真实业务逻辑。

## 16. 下一步建议开发顺序

1. 明确接口契约、环境切换策略和错误码规范。
2. 建立登录与游客态的鉴权流程。
3. 实现首页、找房、筛选、房源详情基础页面。
4. 实现预约看房、实名认证、租约、账单闭环。
5. 在 SDK 和安全方案确认后接入智能门锁、蓝牙、远程开锁能力。
6. 补充 feature 层单元测试、Widget 测试和集成测试。
