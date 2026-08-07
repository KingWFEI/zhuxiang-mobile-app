import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../data/models/appointment_models.dart';
import '../../data/providers/appointment_providers.dart';

class AppointmentListPage extends ConsumerWidget {
  const AppointmentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(myAppointmentsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 44,
          leadingWidth: 80,
          leading: const _AppointmentBackButton(),
          actions: const [SizedBox(width: 80)],
          elevation: 0,
          titleTextStyle: AppTextStyles.normalPageTitle,
          title: const Text('我的预约'),
          centerTitle: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: '待处理'),
              Tab(text: '即将开始'),
              Tab(text: '历史预约'),
            ],
          ),
        ),
        body: appointments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppApiErrorView(
            error: error,
            onRetry: () => ref.invalidate(myAppointmentsProvider),
          ),
          data: (items) => TabBarView(
            children: [
              _AppointmentList(
                items: items
                    .where((item) {
                      return item.status == 'PENDING_CONFIRMATION' ||
                          item.status == 'RESCHEDULE_PROPOSED';
                    })
                    .toList(growable: false),
                onRefresh: () => ref.refresh(myAppointmentsProvider.future),
              ),
              _AppointmentList(
                items: items
                    .where((item) {
                      return item.status == 'CONFIRMED' ||
                          item.status == 'READY' ||
                          item.status == 'IN_PROGRESS';
                    })
                    .toList(growable: false),
                onRefresh: () => ref.refresh(myAppointmentsProvider.future),
              ),
              _AppointmentList(
                items: items
                    .where((item) {
                      return item.status == 'COMPLETED' ||
                          item.status == 'REJECTED' ||
                          item.status == 'CANCELLED' ||
                          item.status == 'EXPIRED' ||
                          item.status == 'NO_SHOW';
                    })
                    .toList(growable: false),
                onRefresh: () => ref.refresh(myAppointmentsProvider.future),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentBackButton extends StatelessWidget {
  const _AppointmentBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.goNamed(RouteNames.home);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: AppIcon.iconBack,
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({required this.items, required this.onRefresh});

  final List<AppointmentSummary> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? const _EmptyView()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _AppointmentCard(
                  appointment: items[index],
                  onTap: () => context.pushNamed(
                    RouteNames.viewingDetail,
                    pathParameters: {'appointmentId': items[index].id},
                  ),
                );
              },
            ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onTap});

  final AppointmentSummary appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: appointment.coverImage.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFF1F5FA),
                          child: Icon(Icons.home_work_outlined),
                        )
                      : Image.network(
                          appointment.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFF1F5FA),
                            child: Icon(Icons.home_work_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.houseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(
                          label: appointment.sourceLabel,
                          color: appointment.sourceType == 'PLATFORM'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0E9F6E),
                        ),
                        _Tag(
                          label: appointment.viewingModeLabel,
                          color: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _formatRange(
                        appointment.appointmentStartAt,
                        appointment.appointmentEndAt,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appointmentStatusLabel(appointment.status),
                      style: TextStyle(
                        color: appointmentStatusColor(appointment.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (appointment.availableActions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: appointment.availableActions
                            .take(2)
                            .map(
                              (action) => TextButton(
                                onPressed: onTap,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(_summaryActionLabel(action)),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 160),
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: Color(0xFF94A3B8),
        ),
        SizedBox(height: 16),
        Center(child: Text('暂无看房预约')),
      ],
    );
  }
}

// ignore: unused_element
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.tonal(
        onPressed: onRetry,
        child: const Text('加载失败，点击重试'),
      ),
    );
  }
}

String appointmentStatusLabel(String status) {
  return switch (status) {
    'PENDING_CONFIRMATION' => '等待确认',
    'RESCHEDULE_PROPOSED' => '等待确认新时间',
    'CONFIRMED' => '预约已确认',
    'READY' => '可以看房',
    'IN_PROGRESS' => '看房中',
    'COMPLETED' => '已完成',
    'REJECTED' => '已拒绝',
    'CANCELLED' => '已取消',
    'EXPIRED' => '已过期',
    'NO_SHOW' => '未到场',
    _ => status,
  };
}

String _summaryActionLabel(String action) {
  return switch (action) {
    'CANCEL' => '取消',
    'ACCEPT_RESCHEDULE' => '接受改期',
    'REJECT_RESCHEDULE' => '拒绝改期',
    'UNLOCK' => '蓝牙开门',
    'VIEW_PASSCODE' => '查看密码',
    'CONTACT_HOST' => '联系接待人',
    'NAVIGATE' => '导航',
    _ => '查看详情',
  };
}

Color appointmentStatusColor(String status) {
  return switch (status) {
    'CONFIRMED' || 'READY' || 'IN_PROGRESS' => const Color(0xFF2563EB),
    'COMPLETED' => const Color(0xFF0E9F6E),
    'REJECTED' ||
    'CANCELLED' ||
    'EXPIRED' ||
    'NO_SHOW' => const Color(0xFFDC2626),
    _ => const Color(0xFFD97706),
  };
}

String _formatRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '时间待确认';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${start.year}-${two(start.month)}-${two(start.day)} '
      '${two(start.hour)}:${two(start.minute)}-'
      '${two(end.hour)}:${two(end.minute)}';
}
