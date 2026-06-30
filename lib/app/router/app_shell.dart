import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/message/data/providers/message_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'role_navigation_config.dart';
import 'route_names.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.navigationShell,
    required this.tabs,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppTabConfig> tabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMessageTab = tabs.any(
      (tab) => tab.routeName == RouteNames.messageCenter,
    );
    final unreadMessageCount = hasMessageTab
        ? ref.watch(
            messageControllerProvider.select(
              (state) => state.unreadCounts.total,
            ),
          )
        : 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomTabBar(
        currentIndex: navigationShell.currentIndex,
        tabs: tabs,
        unreadMessageCount: unreadMessageCount,
        onSelected: (index) {
          if (tabs[index].routeName == RouteNames.messageCenter) {
            ref.read(messageControllerProvider.notifier).refreshUnreadCounts();
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({
    required this.currentIndex,
    required this.tabs,
    required this.unreadMessageCount,
    required this.onSelected,
  });

  final int currentIndex;
  final List<AppTabConfig> tabs;
  final int unreadMessageCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabItems = List.generate(tabs.length, (index) {
      final tab = tabs[index];
      return _TabItem(
        icon: tab.icon,
        selectedIcon: tab.selectedIcon,
        label: tab.label,
        isSelected: currentIndex == index,
        badgeCount: tab.showBadge ? unreadMessageCount : 0,
        onTap: () => onSelected(index),
      );
    });

    return SafeArea(
      top: false,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(color: AppColors.surface),
        child: tabs.length <= 4
            ? Row(
                children: [for (final item in tabItems) Expanded(child: item)],
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: tabItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 2),
                itemBuilder: (context, index) =>
                    SizedBox(width: 72, child: tabItems[index]),
              ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color, size: 18),
              if (badgeCount > 0)
                Positioned(
                  left: 12,
                  top: -7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bottomTextStyle.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
