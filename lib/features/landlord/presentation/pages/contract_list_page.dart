import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../data/models/landlord_contract.dart';
import '../../data/providers/landlord_providers.dart';

class LandlordContractListPage extends ConsumerStatefulWidget {
  const LandlordContractListPage({super.key});

  @override
  ConsumerState<LandlordContractListPage> createState() =>
      _LandlordContractListPageState();
}

class _LandlordContractListPageState
    extends ConsumerState<LandlordContractListPage> {
  static const _pageSize = 20;
  final _controller = ScrollController();
  final List<LandlordContractItem> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.extentAfter < 240) _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _error = null;
      }
    });
    try {
      final data = await ref
          .read(landlordContractServiceProvider)
          .getPendingContracts(page: reset ? 1 : _page, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(data.items);
        _hasMore = data.hasMore;
        if (_hasMore) _page = data.page + 1;
        _error = null;
      });
      ref.invalidate(landlordPendingContractCountProvider);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(String orderId, {bool signNow = false}) async {
    await context.pushNamed(
      RouteNames.landlordContractDetail,
      pathParameters: {'orderId': orderId},
      queryParameters: signNow ? {'sign': '1'} : const {},
    );
    if (mounted) await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('待我签署')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return AppErrorView(
        message: '待签合同加载失败',
        onRetry: () => _load(reset: true),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            AppEmptyView(message: '暂无待签署合同'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.md,
          AppSpacing.pageHorizontal,
          32,
        ),
        itemCount: _items.length + (_loading ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[index];
          return _ContractCard(
            item: item,
            onView: () => _openDetail(item.orderId),
            onSign: () => _openDetail(item.orderId, signNow: true),
          );
        },
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.item,
    required this.onView,
    required this.onSign,
  });
  final LandlordContractItem item;
  final VoidCallback onView;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) {
    final title = [
      item.houseName,
      item.roomName,
    ].where((e) => e.isNotEmpty).join(' ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? '租赁合同' : title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (item.address.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.address,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _line('租客', '${item.tenantName}  ${item.tenantPhone}'),
          _line('租期', '${item.startDate} 至 ${item.endDate}'),
          _line('月租', formatContractMoney(item.monthlyRent), highlight: true),
          const Divider(height: 24),
          _line('租客', item.tenantSigned ? '已签署' : '待签署'),
          _line('房东', '待我签署', highlight: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('查看合同'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: onSign,
                  child: const Text('立即签署'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            '$label：',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}
