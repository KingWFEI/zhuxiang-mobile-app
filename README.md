# 住享 Flutter App

住享是一个企业级租房 App 移动端项目。本仓库当前处于基础架构搭建阶段，只包含项目分层、路由、主题、网络、本地存储、通用模型、通用组件和 Mock 数据，不包含真实业务页面或接口联调。

## 技术栈

- Flutter / Dart
- go_router：路由管理，主页面底部导航使用 `StatefulShellRoute.indexedStack`
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

当前仅完成企业级 Flutter 项目基础结构搭建。主页面使用 indexedStack 底部导航保存 tab 状态，路由页均为占位页，网络地址为占位地址，未实现登录、房源、租约、账单、门锁、报修等真实业务逻辑。

## 后续开发计划

1. 完成设计规范和组件规范。
2. 建立真实 API 契约和数据模型。
3. 按 feature-first 顺序实现登录、首页、找房、房源详情。
4. 接入预约、实名认证、租约、账单等租住流程。
5. 在明确 SDK 方案后接入智能门锁能力。

# 分支提交标准流程

假设新功能分支叫：feature/add-search-page

1. 从最新 develop 创建分支
   git checkout develop
   git pull origin develop
   git checkout -b feature/add-search-page
2. 开发功能，提交代码
   写完代码后：
   git status
   git add .
   git commit -m "新增搜索页面"
3. 合并前同步最新 develop
   git fetch origin
   git merge origin/develop
   把别人已经合并进 develop 的最新代码，同步到你的 feature/add-search-page 分支里。

4. 如果没有冲突
   如果执行 git merge origin/develop 后提示类似：
   Already up to date.
   或者自动合并成功，没有冲突，那你不需要手动 git add . 和 git commit。
   直接推送：
   git push -u origin feature/add-search-page
   然后去 GitHub 创建 PR：feature/add-search-page → develop
5. 如果有冲突
   如果出现冲突，比如：
   CONFLICT (content): lib/app/router/app_router.dart
   Automatic merge failed; fix conflicts and then commit the result.
   你就需要手动解决冲突。
   解决完后执行：
   git add .
   git commit -m "合并最新develop并解决冲突"
   git push -u origin feature/add-search-page
   然后再去 GitHub 创建 PR：
   feature/add-search-page → develop

## 踩坑日记

### 场景：在错误的分支上提交了代码

某次提交 `729b7e6`（修改 md 中 git 提交流程规范）不小心提交到了 `feature/add_main_page` 分支上，而不是目标分支 `docs/update-git-workflow`。更麻烦的是，`feature/add_main_page` 已经被删除了。

切换到 `docs/update-git-workflow` 后，`git status` 显示没有任何未提交的修改（`nothing to commit`），因为改动已经以 commit 的形式存在于另一个分支的历史中，不会自动带到当前分支。

### 解决方法：用 cherry-pick 把 commit「搬运」过来

1. 先切到 develop 并拉取最新代码：

```bash
git checkout develop
git pull --ff-only origin develop
```

2. 基于 develop 重建目标分支：

```bash
git checkout -B docs/update-git-workflow develop
```

> `checkout -B` 会重置该分支指向 develop，相当于重新创建。

3. 把那个 commit 搬运到当前分支：

```bash
git cherry-pick 729b7e6
```

4. 推送到远程：

```bash
git push -u origin docs/update-git-workflow
```

### 一句话总结

**commit 提交到错误分支后，用 `git cherry-pick <commit-hash>` 把它复制到正确的分支。**
