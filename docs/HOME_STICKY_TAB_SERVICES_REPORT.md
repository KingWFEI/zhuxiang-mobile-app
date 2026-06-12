# 首页便捷服务与分类吸顶实现报告

## 1. 调整目标

本次调整恢复首页“便捷服务”模块，并将首页滚动区域重构为统一的 Sliver
结构。顶部 Header 保持固定，便捷服务正常参与滚动，分类 Tab 到达 Header
下方后吸顶，房源瀑布流继续滚动。

智能锁大卡片、“我的家”、蓝牙开锁和远程开锁均未恢复。

## 2. 页面结构调整

首页当前结构如下：

```text
HomePage
├── 固定 Header
│   ├── Logo 与问候语
│   └── 搜索框
└── Expanded + CustomScrollView
    ├── SliverToBoxAdapter：便捷服务
    ├── SliverPersistentHeader：分类 Tab
    └── SliverMainAxisGroup
        ├── 分类说明
        └── 两列 SliverMasonryGrid 房源流
```

页面只有一个主滚动容器，不再嵌套 `ListView` 或 `CustomScrollView`。

## 3. 便捷服务组件

新增 `HomeConvenientServices`，使用白色圆角卡片、主题阴影和四列服务入口：

- 我的租约：跳转租约页面。
- 开门记录：当前显示“开门记录功能开发中”提示。
- 报修服务：跳转报修页面。
- 在线客服：跳转客服页面。

组件复用了现有 `HomeServiceEntry` 和主题颜色、间距、圆角、阴影常量。

## 4. 分类 Tab 吸顶

分类 Tab 放入 `SliverPersistentHeader`，设置 `pinned: true`。初始状态下，
便捷服务位于 Tab 上方并正常显示；向上滚动时便捷服务先离开屏幕，Tab 到达
Header 下方后固定，房源列表继续在其下方滚动。

向下滚动回顶部后，Tab 回到便捷服务下方，便捷服务重新显示。

## 5. 使用 SliverPersistentHeader 的原因

`SliverPersistentHeader` 能在同一个滚动坐标系中处理普通滚动与吸顶状态，
不需要监听滚动距离后手动切换定位，也不会引入多个滚动容器之间的手势冲突。
固定高度 delegate 同时保证吸顶前后 Tab 高度一致。

吸顶区域使用不透明页面背景，并在内容重叠时增加轻微阴影，避免房源文字透出。

## 6. 新增文件

- `lib/features/home/presentation/widgets/home_convenient_services.dart`
- `lib/features/home/presentation/widgets/home_category_tabs_delegate.dart`
- `docs/HOME_STICKY_TAB_SERVICES_REPORT.md`

## 7. 修改文件

- `lib/features/home/presentation/pages/home_page.dart`
- `test/widget_test.dart`

## 8. 当前未实现内容

- 开门记录独立页面和真实数据。
- 便捷服务接口数据。
- 广告卡片点击后的业务页面。
- 房源分类的后端筛选接口。

## 9. 后续建议

- 增加开门记录路由和独立页面。
- 将首页分类配置、广告和房源列表迁移到 provider 或 repository。
- 为各分类保存独立滚动位置。
- 接入真实图片缓存和分页加载。

## 10. flutter analyze

执行 `flutter analyze`，结果：通过，无问题。

## 11. flutter test

执行 `flutter test`，结果：全部测试通过。
