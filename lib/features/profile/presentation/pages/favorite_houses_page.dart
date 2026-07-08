import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../house/data/models/house.dart';
import '../../../house/data/providers/house_providers.dart';
import '../../../house/presentation/widgets/house_card.dart';

class FavoriteHousesPage extends ConsumerStatefulWidget {
  const FavoriteHousesPage({super.key});

  @override
  ConsumerState<FavoriteHousesPage> createState() =>
      _FavoriteHousesPageState();
}

class _FavoriteHousesPageState extends ConsumerState<FavoriteHousesPage> {
  final ScrollController _scrollController = ScrollController();
  List<House> _houses = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 200 && _hasMore && !_isLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(houseServiceProvider)
          .getFavoriteHouses(page: _page, pageSize: 20);
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _hasMore = result.hasMore;
        _houses = _page == 1 ? result.items : [..._houses, ...result.items];
        _isLoading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _page = 1);
    await _load();
  }

  Future<void> _onFavoriteToggle(House house) async {
    try {
      if (house.isFavorite) {
        await ref.read(houseServiceProvider).removeFavorite(house.id);
      } else {
        await ref.read(houseServiceProvider).addFavorite(house.id);
      }
      // 收藏列表中取消收藏后从列表移除
      setState(() => _houses.removeWhere((h) => h.id == house.id));
    } on Object {
      if (mounted) {
        AppToast.show(context, '操作失败', type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: AppColors.surface,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _houses.isEmpty) {
      return const AppLoadingView(message: '正在加载收藏房源');
    }
    if (_error != null && _houses.isEmpty) {
      return AppErrorView(
        message: _error!,
        onRetry: () {
          setState(() => _page = 1);
          _load();
        },
      );
    }
    if (_houses.isEmpty) {
      return const AppEmptyView(message: '还没有收藏房源');
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.md,
          AppSpacing.pageHorizontal,
          96,
        ),
        itemCount: _houses.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _houses.length) {
            return _loadMoreWidget();
          }
          final house = _houses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: HouseCard(
              key: ValueKey(house.id),
              house: house,
              isFavorite: true,
              onFavoriteTap: () => _onFavoriteToggle(house),
              onTap: () => context.pushNamed(
                RouteNames.houseDetail,
                pathParameters: {'houseId': house.id},
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _loadMoreWidget() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton(
            onPressed: _load,
            child: Text('加载失败，点击重试', style: AppTextStyles.bodySmall),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
