import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../appointment/data/models/appointment_models.dart';
import '../../../appointment/data/providers/appointment_providers.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../house/data/models/house_detail.dart';
import '../../../house/data/providers/house_providers.dart';
import '../../../house/presentation/widgets/house_image_placeholder.dart';

class ViewingAppointmentPage extends ConsumerStatefulWidget {
  const ViewingAppointmentPage({
    required this.houseId,
    required this.houseTitle,
    super.key,
  });

  final String houseId;
  final String houseTitle;

  @override
  ConsumerState<ViewingAppointmentPage> createState() =>
      _ViewingAppointmentPageState();
}

class _ViewingAppointmentPageState
    extends ConsumerState<ViewingAppointmentPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarkController = TextEditingController();

  late DateTime _selectedDate;
  DateTime? _selectedStartAt;
  bool _agreedToPrivacy = false;
  bool _isSubmitting = false;
  bool _isLoadingSlots = true;
  String? _slotError;
  List<ViewingSlotDay> _slotDays = const [];
  String _viewingMode = 'LANDLORD_HOSTED';
  bool _requiresConfirmation = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      _nameController.text = user.nickname;
      _phoneController.text = user.phone;
    }
    Future<void>.microtask(_loadSlots);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final houseAsync = ref.watch(houseDetailProvider(widget.houseId));
    final result = houseAsync.valueOrNull;
    final house = result is ApiSuccess<HouseDetail> ? result.data : null;
    final selectedSlot = _selectedSlot();
    final selfService = _viewingMode == 'SELF_SERVICE_LOCK';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(selfService ? '预约自助看房' : '预约看房'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.goNamed(
              RouteNames.houseDetail,
              pathParameters: {'houseId': widget.houseId},
            );
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sm,
                    AppSpacing.pageHorizontal,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _HouseSummaryCard(
                        house: house,
                        fallbackTitle: widget.houseTitle,
                        isLoading: houseAsync.isLoading,
                      ),
                      if (!_isLoadingSlots && _slotError == null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ViewingModeNotice(
                          viewingMode: _viewingMode,
                          requiresConfirmation: _requiresConfirmation,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(
                        index: 1,
                        title: selfService ? '选择自助看房时间' : '选择陪同看房时间',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DateSelector(
                        dates: _slotDays.map((day) => day.date).toList(),
                        selectedDate: _selectedDate,
                        onSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            final slots = _availableSlotsFor(date);
                            _selectedStartAt = slots.isEmpty
                                ? null
                                : slots.first.startAt;
                          });
                        },
                        onMore: _showDatePicker,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_isLoadingSlots)
                        const Center(child: CircularProgressIndicator())
                      else if (_slotError != null)
                        _SlotError(message: _slotError!, onRetry: _loadSlots)
                      else if (_availableSlotsFor(_selectedDate).isEmpty)
                        const _EmptySlots()
                      else
                        _TimeSelector(
                          slots: _availableSlotsFor(_selectedDate),
                          selectedStartAt: _selectedStartAt,
                          onSelected: (slot) {
                            setState(() => _selectedStartAt = slot.startAt);
                          },
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                      const _SectionTitle(index: 2, title: '填写联系信息'),
                      const SizedBox(height: AppSpacing.lg),
                      _ContactField(
                        key: const Key('appointment-name-field'),
                        label: '姓名',
                        hintText: '请输入您的姓名',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ContactField(
                        key: const Key('appointment-phone-field'),
                        label: '手机号',
                        hintText: '请输入手机号码',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ContactField(
                        key: const Key('appointment-remark-field'),
                        label: '备注',
                        optionalLabel: '（选填）',
                        hintText: '如有特殊需求可备注',
                        controller: _remarkController,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const _SectionTitle(index: 3, title: '确认预约信息'),
                      const SizedBox(height: AppSpacing.lg),
                      _ConfirmationCard(
                        date: _selectedDate,
                        time: _selectedStartAt == null
                            ? ''
                            : _hourMinute(_selectedStartAt!),
                        slot: selectedSlot,
                        viewingMode: _viewingMode,
                        requiresConfirmation: _requiresConfirmation,
                        houseTitle: house?.title ?? widget.houseTitle,
                        roomType: house?.roomType ?? '',
                        contactName: _nameController.text.trim(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _PrivacyAgreement(
                        value: _agreedToPrivacy,
                        onChanged: (value) {
                          setState(() => _agreedToPrivacy = value);
                        },
                        onPrivacyTap: () {
                          context.pushNamed(RouteNames.privacyPolicy);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: ElevatedButton(
                            key: const Key('confirm-appointment-button'),
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '确认预约',
                                    style: AppTextStyles.labelLarge,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    if (_slotDays.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: _slotDays.last.date,
      helpText: '选择看房日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (selected == null || !mounted) return;
    final selectable = _slotDays.any(
      (day) => DateUtils.isSameDay(day.date, selected),
    );
    if (!selectable) {
      AppToast.show(context, '该日期暂无可预约时段', type: AppToastType.error);
      return;
    }
    setState(() {
      _selectedDate = selected;
      final slots = _availableSlotsFor(selected);
      _selectedStartAt = slots.isEmpty ? null : slots.first.startAt;
    });
  }

  Future<void> _loadSlots() async {
    if (mounted) {
      setState(() {
        _isLoadingSlots = true;
        _slotError = null;
      });
    }
    try {
      final result = await ref
          .read(appointmentServiceProvider)
          .getViewingSlots(widget.houseId);
      if (!mounted) return;
      final availableDays = result.dates
          .where((day) => day.slots.any((slot) => slot.available))
          .toList(growable: false);
      setState(() {
        _slotDays = availableDays;
        _viewingMode = result.viewingMode;
        _requiresConfirmation = result.requiresConfirmation;
        _isLoadingSlots = false;
        if (availableDays.isNotEmpty) {
          _selectedDate = availableDays.first.date;
          final firstSlot = availableDays.first.slots.firstWhere(
            (slot) => slot.available,
          );
          _selectedStartAt = firstSlot.startAt;
        } else {
          _selectedStartAt = null;
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
        _slotError = '可预约时段加载失败，请稍后重试';
      });
    }
  }

  List<ViewingSlot> _availableSlotsFor(DateTime date) {
    for (final day in _slotDays) {
      if (DateUtils.isSameDay(day.date, date)) {
        return day.slots
            .where((slot) => slot.available)
            .toList(growable: false);
      }
    }
    return const [];
  }

  ViewingSlot? _selectedSlot() {
    for (final day in _slotDays) {
      if (!DateUtils.isSameDay(day.date, _selectedDate)) continue;
      for (final slot in day.slots) {
        if (slot.available &&
            _selectedStartAt != null &&
            slot.startAt.isAtSameMomentAs(_selectedStartAt!)) {
          return slot;
        }
      }
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final authState = ref.read(authControllerProvider);
    if (!authState.isLoggedIn) {
      AppToast.show(context, '请先登录后再预约', type: AppToastType.error);
      await context.pushNamed(RouteNames.login);
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, '请输入姓名', type: AppToastType.error);
      return;
    }
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      AppToast.show(context, '请输入正确的手机号码', type: AppToastType.error);
      return;
    }
    if (!_agreedToPrivacy) {
      AppToast.show(context, '请先阅读并同意隐私政策', type: AppToastType.error);
      return;
    }
    final selectedSlot = _selectedSlot();
    if (selectedSlot == null) {
      AppToast.show(context, '请选择一个可预约时段', type: AppToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final appointment = await ref
          .read(appointmentServiceProvider)
          .create(
            houseId: widget.houseId,
            startAt: selectedSlot.startAt,
            contactName: name,
            contactPhone: phone,
            remark: _remarkController.text.trim(),
            testSlot: selectedSlot.testSlot,
          );
      if (!mounted) return;
      AppToast.show(
        context,
        appointment.requiresConfirmation ? '预约已提交，请等待确认' : '预约已确认',
        type: AppToastType.success,
      );
      context.pushReplacementNamed(
        RouteNames.viewingDetail,
        pathParameters: {'appointmentId': appointment.id},
        queryParameters: {'fromHouseId': widget.houseId},
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = error is ApiException ? error.message : '预约提交失败，请稍后重试';
      if (!message.contains('请先取消已有预约')) {
        await _loadSlots();
        if (!mounted) return;
      }
      AppToast.show(context, message, type: AppToastType.error);
    }
  }
}

class _HouseSummaryCard extends StatelessWidget {
  const _HouseSummaryCard({
    required this.house,
    required this.fallbackTitle,
    required this.isLoading,
  });

  final HouseDetail? house;
  final String fallbackTitle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final detail = house;
    final title = detail?.title.isNotEmpty == true
        ? detail!.title
        : fallbackTitle;
    final attributes = [
      detail?.roomType ?? '',
      if (detail != null && detail.area > 0) '${detail.area}㎡',
      detail?.orientation ?? '',
    ].where((item) => item.isNotEmpty).join(' · ');
    final address = [
      detail?.location ?? '',
      detail?.community ?? '',
      detail?.address ?? '',
    ].where((item) => item.isNotEmpty).toSet().join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: HouseImagePlaceholder(
              coverImage: detail?.coverImage,
              height: 112,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: SizedBox(
              height: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (isLoading)
                    const _LoadingLine(width: 150)
                  else
                    Text(
                      attributes.isEmpty ? '房源信息加载中' : attributes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  if (isLoading)
                    const _LoadingLine(width: 120)
                  else
                    Text(
                      address.isEmpty ? '详细地址以管家确认为准' : address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  const Spacer(),
                  Text(
                    detail == null || detail.price <= 0
                        ? '价格面议'
                        : '¥${detail.price}/月',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.error,
                      fontSize: 17,
                    ),
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

class _ViewingModeNotice extends StatelessWidget {
  const _ViewingModeNotice({
    required this.viewingMode,
    required this.requiresConfirmation,
  });

  final String viewingMode;
  final bool requiresConfirmation;

  @override
  Widget build(BuildContext context) {
    final selfService = viewingMode == 'SELF_SERVICE_LOCK';
    final landlordHosted = viewingMode == 'LANDLORD_HOSTED';
    final title = selfService
        ? '智能门锁自助看房'
        : landlordHosted
        ? '房东陪同看房'
        : '平台管家陪同看房';
    final description = selfService
        ? '预约成功后系统将按页面显示的有效时间发放蓝牙钥匙和开门密码，无需等待人工确认。'
        : landlordHosted
        ? '提交后需要等待房东确认，确认后请按约定地点与房东会合。'
        : '提交后需要等待平台管家确认，确认后由管家按约定地点陪同看房。';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: selfService ? const Color(0xFFEEF6FF) : const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: selfService
              ? const Color(0xFFBBD8FF)
              : const Color(0xFFF2D49A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selfService ? Icons.lock_open_rounded : Icons.support_agent_rounded,
            color: selfService ? AppColors.primary : const Color(0xFFB7791F),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodySmall),
                if (requiresConfirmation) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '当前预约需接待方确认后生效',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFB7791F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.index, required this.title});

  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
    required this.onMore,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final visibleDates = dates.take(5).toList(growable: false);

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleDates.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == visibleDates.length) {
            final isCustomDate = !visibleDates.any(
              (date) => DateUtils.isSameDay(date, selectedDate),
            );
            return _DateTile.more(selected: isCustomDate, onTap: onMore);
          }
          final date = visibleDates[index];
          return _DateTile(
            date: date,
            selected: DateUtils.isSameDay(date, selectedDate),
            onTap: () => onSelected(date),
          );
        },
      ),
    );
  }
}

class _SlotError extends StatelessWidget {
  const _SlotError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}

class _EmptySlots extends StatelessWidget {
  const _EmptySlots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '当前暂无可预约时段',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.selected,
    required this.onTap,
  }) : isMore = false;

  const _DateTile.more({required this.selected, required this.onTap})
    : date = null,
      isMore = true;

  final DateTime? date;
  final bool selected;
  final VoidCallback onTap;
  final bool isMore;

  @override
  Widget build(BuildContext context) {
    final currentDate = date;
    return SizedBox(
      width: 53,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: isMore
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '更多',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dateLabel(currentDate!),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _monthDay(currentDate),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
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

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.slots,
    required this.selectedStartAt,
    required this.onSelected,
  });

  final List<ViewingSlot> slots;
  final DateTime? selectedStartAt;
  final ValueChanged<ViewingSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.8,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final time = _hourMinute(slot.startAt);
        final selected =
            selectedStartAt != null &&
            slot.startAt.isAtSameMomentAs(selectedStartAt!);
        return Material(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            key: Key(
              slot.testSlot
                  ? 'appointment-time-test'
                  : 'appointment-time-$time',
            ),
            onTap: () => onSelected(slot),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: slot.testSlot
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '测试 · 最近整点',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: selected
                                ? Colors.white
                                : const Color(0xFFD97706),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _timeRange(slot.startAt, slot.endAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _timeRange(slot.startAt, slot.endAt),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.textInputAction,
    this.optionalLabel,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final String? optionalLabel;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (optionalLabel != null)
                  Flexible(
                    child: Text(
                      optionalLabel!,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.date,
    required this.time,
    required this.slot,
    required this.viewingMode,
    required this.requiresConfirmation,
    required this.houseTitle,
    required this.roomType,
    required this.contactName,
  });

  final DateTime date;
  final String time;
  final ViewingSlot? slot;
  final String viewingMode;
  final bool requiresConfirmation;
  final String houseTitle;
  final String roomType;
  final String contactName;

  @override
  Widget build(BuildContext context) {
    final selectedSlot = slot;
    final selfService = viewingMode == 'SELF_SERVICE_LOCK';
    final viewingTime = selectedSlot == null
        ? '${_fullDate(date)} ${_todaySuffix(date)} $time'
        : '${_fullDate(selectedSlot.startAt.toLocal())} '
              '${_todaySuffix(selectedSlot.startAt.toLocal())} '
              '${_timeRange(selectedSlot.startAt, selectedSlot.endAt)}';
    final modeLabel = selfService
        ? '智能门锁自助看房'
        : viewingMode == 'LANDLORD_HOSTED'
        ? '房东陪同看房'
        : '平台管家陪同看房';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.authBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          _ConfirmationRow(label: '看房时间', value: viewingTime),
          if (selectedSlot?.testSlot == true) ...[
            const Divider(height: 1, color: AppColors.border),
            const _ConfirmationRow(
              label: '测试时段',
              value: '提交时按服务器下一个最近整点创建',
              valueColor: Color(0xFFD97706),
            ),
          ],
          const Divider(height: 1, color: AppColors.border),
          _ConfirmationRow(label: '看房方式', value: modeLabel),
          if (selfService &&
              selectedSlot?.accessValidFrom != null &&
              selectedSlot?.accessValidTo != null) ...[
            const Divider(height: 1, color: AppColors.border),
            _ConfirmationRow(
              label: '门锁有效',
              value: _dateTimeRange(
                selectedSlot!.accessValidFrom!,
                selectedSlot.accessValidTo!,
              ),
              valueColor: AppColors.primary,
            ),
          ],
          if (requiresConfirmation) ...[
            const Divider(height: 1, color: AppColors.border),
            const _ConfirmationRow(label: '确认状态', value: '提交后等待接待方确认'),
          ],
          const Divider(height: 1, color: AppColors.border),
          _ConfirmationRow(
            label: '房源',
            value: [
              houseTitle,
              roomType,
            ].where((item) => item.isNotEmpty).join('  '),
          ),
          const Divider(height: 1, color: AppColors.border),
          _ConfirmationRow(
            label: '联系人',
            value: contactName.isEmpty ? '—' : contactName,
          ),
        ],
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueColor == null ? null : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyAgreement extends StatelessWidget {
  const _PrivacyAgreement({
    required this.value,
    required this.onChanged,
    required this.onPrivacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            key: const Key('appointment-privacy-checkbox'),
            value: value,
            onChanged: (next) => onChanged(next ?? false),
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.inputBorder),
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('我已阅读并同意', style: AppTextStyles.bodySmall),
              InkWell(
                onTap: onPrivacyTap,
                child: Text(
                  '《隐私政策》',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final difference = date.difference(today).inDays;
  if (difference == 0) return '今天';
  if (difference == 1) return '明天';
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[date.weekday - 1];
}

String _monthDay(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

String _fullDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _hourMinute(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _timeRange(DateTime start, DateTime end) {
  return '${_hourMinute(start)}–${_hourMinute(end)}';
}

String _dateTimeRange(DateTime start, DateTime end) {
  final localStart = start.toLocal();
  final localEnd = end.toLocal();
  if (DateUtils.isSameDay(localStart, localEnd)) {
    return '${_fullDate(localStart)} ${_timeRange(localStart, localEnd)}';
  }
  return '${_fullDate(localStart)} ${_hourMinute(localStart)}–'
      '${_fullDate(localEnd)} ${_hourMinute(localEnd)}';
}

String _todaySuffix(DateTime date) {
  final now = DateTime.now();
  return DateUtils.isSameDay(now, date) ? '（今天）' : '';
}
