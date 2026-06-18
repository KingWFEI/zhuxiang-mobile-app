import 'package:flutter/material.dart';
import 'package:zhuxiang_app/app/theme/app_text_styles.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class HouseSearchBar extends StatefulWidget {
  const HouseSearchBar({
    required this.keyword,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFilterTap,
    required this.activeFilterCount,
    super.key,
  });

  final String keyword;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  State<HouseSearchBar> createState() => _HouseSearchBarState();
}

class _HouseSearchBarState extends State<HouseSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.keyword);
  }

  @override
  void didUpdateWidget(covariant HouseSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyword != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.keyword,
        selection: TextSelection.collapsed(offset: widget.keyword.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: '搜索小区、地铁、区域或房源',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.keyword.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Badge(
          isLabelVisible: widget.activeFilterCount > 0,
          label: Text('${widget.activeFilterCount}'),
          child: IconButton.filledTonal(
            onPressed: widget.onFilterTap,
            tooltip: '筛选',
            icon: const Icon(Icons.tune),
            iconSize: 20,
          ),
        ),
      ],
    );
  }
}
