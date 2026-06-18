import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomTabBar(
        currentIndex: navigationShell.currentIndex,
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
  const _BottomTabBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(color: AppColors.surface),
        child: Row(
          children: [
            Expanded(
              child: _TabItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: '首页',
                isSelected: currentIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _TabItem(
                icon: Icons.search,
                selectedIcon: Icons.manage_search,
                label: '找房',
                isSelected: currentIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
            Expanded(
              child: _TabItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: '消息',
                isSelected: currentIndex == 2,
                showBadge: true,
                onTap: () => onSelected(2),
              ),
            ),
            Expanded(
              child: _TabItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: '我的',
                isSelected: currentIndex == 3,
                onTap: () => onSelected(3),
              ),
            ),
          ],
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
