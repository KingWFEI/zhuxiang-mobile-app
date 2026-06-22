import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/house_providers.dart';
import '../widgets/filter_bottom_sheet.dart';

/// 参照设计图实现的全屏房源筛选页。
class HouseFilterPage extends ConsumerStatefulWidget {
  const HouseFilterPage({super.key});

  @override
  ConsumerState<HouseFilterPage> createState() => _HouseFilterPageState();
}

class _HouseFilterPageState extends ConsumerState<HouseFilterPage> {
  late String _region;
  late String _rent;
  late String _roomType;
  String _area = '';
  String _orientation = '';
  String _floor = '';
  String _decoration = '';
  String _rentType = '';
  final Set<String> _features = <String>{};

  @override
  void initState() {
    super.initState();
    final current = ref.read(houseSearchProvider);
    _region = current.region;
    _rent = _rentFromState(current.minPrice, current.maxPrice);
    _roomType = current.roomType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      body: SafeArea(
        child: Column(
          children: [
            _FilterPageHeader(onClose: _closePage),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _FilterSection(
                    title: '区域',
                    value: _region,
                    options: const {
                      '': '不限',
                      'yubei': '渝北区',
                      'jiangbei': '江北区',
                      'yuzhong': '渝中区',
                      'more': '更多⌄',
                    },
                    onSelected: (value) => setState(() => _region = value),
                  ),
                  _FilterSection(
                    title: '租金',
                    unit: '（元/月）',
                    value: _rent,
                    options: const {
                      '': '不限',
                      '0-1000': '1000以下',
                      '1000-2000': '1000–2000',
                      '2000-3000': '2000–3000',
                      '3000-5000': '3000–5000',
                      '5000+': '5000以上',
                    },
                    onSelected: (value) => setState(() => _rent = value),
                  ),
                  _FilterSection(
                    title: '户型',
                    value: _roomType,
                    options: const {
                      '': '不限',
                      '1室0厅1卫': '一居',
                      '2室1厅1卫': '二居',
                      '3室2厅2卫': '三居',
                      '4+': '四居及以上',
                    },
                    onSelected: (value) => setState(() => _roomType = value),
                  ),
                  _FilterSection(
                    title: '面积',
                    unit: '（m²）',
                    value: _area,
                    options: const {
                      '': '不限',
                      '0-30': '30以下',
                      '30-50': '30–50',
                      '50-70': '50–70',
                      '70-90': '70–90',
                      '90+': '90以上',
                    },
                    onSelected: (value) => setState(() => _area = value),
                  ),
                  _FilterSection(
                    title: '朝向',
                    value: _orientation,
                    options: const {
                      '': '不限',
                      'south': '南',
                      'north': '北',
                      'east_south': '东南',
                      'west_south': '西南',
                      'east': '东',
                      'west': '西',
                    },
                    onSelected: (value) => setState(() => _orientation = value),
                  ),
                  _FilterSection(
                    title: '楼层',
                    value: _floor,
                    options: const {
                      '': '不限',
                      'low': '低楼层（1–6层）',
                      'middle': '中楼层（7–18层）',
                      'high': '高楼层（19层以上）',
                    },
                    onSelected: (value) => setState(() => _floor = value),
                  ),
                  _FilterSection(
                    title: '装修',
                    value: _decoration,
                    options: const {
                      '': '不限',
                      'rough': '毛坯',
                      'simple': '简装',
                      'fine': '精装',
                      'luxury': '豪华装',
                    },
                    onSelected: (value) => setState(() => _decoration = value),
                  ),
                  _FilterSection(
                    title: '租赁方式',
                    value: _rentType,
                    options: const {'': '不限', 'whole': '整租', 'shared': '合租'},
                    onSelected: (value) => setState(() => _rentType = value),
                  ),
                  _FeatureSection(
                    selected: _features,
                    onSelected: _toggleFeature,
                  ),
                ],
              ),
            ),
            _FilterActionBar(onReset: _reset, onConfirm: _confirm),
          ],
        ),
      ),
    );
  }

  /// 切换可多选的更多条件。
  void _toggleFeature(String feature) {
    setState(() {
      if (!_features.add(feature)) _features.remove(feature);
    });
  }

  /// 重置全部筛选条件。
  void _reset() {
    setState(() {
      _region = '';
      _rent = '';
      _roomType = '';
      _area = '';
      _orientation = '';
      _floor = '';
      _decoration = '';
      _rentType = '';
      _features.clear();
    });
  }

  /// 将当前服务支持的筛选字段返回调用页面。
  void _confirm() {
    final prices = _priceRange(_rent);
    context.pop(
      HouseFilterSelection(
        region: _region == 'more' ? '' : _region,
        minPrice: prices.$1,
        maxPrice: prices.$2,
        roomType: _roomType == '4+' ? '' : _roomType,
        sort: ref.read(houseSearchProvider).sort,
      ),
    );
  }

  void _closePage() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.search);
    }
  }

  String _rentFromState(int minPrice, int maxPrice) {
    if (minPrice == 0 && maxPrice == 100000) return '0-1000';
    if (minPrice == 100000 && maxPrice == 200000) return '1000-2000';
    if (minPrice == 200000 && maxPrice == 300000) return '2000-3000';
    if (minPrice == 300000 && maxPrice == 500000) return '3000-5000';
    if (minPrice == 500000 && maxPrice == 0) return '5000+';
    return '';
  }

  (int, int) _priceRange(String value) {
    return switch (value) {
      '0-1000' => (0, 100000),
      '1000-2000' => (100000, 200000),
      '2000-3000' => (200000, 300000),
      '3000-5000' => (300000, 500000),
      '5000+' => (500000, 0),
      _ => (0, 0),
    };
  }
}

class _FilterPageHeader extends StatelessWidget {
  const _FilterPageHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            '筛选房源',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Positioned(
            left: AppSpacing.sm,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 26),
            ),
          ),
          const Positioned(
            right: AppSpacing.lg,
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppColors.primary),
                SizedBox(width: AppSpacing.xs),
                Text(
                  '当前定位',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
    this.unit,
  });

  final String title;
  final String? unit;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: title,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
              children: [
                if (unit != null)
                  TextSpan(text: ' $unit', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: options.entries
                .map(
                  (option) => _FilterChoice(
                    label: option.value,
                    selected: value == option.key,
                    outlined: option.key.isEmpty,
                    onTap: () => onSelected(option.key),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.outlined,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 76, minHeight: 38),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected || outlined
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.selected, required this.onSelected});

  final Set<String> selected;
  final ValueChanged<String> onSelected;

  static const _features = <(String, IconData)>[
    ('近地铁', Icons.directions_subway_rounded),
    ('可短租', Icons.calendar_month_rounded),
    ('可养宠物', Icons.pets_rounded),
    ('有电梯', Icons.elevator_rounded),
    ('随时看房', Icons.schedule_rounded),
    ('智能门锁', Icons.lock_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('更多', style: AppTextStyles.titleMedium.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _features
                    .map(
                      (feature) => SizedBox(
                        width: width,
                        child: _FilterChoice(
                          label: feature.$1,
                          icon: feature.$2,
                          selected: selected.contains(feature.$1),
                          outlined: false,
                          onTap: () => onSelected(feature.$1),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterActionBar extends StatelessWidget {
  const _FilterActionBar({required this.onReset, required this.onConfirm});

  final VoidCallback onReset;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReset,
                child: const Text('重置'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onConfirm,
                child: const Text('查看房源（1286套）'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
