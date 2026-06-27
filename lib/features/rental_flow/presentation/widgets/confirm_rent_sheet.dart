import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../house/data/models/house_detail.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../data/services/rental_flow_service.dart';
import '../../domain/entities/rent_order.dart';
import 'agreement_checkbox.dart';

const List<String> _paymentMethodOptions = ['月付', '季付', '半年付', '年付'];

class ConfirmRentSheet extends ConsumerStatefulWidget {
  const ConfirmRentSheet({required this.house, super.key});

  final HouseDetail house;

  @override
  ConsumerState<ConfirmRentSheet> createState() => _ConfirmRentSheetState();
}

class _ConfirmRentSheetState extends ConsumerState<ConfirmRentSheet> {
  bool _agreed = false;
  DateTime _startDate = DateTime(2026, 7, 1);
  int _leaseMonths = 12;
  String _paymentMethod = '月付';
  int _tenantCount = 1;

  int get _monthlyRent => _displayMoney(widget.house.price);
  int get _deposit => widget.house.deposit > 0
      ? _displayMoney(widget.house.deposit)
      : _displayMoney(widget.house.price);
  int get _serviceFee => 200;

  @override
  void initState() {
    super.initState();
    if (widget.house.paymentMethod.isNotEmpty) {
      _paymentMethod = _paymentMethodLabel(widget.house.paymentMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.md,
                bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('确认租住', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.lg),
                  _HouseSummary(house: widget.house),
                  const SizedBox(height: AppSpacing.lg),
                  _OptionCard(
                    rows: [
                      _SheetRow(
                        label: '起租日期',
                        value: _formatDate(_startDate),
                        onTap: _pickStartDate,
                      ),
                      _SheetRow(
                        label: '租期',
                        value: '$_leaseMonths个月',
                        onTap: () => _pickIntOption(
                          title: '选择租期',
                          values: const [6, 12, 24],
                          current: _leaseMonths,
                          formatter: (value) => '$value个月',
                          onSelected: (value) {
                            setState(() => _leaseMonths = value);
                          },
                        ),
                      ),
                      _SheetRow(
                        label: '付款方式',
                        value: _paymentMethod,
                        onTap: () => _pickStringOption(
                          title: '选择付款方式',
                          values: _paymentMethodOptions,
                          current: _paymentMethod,
                          onSelected: (value) {
                            setState(() => _paymentMethod = value);
                          },
                        ),
                      ),
                      _SheetRow(
                        label: '入住人',
                        value: '$_tenantCount人',
                        onTap: () => _pickIntOption(
                          title: '选择入住人数',
                          values: const [1, 2, 3, 4],
                          current: _tenantCount,
                          formatter: (value) => '$value人',
                          onSelected: (value) {
                            setState(() => _tenantCount = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FeeSummary(
                    monthlyRent: _monthlyRent,
                    deposit: _deposit,
                    serviceFee: _serviceFee,
                    leaseMonths: _leaseMonths,
                    paymentMethod: _paymentMethod,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AgreementCheckbox(
                    value: _agreed,
                    text: '我已阅读并同意《租住须知》与《平台协议》',
                    onChanged: (value) => setState(() => _agreed = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size.fromHeight(48),
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('确认租住'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('zh', 'CN'),
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickStringOption({
    required String title,
    required List<String> values,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionPicker<String>(
        title: title,
        values: values,
        current: current,
        formatter: (value) => value,
      ),
    );
    if (value == null || !mounted) return;
    onSelected(value);
  }

  Future<void> _pickIntOption({
    required String title,
    required List<int> values,
    required int current,
    required String Function(int value) formatter,
    required ValueChanged<int> onSelected,
  }) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionPicker<int>(
        title: title,
        values: values,
        current: current,
        formatter: formatter,
      ),
    );
    if (value == null || !mounted) return;
    onSelected(value);
  }

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先勾选并同意相关协议')));
      return;
    }

    final currentOrder = ref.read(rentalFlowControllerProvider).order;
    if (currentOrder != null && currentOrder.houseId == widget.house.id) {
      if (currentOrder.status == RentOrderStatus.completed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该房源已完成租住，不能重复发起租约')));
        return;
      }
      Navigator.pop(context);
      _goNextStep(currentOrder);
      return;
    }

    final order = await ref
        .read(rentalFlowControllerProvider.notifier)
        .createRentOrder(
          CreateRentOrderRequest(
            houseId: widget.house.id,
            houseName: widget.house.title,
            roomName: widget.house.community.isEmpty
                ? '待确认房间'
                : widget.house.community,
            address: widget.house.address.isEmpty
                ? widget.house.location
                : widget.house.address,
            coverUrl: widget.house.coverImage,
            startDate: _startDate,
            leaseMonths: _leaseMonths,
            paymentMethod: _paymentMethodCode(_paymentMethod),
            tenantCount: _tenantCount,
            monthlyRent: _monthlyRent,
            deposit: _deposit,
            serviceFee: _serviceFee,
          ),
        );
    if (!mounted || order == null) return;
    Navigator.pop(context);
    context.pushNamed(
      RouteNames.realNameVerify,
      pathParameters: {'orderId': order.id},
    );
  }

  void _goNextStep(RentOrder order) {
    final routeName = switch (order.status) {
      RentOrderStatus.created ||
      RentOrderStatus.pendingRealName => RouteNames.realNameVerify,
      RentOrderStatus.pendingContract => RouteNames.leaseContract,
      RentOrderStatus.pendingPayment => RouteNames.rentalPayment,
      RentOrderStatus.pendingSign => RouteNames.onlineSign,
      RentOrderStatus.completed => RouteNames.moveInComplete,
      RentOrderStatus.cancelled => RouteNames.realNameVerify,
    };
    context.pushNamed(routeName, pathParameters: {'orderId': order.id});
  }
}

class _HouseSummary extends StatelessWidget {
  const _HouseSummary({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: house.coverImage.isEmpty
                ? Container(
                    width: 76,
                    height: 76,
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.primary,
                    ),
                  )
                : Image.network(
                    house.coverImage,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 76,
                      height: 76,
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  house.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  house.address.isEmpty ? house.location : house.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  house.community,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.rows});

  final List<_SheetRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index != rows.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeSummary extends StatelessWidget {
  const _FeeSummary({
    required this.monthlyRent,
    required this.deposit,
    required this.serviceFee,
    required this.leaseMonths,
    required this.paymentMethod,
  });

  final int monthlyRent;
  final int deposit;
  final int serviceFee;
  final int leaseMonths;
  final String paymentMethod;

  int get rentMonths => _paymentMonths(paymentMethod).clamp(1, leaseMonths);
  int get firstRent => monthlyRent * rentMonths;
  int get total => firstRent + deposit + serviceFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _FeeRow(label: '月租金', amount: monthlyRent),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(label: '首期租金', amount: firstRent),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(label: '押金', amount: deposit),
          const SizedBox(height: AppSpacing.sm),
          _FeeRow(label: '服务费', amount: serviceFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Text(
                '首笔应付',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '￥$total',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text('￥$amount', style: AppTextStyles.bodyLarge),
      ],
    );
  }
}

class _OptionPicker<T> extends StatelessWidget {
  const _OptionPicker({
    required this.title,
    required this.values,
    required this.current,
    required this.formatter,
  });

  final String title;
  final List<T> values;
  final T current;
  final String Function(T value) formatter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),
                ...values.map(
                  (value) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      formatter(value),
                      style: AppTextStyles.bodyLarge,
                    ),
                    trailing: value == current
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

int _displayMoney(int value) {
  if (value < 10000) return value;
  return (value / 100).round();
}

int _paymentMonths(String paymentMethod) {
  return switch (paymentMethod) {
    'quarterly' || '季付' => 3,
    'semi_annual' || '半年付' => 6,
    'annual' || '年付' => 12,
    _ => 1,
  };
}

String _paymentMethodCode(String paymentMethod) {
  return switch (paymentMethod) {
    '季付' || 'quarterly' => 'quarterly',
    '半年付' || 'semi_annual' => 'semi_annual',
    '年付' || 'annual' => 'annual',
    _ => 'monthly',
  };
}

String _paymentMethodLabel(String paymentMethod) {
  return switch (paymentMethod) {
    'monthly' || '押一付一' || '月付' => '月付',
    'quarterly' || '押一付三' || '季付' => '季付',
    'semi_annual' || '押一付六' || '半年付' => '半年付',
    'annual' || '押一付十二' || '年付' => '年付',
    _ => paymentMethod.isEmpty ? '月付' : paymentMethod,
  };
}
