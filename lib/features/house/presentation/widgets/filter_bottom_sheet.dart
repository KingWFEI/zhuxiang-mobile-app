import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/house_search_state.dart';

class HouseFilterSelection {
  const HouseFilterSelection({
    required this.region,
    required this.minPrice,
    required this.maxPrice,
    required this.roomType,
    required this.sort,
  });

  final String region;
  final int minPrice;
  final int maxPrice;
  final String roomType;
  final String sort;
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({required this.initialState, super.key});

  final HouseSearchState initialState;

  static Future<HouseFilterSelection?> show(
    BuildContext context,
    HouseSearchState state,
  ) {
    return showModalBottomSheet<HouseFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (_) => FilterBottomSheet(initialState: state),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  static const _maxPrice = 1000000.0;

  late String _region;
  late RangeValues _prices;
  late String _roomType;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _region = widget.initialState.region;
    _prices = RangeValues(
      widget.initialState.minPrice.toDouble(),
      widget.initialState.maxPrice > 0
          ? widget.initialState.maxPrice.toDouble()
          : _maxPrice,
    );
    _roomType = widget.initialState.roomType;
    _sort = widget.initialState.sort;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('筛选房源', style: AppTextStyles.titleLarge),
              const Spacer(),
              TextButton(onPressed: _reset, child: const Text('重置')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('区域'),
          _ChoiceGroup(
            value: _region,
            options: const {
              '': '不限',
              'yubei': '渝北区',
              'jiangbei': '江北区',
              'yuzhong': '渝中区',
            },
            onSelected: (value) => setState(() => _region = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(
            '月租金：${_priceLabel(_prices.start)} - ${_priceLabel(_prices.end)}',
          ),
          RangeSlider(
            values: _prices,
            min: 0,
            max: _maxPrice,
            divisions: 100,
            labels: RangeLabels(
              _priceLabel(_prices.start),
              _priceLabel(_prices.end),
            ),
            onChanged: (value) => setState(() => _prices = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('户型'),
          _ChoiceGroup(
            value: _roomType,
            options: const {
              '': '不限',
              '1室0厅1卫': '单间',
              '1室1厅1卫': '一室一厅',
              '2室1厅1卫': '两室一厅',
            },
            onSelected: (value) => setState(() => _roomType = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('排序'),
          _ChoiceGroup(
            value: _sort,
            options: const {
              'default': '综合排序',
              'price_asc': '价格从低到高',
              'price_desc': '价格从高到低',
              'latest': '最新发布',
            },
            onSelected: (value) => setState(() => _sort = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(onPressed: _confirm, child: const Text('查看房源')),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _region = '';
      _prices = const RangeValues(0, _maxPrice);
      _roomType = '';
      _sort = 'default';
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      HouseFilterSelection(
        region: _region,
        minPrice: _prices.start.round(),
        maxPrice: _prices.end >= _maxPrice ? 0 : _prices.end.round(),
        roomType: _roomType,
        sort: _sort,
      ),
    );
  }

  String _priceLabel(double value) {
    if (value >= _maxPrice) return '不限';
    return '¥${(value / 100).round()}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTextStyles.titleMedium),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
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
      children: options.entries
          .map(
            (option) => ChoiceChip(
              label: Text(option.value),
              selected: option.key == value,
              onSelected: (_) => onSelected(option.key),
            ),
          )
          .toList(growable: false),
    );
  }
}
