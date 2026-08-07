import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/house_tag.dart';

const _sheetTitleStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w800);

/// 展示区域选择 BottomSheet。
Future<String?> showRegionSheet(
  BuildContext context, {
  required String selectedValue,
  required Map<String, String> options,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SingleSelectSheet(
      title: '选择区域',
      selectedValue: selectedValue,
      options: options,
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
  required Map<String, String> options,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SingleSelectSheet(
      title: '选择户型',
      selectedValue: selectedValue,
      options: options,
    ),
  );
}

/// 展示更多筛选条件 BottomSheet（含排序、电梯、朝向等）。
Future<HouseExtraFilterSelection?> showMoreFilterSheet(
  BuildContext context, {
  required String sort,
  required String decoration,
  required String orientation,
  required String rentMode,
  required String rentType,
  required Set<String> facilityIds,
  required Set<String> tagIds,
  required List<HouseTag> facilities,
  required List<HouseTag> tags,
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
      rentMode: rentMode,
      rentType: rentType,
      facilityIds: facilityIds,
      tagIds: tagIds,
      facilities: facilities,
      tags: tags,
    ),
  );
}

class HouseExtraFilterSelection {
  const HouseExtraFilterSelection({
    required this.sort,
    required this.decoration,
    required this.orientation,
    required this.rentMode,
    required this.rentType,
    required this.facilityIds,
    required this.tagIds,
  });

  final String sort;
  final String decoration;
  final String orientation;
  final String rentMode;
  final String rentType;
  final Set<String> facilityIds;
  final Set<String> tagIds;
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
            width: 40,
            height: 4,
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
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: Material(
              color: Colors.white,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final option in options.entries)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.value),
                      trailing: option.key == selectedValue
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(option.key),
                    ),
                ],
              ),
            ),
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
            width: 40,
            height: 4,
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
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
    required this.rentMode,
    required this.rentType,
    required this.facilityIds,
    required this.tagIds,
    required this.facilities,
    required this.tags,
  });

  final String sort;
  final String decoration;
  final String orientation;
  final String rentMode;
  final String rentType;
  final Set<String> facilityIds;
  final Set<String> tagIds;
  final List<HouseTag> facilities;
  final List<HouseTag> tags;

  @override
  State<_MoreFilterSheet> createState() => _MoreFilterSheetState();
}

class _MoreFilterSheetState extends State<_MoreFilterSheet> {
  late String _sort;
  late String _decoration;
  late String _orientation;
  late String _rentMode;
  late String _rentType;
  late Set<String> _facilityIds;
  late Set<String> _tagIds;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
    _decoration = widget.decoration;
    _orientation = widget.orientation;
    _rentMode = widget.rentMode;
    _rentType = widget.rentType;
    _facilityIds = widget.facilityIds.toSet();
    _tagIds = widget.tagIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
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
                '精装修': '精装修',
                '简装修': '简装修',
                '毛坯': '毛坯',
                '豪华装修': '豪华装修',
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
                '朝南': '朝南',
                '朝北': '朝北',
                '朝东': '朝东',
                '朝西': '朝西',
              },
              onSelected: (v) => setState(() => _orientation = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle('出租方式'),
            _ChoiceBar(
              value: _rentMode,
              options: const {
                '': '不限',
                'WHOLE_RENT': '整租',
                'SHARED_RENT': '合租',
              },
              onSelected: (v) => setState(() => _rentMode = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle('租赁类型'),
            _ChoiceBar(
              value: _rentType,
              options: const {
                '': '不限',
                'LONG_RENT': '长租',
                'SHORT_RENT': '短租',
                'HOMESTAY': '民宿',
              },
              onSelected: (v) => setState(() => _rentType = v),
            ),
            if (widget.facilities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('房间设施'),
              _MultiChoiceBar(
                selected: _facilityIds,
                options: widget.facilities,
                onSelected: (value) => setState(() {
                  if (!_facilityIds.add(value)) _facilityIds.remove(value);
                }),
              ),
            ],
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('更多'),
              _MultiChoiceBar(
                selected: _tagIds,
                options: widget.tags,
                onSelected: (value) => setState(() {
                  if (!_tagIds.add(value)) _tagIds.remove(value);
                }),
              ),
            ],
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
                    rentMode: _rentMode,
                    rentType: _rentType,
                    facilityIds: _facilityIds,
                    tagIds: _tagIds,
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
      child: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChoiceBar extends StatelessWidget {
  const _ChoiceBar({
    required this.value,
    required this.options,
    required this.onSelected,
  });
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

class _MultiChoiceBar extends StatelessWidget {
  const _MultiChoiceBar({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final Set<String> selected;
  final List<HouseTag> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options
          .map(
            (option) => FilterChip(
              label: Text(option.label),
              selected: selected.contains(option.value),
              onSelected: (_) => onSelected(option.value),
            ),
          )
          .toList(growable: false),
    );
  }
}
