import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'role_navigation_config.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.tabs,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppTabConfig> tabs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomTabBar(
        currentIndex: navigationShell.currentIndex,
        tabs: tabs,
        onSelected: (index) {
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
    required this.onSelected,
  });

  final int currentIndex;
  final List<AppTabConfig> tabs;
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
        showBadge: tab.showBadge,
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
    this.showBadge = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool showBadge;
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
              if (showBadge)
                const Positioned(
                  right: -2,
                  top: -2,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: AppColors.error,
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
