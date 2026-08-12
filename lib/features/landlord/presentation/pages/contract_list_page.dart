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
import '../../../auth/presentation/auth_controller.dart';
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
  final List<LandlordTerminationItem> _terminationItems = [];
  int _page = 1;
  bool _hasMore = true;
  int _terminationPage = 1;
  bool _terminationHasMore = true;
  bool _loading = false;
  Object? _error;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _loadedUserId = ref.read(authControllerProvider).user?.id;
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
    if (!reset && !_hasMore && !_terminationHasMore) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _terminationPage = 1;
        _terminationHasMore = true;
        _error = null;
      }
    });
    try {
      final service = ref.read(landlordContractServiceProvider);
      final results = await Future.wait([
        if (reset || _hasMore)
          service.getPendingContracts(
            page: reset ? 1 : _page,
            pageSize: _pageSize,
          ),
        if (reset || _terminationHasMore)
          service.getPendingTerminations(
            page: reset ? 1 : _terminationPage,
            pageSize: _pageSize,
          ),
      ]);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items.clear();
          _terminationItems.clear();
        }
        for (final result in results) {
          if (result is LandlordContractPage) {
            _items.addAll(result.items);
            _hasMore = result.hasMore;
            if (_hasMore) _page = result.page + 1;
          } else if (result is LandlordTerminationPage) {
            _terminationItems.addAll(
              result.items.where((item) => item.isValidPendingSignature),
            );
            _terminationHasMore = result.hasMore;
            if (_terminationHasMore) _terminationPage = result.page + 1;
          }
        }
        _error = null;
      });
      ref.invalidate(landlordPendingSignCountsProvider);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(String orderId) async {
    await context.pushNamed(
      RouteNames.landlordContractDetail,
      pathParameters: {'orderId': orderId},
    );
    if (mounted) await _load(reset: true);
  }

  Future<void> _openTerminationDetail(String applicationId) async {
    await context.pushNamed(
      RouteNames.landlordTerminationDetail,
      pathParameters: {'applicationId': applicationId},
    );
    if (mounted) await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    if (_loadedUserId != userId) {
      _loadedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _loadedUserId != userId) return;
        setState(() {
          _items.clear();
          _terminationItems.clear();
          _page = 1;
          _hasMore = true;
          _terminationPage = 1;
          _terminationHasMore = true;
          _error = null;
        });
        _load(reset: true);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('待我签署')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _terminationItems.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _terminationItems.isEmpty && _error != null) {
      return AppErrorView(
        message: '待签合同加载失败',
        onRetry: () => _load(reset: true),
      );
    }
    if (_items.isEmpty && _terminationItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            AppEmptyView(message: '暂无待签署合同或解约协议'),
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
        itemCount:
            _items.length + _terminationItems.length + (_loading ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == _items.length + _terminationItems.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (index < _items.length) {
            final item = _items[index];
            return _ContractCard(
              item: item,
              onView: () => _openDetail(item.orderId),
              onSign: () => _openDetail(item.orderId),
            );
          }
          final item = _terminationItems[index - _items.length];
          return _TerminationCard(
            item: item,
            onView: () => _openTerminationDetail(item.applicationId),
            onSign: () => _openTerminationDetail(item.applicationId),
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
          const _DocumentTypeBadge(
            label: '租赁合同',
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
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
                  child: const Text('处理合同'),
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

class _TerminationCard extends StatelessWidget {
  const _TerminationCard({
    required this.item,
    required this.onView,
    required this.onSign,
  });

  final LandlordTerminationItem item;
  final VoidCallback onView;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) {
    final title = [
      item.houseName,
      item.roomName,
    ].where((value) => value.isNotEmpty).join(' ');
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
          const _DocumentTypeBadge(
            label: '解约协议',
            icon: Icons.assignment_return_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title.isEmpty ? '租赁合同解约协议' : title,
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
          _infoLine('租客', '${item.tenantName}  ${item.tenantPhone}'),
          _infoLine('申请单', item.applicationNo),
          _infoLine('退租日', item.expectedMoveOutDate),
          const Divider(height: 24),
          _infoLine('租客', item.tenantSigned ? '已签署' : '待签署'),
          _infoLine('房东', '待我签署', highlight: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('查看协议'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: onSign,
                  child: const Text('处理协议'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentTypeBadge extends StatelessWidget {
  const _DocumentTypeBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.primary, fontSize: 12),
        ),
      ],
    ),
  );
}

Widget _infoLine(String label, String value, {bool highlight = false}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '$label：',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: highlight ? AppColors.primary : AppColors.textPrimary,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
