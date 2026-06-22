import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
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
  String _keyword = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(houseSearchProvider);
    final communities = ref.watch(houseServiceProvider).getHotCommunities();

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
                onChanged: (value) => setState(() => _keyword = value),
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
              HotSearchSection(onItemTap: _submitSearch),
              const SizedBox(height: AppSpacing.xxl),
              HotCommunitySection(
                communities: communities,
                onItemTap: _submitSearch,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SearchSuggestionSection(
                keyword: _keyword,
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

  /// 校验关键词、保存搜索历史并跳转到搜索结果页。
  Future<void> _submitSearch(String value) async {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('请输入搜索关键词')));
      return;
    }

    await ref.read(houseSearchProvider.notifier).saveSearchHistory(keyword);
    if (!mounted) return;
    context.pushNamed(
      RouteNames.houseSearchResult,
      queryParameters: {'keyword': keyword},
    );
  }

  void _closePage() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.search);
    }
  }
}
