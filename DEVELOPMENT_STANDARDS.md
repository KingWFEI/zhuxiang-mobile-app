# 住享 App 项目开发规范

## 一、项目概览

| 项目     | 说明                                        |
| -------- | ------------------------------------------- |
| 框架     | Flutter 3.x + Dart                          |
| 状态管理 | flutter_riverpod                            |
| 路由     | go_router（命名路由 + Shell）               |
| 网络层   | Dio（自封装 ApiClient）                     |
| 本地存储 | flutter_secure_storage + shared_preferences |
| 架构模式 | Clean Architecture（按 Feature 分层）       |

---

## 二、目录结构

```
lib/
├── main.dart                          # 入口：初始化配置 → runApp
├── app/
│   ├── app.dart                       # MaterialApp.router 根组件
│   ├── config/
│   │   ├── app_config.dart            # 全局配置（baseUrl、timeout）
│   │   └── app_env.dart               # 环境枚举（dev/staging/prod）
│   ├── launch/
│   │   └── app_loading_page.dart      # 启动页（恢复会话 + 路由分发）
│   ├── router/
│   │   ├── route_names.dart           # 路由名称常量
│   │   ├── route_paths.dart           # 路由路径常量
│   │   ├── app_router.dart            # GoRouter 配置 + 路由守卫
│   │   ├── app_shell.dart             # 底部 Tab 壳（StatefulShellRoute）
│   │   └── role_navigation_config.dart # 角色导航配置 + 权限控制
│   └── theme/
│       ├── app_colors.dart            # 颜色常量
│       ├── app_spacing.dart           # 间距常量
│       ├── app_radius.dart            # 圆角常量
│       ├── app_shadows.dart           # 阴影常量
│       ├── app_text_styles.dart       # 文字样式常量
│       └── app_theme.dart             # ThemeData 全局主题
├── core/
│   ├── constants/
│   │   ├── storage_keys.dart          # 本地存储 Key 常量
│   │   └── app_constants.dart         # 通用业务常量
│   ├── network/
│   │   ├── api_client.dart            # 统一 HTTP 客户端（封装 Dio）
│   │   ├── api_client_provider.dart   # ApiClient 的 Riverpod Provider
│   │   ├── api_interceptor.dart       # 请求拦截器（自动附加 Token）
│   │   ├── api_result.dart            # ApiResult 密封类（Success/Failure）
│   │   ├── api_exception.dart         # 自定义异常类型
│   │   └── api_endpoints.dart         # 后端接口路径常量
│   ├── storage/
│   │   ├── storage_service.dart       # 存储服务入口
│   │   ├── token_storage.dart         # Token 持久化
│   │   ├── guest_mode_storage.dart    # 游客模式标记
│   │   └── local_storage.dart         # SharedPreferences 封装
│   ├── widgets/                       # 通用 UI 组件
│   │   ├── app_toast.dart             # 底部轻提示
│   │   ├── app_button.dart            # 通用按钮
│   │   ├── app_text_field.dart        # 通用输入框
│   │   ├── app_empty_view.dart        # 空状态视图
│   │   ├── app_error_view.dart        # 错误状态视图
│   │   ├── app_loading_view.dart      # 加载状态视图
│   │   └── app_placeholder_page.dart  # 占位页面
│   ├── utils/
│   │   ├── logger.dart                # 日志工具
│   │   └── date_time_utils.dart       # 日期时间工具
│   ├── errors/                        # 错误处理
│   └── permissions/                   # 权限服务
├── features/
│   ├── {feature_name}/                # 按业务功能划分
│   │   ├── domain/
│   │   │   └── entities/              # 领域实体（纯 Dart 对象）
│   │   ├── data/
│   │   │   ├── models/                # 数据模型（含序列化）
│   │   │   ├── services/              # API 调用服务
│   │   │   └── providers/             # Riverpod Provider 定义
│   │   ├── application/               # 状态控制器（StateNotifier）
│   │   └── presentation/
│   │       ├── pages/                 # 页面级组件
│   │       └── widgets/               # 页面内私有组件
├── shared/
│   ├── extensions/                    # 通用扩展方法
│   ├── models/                        # 跨 Feature 共享的 Model
│   └── widgets/                       # 跨 Feature 共享的 Widget
└── mock/                              # Mock 数据
```

