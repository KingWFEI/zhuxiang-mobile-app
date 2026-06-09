# 住享 Flutter App

住享是一个企业级租房 App 移动端项目。本仓库当前处于基础架构搭建阶段，只包含项目分层、路由、主题、网络、本地存储、通用模型、通用组件和 Mock 数据，不包含真实业务页面或接口联调。

## 技术栈

- Flutter / Dart
- go_router：路由管理
- flutter_riverpod：状态管理基础能力
- dio：网络请求封装
- flutter_secure_storage：Token 安全存储
- shared_preferences：本地轻量配置
- freezed_annotation / json_annotation / equatable：模型扩展预留
- intl：日期格式化

## 目录结构

```text
lib/
├── app/                # App 入口组件、路由、主题、环境配置
├── core/               # 网络、存储、错误、权限、工具、基础组件
├── features/           # feature-first 业务模块目录
├── shared/             # 跨模块扩展、模型、共享组件
├── mock/               # 本地 Mock 数据
└── main.dart           # 初始化并启动 App
```

## 开发环境

- Flutter SDK：满足 `pubspec.yaml` 中的 SDK 约束
- Dart SDK：随 Flutter SDK 提供
- 推荐使用 Android Studio、VS Code 或支持 Flutter 的 IDE

## 常用命令

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## Git 分支规范

- 功能开发：`feature/<module-or-task>`
- 缺陷修复：`fix/<module-or-issue>`
- 基础设施：`chore/<task>`
- 发布准备：`release/<version>`

## Commit 规范

建议使用简洁的 Conventional Commits 风格：

- `feat: add house list foundation`
- `fix: correct router path`
- `chore: update dependencies`
- `docs: update project structure report`

## 当前阶段

当前仅完成企业级 Flutter 项目基础结构搭建。路由页均为占位页，网络地址为占位地址，未实现登录、房源、租约、账单、门锁、报修等真实业务逻辑。

## 后续开发计划

1. 完成设计规范和组件规范。
2. 建立真实 API 契约和数据模型。
3. 按 feature-first 顺序实现登录、首页、找房、房源详情。
4. 接入预约、实名认证、租约、账单等租住流程。
5. 在明确 SDK 方案后接入智能门锁能力。
