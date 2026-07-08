import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

const _sheetTitleStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w800);

/// 展示区域选择 BottomSheet。
Future<String?> showRegionSheet(
  BuildContext context, {
  required String selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SingleSelectSheet(
      title: '选择区域',
      selectedValue: selectedValue,
      options: const {
        '': '不限',
        'yubei': '渝北区',
        'jiangbei': '江北区',
        'yuzhong': '渝中区',
      },
    ),
  );
}

/// 展示租金范围选择 BottomSheet。
Future<RangeValues?> showRentSheet(
  BuildContext context, {
  required int minPrice,
  required int maxPrice,
}) {
  return showModalBottomSheet<RangeValues>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RentSheet(minPrice: minPrice, maxPrice: maxPrice),
  );
}

/// 展示户型选择 BottomSheet。
Future<String?> showRoomSheet(
  BuildContext context, {
  required String selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SingleSelectSheet(
      title: '选择户型',
      selectedValue: selectedValue,
      options: const {
        '': '不限',
        '1室0厅1卫': '单间',
        '1室1厅1卫': '一室一厅',
        '2室1厅1卫': '两室一厅',
        '3室1厅1卫': '三室一厅',
      },
    ),
  );
}

/// 展示更多筛选条件 BottomSheet（含排序、电梯、朝向等）。
Future<HouseExtraFilterSelection?> showMoreFilterSheet(
  BuildContext context, {
  required String sort,
  required String decoration,
  required String orientation,
}) {
  return showModalBottomSheet<HouseExtraFilterSelection>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoreFilterSheet(
      sort: sort,
      decoration: decoration,
      orientation: orientation,
    ),
  );
}

class HouseExtraFilterSelection {
  const HouseExtraFilterSelection({
    required this.sort,
    required this.decoration,
    required this.orientation,
  });

  final String sort;
  final String decoration;
  final String orientation;
}

// ─── 通用单选列表 ──────────────────────────────────────────────

class _SingleSelectSheet extends StatelessWidget {
  const _SingleSelectSheet({
    required this.title,
    required this.selectedValue,
    required this.options,
  });

  final String title;
  final String selectedValue;
  final Map<String, String> options;

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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: _sheetTitleStyle),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final option in options.entries)
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

// ─── 租金范围 ──────────────────────────────────────────────────

class _RentSheet extends StatefulWidget {
  const _RentSheet({required this.minPrice, required this.maxPrice});

  final int minPrice;
  final int maxPrice;

  @override
  State<_RentSheet> createState() => _RentSheetState();
}

class _RentSheetState extends State<_RentSheet> {
  static const _maxValue = 1000000.0;

  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(
      widget.minPrice.toDouble(),
      widget.maxPrice > 0 ? widget.maxPrice.toDouble() : _maxValue,
    );
  }

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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('选择租金范围', style: _sheetTitleStyle),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_priceLabel(_values.start)} - ${_priceLabel(_values.end)}',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _values,
            min: 0,
            max: _maxValue,
            divisions: 100,
            labels: RangeLabels(
              _priceLabel(_values.start),
              _priceLabel(_values.end),
            ),
            onChanged: (value) => setState(() => _values = value),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_values),
              child: const Text('确定'),
            ),
          ),
        ],
      ),
    );
  }

  String _priceLabel(double value) {
    if (value >= _maxValue) return '不限';
    final v = value.round();
    if (v < 100) return '¥$v';
    return '¥${(v / 100).round()}元';
  }
}

// ─── 更多筛选 ──────────────────────────────────────────────────

class _MoreFilterSheet extends StatefulWidget {
  const _MoreFilterSheet({
    required this.sort,
    required this.decoration,
    required this.orientation,
  });

  final String sort;
  final String decoration;
  final String orientation;

  @override
  State<_MoreFilterSheet> createState() => _MoreFilterSheetState();
}

class _MoreFilterSheetState extends State<_MoreFilterSheet> {
  late String _sort;
  late String _decoration;
  late String _orientation;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _decoration = widget.decoration;
    _orientation = widget.orientation;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('更多筛选', style: _sheetTitleStyle),
            const SizedBox(height: AppSpacing.md),
            // 排序
            _SectionTitle('排序方式'),
            _ChoiceBar(
              value: _sort,
              options: const {
                'default': '综合',
                'price_asc': '低价优先',
                'price_desc': '高价优先',
                'latest': '最新',
                'smart_lock': '智能锁',
              },
              onSelected: (v) => setState(() => _sort = v),
            ),
            const SizedBox(height: AppSpacing.md),
            // 装修
            _SectionTitle('装修情况'),
            _ChoiceBar(
              value: _decoration,
              options: const {
                '': '不限',
                'jingzhuang': '精装',
                'jianzhuang': '简装',
                'haohua': '豪装',
              },
              onSelected: (v) => setState(() => _decoration = v),
            ),
            const SizedBox(height: AppSpacing.md),
            // 朝向
            _SectionTitle('房屋朝向'),
            _ChoiceBar(
              value: _orientation,
              options: const {
                '': '不限',
                'south': '朝南',
                'north': '朝北',
                'east': '朝东',
                'west': '朝西',
              },
              onSelected: (v) => setState(() => _orientation = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  HouseExtraFilterSelection(
                    sort: _sort,
                    decoration: _decoration,
                    orientation: _orientation,
                  ),
                ),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _ChoiceBar extends StatelessWidget {
  const _ChoiceBar({required this.value, required this.options, required this.onSelected});
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.entries.map((o) {
        return ChoiceChip(
          label: Text(o.value),
          selected: o.key == value,
          onSelected: (_) => onSelected(o.key),
        );
      }).toList(),
    );
  }
}