---

## 三、新增页面时需查看/修改的文件清单

按操作顺序排列：

### 3.1 必须查看（了解全局配置）

| 顺序 | 文件                                   | 用途                             |
| ---- | -------------------------------------- | -------------------------------- |
| 1    | `lib/app/theme/app_colors.dart`        | 获取可用颜色常量                 |
| 2    | `lib/app/theme/app_spacing.dart`       | 获取可用间距常量                 |
| 3    | `lib/app/theme/app_radius.dart`        | 获取可用圆角常量                 |
| 4    | `lib/app/theme/app_shadows.dart`       | 获取可用阴影常量                 |
| 5    | `lib/app/theme/app_text_styles.dart`   | 获取可用文字样式                 |
| 6    | `lib/core/widgets/`                    | 查看已有通用组件，避免重复造轮子 |
| 7    | `lib/core/network/api_endpoints.dart`  | 查看已有接口路径                 |
| 8    | `lib/core/constants/storage_keys.dart` | 如需本地存储，查看已有 Key       |

### 3.2 必须修改（注册路由）

| 顺序 | 文件                                         | 操作                                                             |
| ---- | -------------------------------------------- | ---------------------------------------------------------------- |
| 1    | `lib/app/router/route_names.dart`            | 添加路由名称常量                                                 |
| 2    | `lib/app/router/route_paths.dart`            | 添加路由路径常量                                                 |
| 3    | `lib/app/router/app_router.dart`             | 在 `_tenantStandaloneRoutes()` 中注册 `GoRoute`，同时添加 import |
| 4    | `lib/app/router/role_navigation_config.dart` | 如新页面是租户端页面，需加入 `tenant.allowedRouteNames`          |

### 3.3 按需修改

| 文件                                         | 场景               |
| -------------------------------------------- | ------------------ |
| `lib/core/network/api_endpoints.dart`        | 新的接口路径前缀   |
| `lib/app/theme/app_theme.dart`               | 全局组件样式调整   |
| `lib/app/router/app_shell.dart`              | 新增底部 Tab       |
| `lib/app/router/role_navigation_config.dart` | 新增角色或调整权限 |
| `lib/core/constants/storage_keys.dart`       | 新增本地存储 Key   |

---

## 四、Feature 内部开发规范

### 4.1 目录层级（由简到繁）

项目中的 Feature 根据复杂度不同，目录层级也不同：

**简单场景**（如 profile）—— 只有 Service + Provider + Page：

```
profile/
├── data/
│   ├── models/profile_models.dart
│   ├── services/profile_service.dart
│   └── providers/profile_providers.dart
└── presentation/
    ├── pages/
    │   ├── profile_page.dart
    │   └── profile_edit_page.dart
    └── widgets/profile_menu_tile.dart
```

**复杂场景**（如 repair）—— 完整 Clean Architecture：

```
repair/
├── domain/
│   └── entities/repair_order.dart          # 领域实体（不可变 + copyWith）
├── data/
│   ├── models/repair_order_model.dart       # 数据模型（含 fromJson/toEntity）
│   ├── services/repair_service.dart         # API 调用 + Mock 降级
│   └── providers/repair_providers.dart      # Riverpod Provider
├── application/
│   └── repair_controller.dart               # StateNotifier 控制器
└── presentation/
    ├── pages/                               # 页面
    └── widgets/                             # 页面内组件
```

### 4.2 文件命名

