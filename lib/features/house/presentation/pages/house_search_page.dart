import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/location/user_location_provider.dart';
import '../../application/house_search_notifier.dart';
import '../../data/providers/house_providers.dart';
import '../widgets/search_discovery_widgets.dart';

/// 房源搜索发现页
class HouseSearchPage extends ConsumerStatefulWidget {
  const HouseSearchPage({super.key});

  @override
  ConsumerState<HouseSearchPage> createState() => _HouseSearchPageState();
}

class _HouseSearchPageState extends ConsumerState<HouseSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _suggestionDebounce;
  String _keyword = '';
  List<String> _suggestions = const [];
  bool _isSuggestionLoading = false;
  int _suggestionRequestVersion = 0;
  bool _isNavigating = false;

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(houseSearchProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchInputHeader(
                controller: _controller,
                onBack: _closePage,
                onChanged: _onKeywordChanged,
                onSubmitted: _submitSearch,
                onAction: _keyword.trim().isEmpty ? _closePage : _searchCurrent,
              ),
              SearchHistorySection(
                items: state.searchHistory,
                onItemTap: _submitSearch,
                onClear: () =>
                    ref.read(houseSearchProvider.notifier).clearSearchHistory(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SearchSuggestionSection(
                keyword: _keyword,
                suggestions: _suggestions,
                isLoading: _isSuggestionLoading,
                onItemTap: _submitSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 搜索按钮使用输入框当前内容。
  void _searchCurrent() => _submitSearch(_controller.text);

  void _onKeywordChanged(String value) {
    final keyword = value.trim();
    _suggestionDebounce?.cancel();
    final requestVersion = ++_suggestionRequestVersion;
    setState(() {
      _keyword = value;
      _suggestions = const [];
      _isSuggestionLoading = false;
    });
    if (keyword.isEmpty) return;
    _suggestionDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _loadSuggestions(keyword, requestVersion),
    );
  }

  Future<void> _loadSuggestions(String keyword, int requestVersion) async {
    if (!mounted || requestVersion != _suggestionRequestVersion) return;
    setState(() => _isSuggestionLoading = true);
    try {
      final city = ref.read(userLocationProvider).city;
      final suggestions = await ref
          .read(houseServiceProvider)
          .fetchSearchSuggestions(keyword, city: city);
      if (!mounted || requestVersion != _suggestionRequestVersion) return;
      setState(() {
        _suggestions = suggestions;
        _isSuggestionLoading = false;
      });
    } on Object {
      if (!mounted || requestVersion != _suggestionRequestVersion) return;
      setState(() {
        _suggestions = const [];
        _isSuggestionLoading = false;
      });
    }
  }

  /// 校验关键词并跳转到搜索结果页（搜索历史由结果页在搜索完成后自动保存）。
  void _submitSearch(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('请输入搜索关键词')));
      return;
    }
    // 防止 onSubmitted 和 onAction 短时间内重复触发导致 Navigator key 冲突
    if (_isNavigating) return;
    _suggestionDebounce?.cancel();
    _suggestionRequestVersion++;
    _isNavigating = true;

    context
        .pushNamed(
          RouteNames.houseSearchResult,
          queryParameters: {'keyword': keyword},
        )
        .whenComplete(() {
          if (mounted) _isNavigating = false;
        });
  }

  void _closePage() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.search);
    }
  }
}
