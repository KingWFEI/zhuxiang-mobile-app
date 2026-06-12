import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HomeCategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  HomeCategoryTabsDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.background,
      elevation: overlapsContent ? 2 : 0,
      shadowColor: const Color(0x14000000),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant HomeCategoryTabsDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}