| 类型     | 命名规则                  | 示例                     |
| -------- | ------------------------- | ------------------------ |
| 页面     | `{name}_page.dart`        | `profile_edit_page.dart` |
| 服务     | `{name}_service.dart`     | `profile_service.dart`   |
| 模型     | `{name}_models.dart`      | `profile_models.dart`    |
| Provider | `{name}_providers.dart`   | `profile_providers.dart` |
| 控制器   | `{name}_controller.dart`  | `repair_controller.dart` |
| 实体     | `{name}.dart`             | `repair_order.dart`      |
| 组件     | `{name}_widget_name.dart` | `home_search_bar.dart`   |

### 4.3 类命名

| 类型           | 规则                         | 示例                              |
| -------------- | ---------------------------- | --------------------------------- |
| 页面           | `{Name}Page`                 | `ProfileEditPage`                 |
| 页面内私有组件 | `_{Name}`                    | `_UserInfoCard`                   |
| 服务           | `{Name}Service`              | `ProfileService`                  |
| 模型           | `{Name}Model` 或业务名       | `CurrentHome`, `RepairOrderModel` |
| 控制器         | `{Name}Controller`           | `RepairController`                |
| 状态           | `{Name}State`                | `RepairState`                     |
| Provider 变量  | `{name}Provider` (camelCase) | `profileServiceProvider`          |

---

## 五、页面编写规范

### 5.1 页面基础结构

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 简单页面：使用 ConsumerWidget
class XxxPage extends ConsumerWidget {
  const XxxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,  // 统一背景色
      appBar: AppBar(title: const Text('标题')),
      body: ...,                              // 内容
    );
  }
}

// 有交互状态：使用 ConsumerStatefulWidget
class XxxPage extends ConsumerStatefulWidget {
  const XxxPage({super.key});

  @override
  ConsumerState<XxxPage> createState() => _XxxPageState();
}

class _XxxPageState extends ConsumerState<XxxPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

### 5.2 样式使用

**必须**使用主题系统定义的常量，禁止硬编码：

```dart
// ✓ 正确
color: AppColors.textPrimary
padding: const EdgeInsets.all(AppSpacing.lg)
borderRadius: BorderRadius.circular(AppRadius.xl)
style: AppTextStyles.bodyLarge
boxShadow: AppShadows.card

// ✗ 错误
color: Color(0xFF1F2937)
padding: const EdgeInsets.all(16)
borderRadius: BorderRadius.circular(12)
```

### 5.3 数据加载模式

使用 `ref.watch(xxxProvider)` + AsyncValue 的三态处理：

```dart
final dataAsync = ref.watch(someProvider);

return dataAsync.when(
  loading: () => const _XxxSkeleton(),
  error: (error, _) => _XxxErrorView(message: error.toString(), onRetry: () => ref.invalidate(someProvider)),
  data: (data) => _buildContent(data),
);
```

### 5.4 路由导航

```dart
// push 新页面（可返回）
context.pushNamed(RouteNames.profileEdit);

// go 替换当前栈（不可返回，如登录后）
context.goNamed(RouteNames.home);

// 带路参
context.pushNamed(RouteNames.houseDetail, pathParameters: {'houseId': id});

// 带查询参数
context.goNamed(RouteNames.houseSearchResult, queryParameters: {'keyword': keyword});
```

### 5.5 用户反馈

统一使用 `AppToast` 替代 `ScaffoldMessenger.showSnackBar`：

```dart
import '../../../../core/widgets/app_toast.dart';

AppToast.show(context, '操作成功', type: AppToastType.success);
AppToast.show(context, '操作失败', type: AppToastType.error);
AppToast.show(context, '普通提示', type: AppToastType.normal);  // 默认
```

### 5.6 私有组件拆分

页面内大块 UI 拆成私有 Widget，放在同一文件底部：

```dart
// 在页面类外面
class _XxxHeader extends StatelessWidget { ... }
class _XxxSkeleton extends StatefulWidget { ... }
```

