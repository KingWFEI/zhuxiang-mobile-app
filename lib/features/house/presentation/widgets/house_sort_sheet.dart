import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

const houseSortLabels = <String, String>{
  'default': '综合排序',
  'price_asc': '租金从低到高',
  'price_desc': '租金从高到低',
  'distance': '距离最近',
  'latest': '最新发布',
  'smart_lock': '智能门锁优先',
};

/// 展示首页和结果页共用的排序 BottomSheet。
Future<String?> showHouseSortSheet(
  BuildContext context, {
  required String selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HouseSortSheet(selectedValue: selectedValue),
  );
}

class _HouseSortSheet extends StatelessWidget {
  const _HouseSortSheet({required this.selectedValue});

  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '选择排序方式',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final option in houseSortLabels.entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(option.value),
              trailing: option.key == selectedValue
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(option.key),
            ),
        ],
      ),
    );
  }
}
