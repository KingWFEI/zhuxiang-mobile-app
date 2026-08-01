import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/community.dart';
import '../../data/providers/landlord_providers.dart';
import '../pages/map_poi_selector.dart';

class CommunityPicker extends StatelessWidget {
  const CommunityPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Community? selected;
  final ValueChanged<Community> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<Community>(
      key: ValueKey(selected?.id),
      initialValue: selected,
      validator: (value) => value == null || value.id.isEmpty ? '请选择小区' : null,
      builder: (field) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () async {
            final result = await showModalBottomSheet<Community>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CommunitySearchSheet(initial: selected),
            );
            if (result == null) return;
            field.didChange(result);
            onChanged(result);
          },
          child: InputDecorator(
            // 未选择时仍显示了“搜索并选择小区”，装饰器实际并非空状态。
            // 固定浮动标签，避免 labelText 与提示文字占用同一行。
            isEmpty: false,
            decoration: InputDecoration(
              labelText: '小区',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              errorText: field.errorText,
              prefixIcon: const Icon(Icons.apartment_rounded),
              suffixIcon: const Icon(Icons.chevron_right_rounded),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
            child: selected == null
                ? Text(
                    '搜索并选择小区',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected!.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selected!.locationLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          selected!.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _CommunitySearchSheet extends ConsumerStatefulWidget {
  const _CommunitySearchSheet({this.initial});

  final Community? initial;

  @override
  ConsumerState<_CommunitySearchSheet> createState() =>
      _CommunitySearchSheetState();
}

class _CommunitySearchSheetState extends ConsumerState<_CommunitySearchSheet> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;
  List<Community> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initial?.name ?? '');
    if (_searchCtrl.text.trim().length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    if (keyword.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _search() async {
    final keyword = _searchCtrl.text.trim();
    if (keyword.length < 2) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(communityServiceProvider).search(keyword);
      if (!mounted || keyword != _searchCtrl.text.trim()) return;
      setState(() => _results = results);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted && keyword == _searchCtrl.text.trim()) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openMap() async {
    final keyword = _searchCtrl.text.trim();
    if (keyword.length < 2) return;
    final result = await Navigator.of(context, rootNavigator: true)
        .push<Community>(
          MaterialPageRoute(
            builder: (_) => MapPoiSelector(initialKeyword: keyword),
          ),
        );
    if (!mounted || result == null) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.86,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择小区', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('输入至少 2 个字，先从已收录小区中查找', style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchCtrl,
                  autofocus: widget.initial == null,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '例如：龙湖春森彼岸',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              _onQueryChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppColors.authBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
          if (_searchCtrl.text.trim().length >= 2)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('内部没找到？从地图中查找'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: '小区搜索失败',
        description: _error!,
        actionLabel: '重试',
        onAction: _search,
      );
    }
    if (_searchCtrl.text.trim().length < 2) {
      return const _MessageState(
        icon: Icons.apartment_rounded,
        title: '输入小区名称',
        description: '输入 2 个字后将自动搜索',
      );
    }
    if (_results.isEmpty) {
      return const _MessageState(
        icon: Icons.location_searching_rounded,
        title: '未找到已收录小区',
        description: '可以使用下方按钮从地图中查找',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, index) {
        final community = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.apartment_rounded),
          ),
          title: Text(
            community.name,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: community.locationLabel.isEmpty
              ? null
              : Text(
                  community.locationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).pop(community),
        );
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