可复用的组件提取到 `presentation/widgets/` 目录下作为独立文件。

---

## 六、Service 层编写规范

### 6.1 基本结构

```dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class XxxService {
  const XxxService(this.apiClient);
  final ApiClient apiClient;

  Future<XxxData> fetchXxx() async {
    final result = await apiClient.get('/xxx');
    return result.when(
      success: (response) {
        final body = response.data as Map<String, dynamic>;
        // 校验 code 并解析 data
        return XxxData.fromJson(body['data']);
      },
      failure: (message, error) {
        throw error is ApiException
            ? error
            : ApiException(type: ApiExceptionType.unknown, message: message, cause: error);
      },
    );
  }
}
```

### 6.2 Provider 注册

```dart
final xxxServiceProvider = Provider<XxxService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return XxxService(apiClient);
});

final xxxDataProvider = FutureProvider<XxxData>((ref) {
  final service = ref.watch(xxxServiceProvider);
  return service.fetchXxx();
});
```

---

## 七、网络层规范

### 7.1 统一使用 ApiClient

所有 HTTP 请求必须通过 `ApiClient` 发起（经由 Dio + ApiInterceptor），**禁止**直接 new Dio 或使用第三方 HTTP 库。

### 7.2 异常处理

网络异常由 `ApiClient._mapDioException()` 统一映射为 `ApiException` 枚举类型：

| 类型           | 含义               |
| -------------- | ------------------ |
| `timeout`      | 连接/接收/发送超时 |
| `network`      | 无网络连接         |
| `unauthorized` | 401 未授权         |
| `server`       | 5xx 服务端错误     |
| `unknown`      | 其他未知错误       |

### 7.3 Token 自动注入

`ApiInterceptor` 在每次请求前自动从 `TokenStorage` 读取 accessToken 并附加到 `Authorization` 头。Service 层无需手动处理。

---

## 八、本地存储规范

### 8.1 Key 管理

所有存储 Key 统一定义在 `lib/core/constants/storage_keys.dart` 中：

```dart
class StorageKeys {
  const StorageKeys._();
  static const someKey = 'some_key';
}
```

### 8.2 使用方式

- **Token/敏感数据**：通过 `StorageService.tokenStorage`
- **游客模式**：通过 `StorageService.guestModeStorage`
- **普通 KV 数据**：通过 `StorageService.localStorage`

---

## 九、命名通用规则

| 项目           | 规则                                  |
| -------------- | ------------------------------------- |
| 文件名         | `snake_case.dart`                     |
| 类名           | `PascalCase`                          |
| 变量/方法      | `camelCase`                           |
| 常量           | `camelCase` 或 `SCREAMING_SNAKE_CASE` |
| 私有成员       | 前缀 `_`                              |
| 页面内私有组件 | `_{ComponentName}`                    |
| Provider 变量  | `{name}Provider`                      |
| 页面文件       | `{name}_page.dart`                    |

---

## 十、禁止事项

1. **禁止**硬编码颜色/间距/字号/圆角 —— 必须用 AppColors / AppSpacing / AppTextStyles / AppRadius
2. **禁止**使用 `ScaffoldMessenger.showSnackBar` —— 用 `AppToast.show`
3. **禁止**在 Service 外直接实例化 `Dio` —— 通过 `ref.watch(apiClientProvider)` 获取 `ApiClient`
4. **禁止**在 build 方法中调用 `ref.read(xxx.notifier).xxx()` —— 读状态用 `ref.watch`，改状态放在事件回调里用 `ref.read`
5. **禁止**在 `domain/entities` 中引入 Flutter 依赖 —— 实体必须是纯 Dart
6. **禁止**新增页面的路由路径直接硬编码字符串 —— 必须经过 `RoutePaths` / `RouteNames`
7. **禁止**随意引入第三方库 —— 能用 Flutter 原生能力的就不要加依赖
