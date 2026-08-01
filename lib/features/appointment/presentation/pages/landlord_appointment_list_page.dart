import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/appointment_models.dart';
import '../../data/providers/appointment_providers.dart';
import 'appointment_list_page.dart';

class LandlordAppointmentListPage extends ConsumerWidget {
  const LandlordAppointmentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(landlordAppointmentsProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('看房预约'),
          centerTitle: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '待确认'),
              Tab(text: '今日预约'),
              Tab(text: '即将开始'),
              Tab(text: '历史预约'),
            ],
          ),
        ),
        body: appointments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: FilledButton.tonal(
              onPressed: () => ref.invalidate(landlordAppointmentsProvider),
              child: const Text('加载失败，点击重试'),
            ),
          ),
          data: (items) {
            final now = DateTime.now();
            bool isToday(AppointmentSummary item) {
              final value = item.appointmentStartAt;
              return value != null && DateUtils.isSameDay(value, now);
            }

            bool isHistory(AppointmentSummary item) {
              return const {
                'COMPLETED',
                'REJECTED',
                'CANCELLED',
                'EXPIRED',
                'NO_SHOW',
              }.contains(item.status);
            }

            return TabBarView(
              children: [
                _AppointmentList(
                  items: items
                      .where((item) => item.status == 'PENDING_CONFIRMATION')
                      .toList(growable: false),
                  onRefresh: () =>
                      ref.refresh(landlordAppointmentsProvider.future),
                ),
                _AppointmentList(
                  items: items.where(isToday).toList(growable: false),
                  onRefresh: () =>
                      ref.refresh(landlordAppointmentsProvider.future),
                ),
                _AppointmentList(
                  items: items
                      .where((item) {
                        final start = item.appointmentStartAt;
                        return !isHistory(item) &&
                            !isToday(item) &&
                            start != null &&
                            start.isAfter(now);
                      })
                      .toList(growable: false),
                  onRefresh: () =>
                      ref.refresh(landlordAppointmentsProvider.future),
                ),
                _AppointmentList(
                  items: items.where(isHistory).toList(growable: false),
                  onRefresh: () =>
                      ref.refresh(landlordAppointmentsProvider.future),
                ),
              ],
            );
          },
        ),
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
          ? ListView(
              children: const [
                SizedBox(height: 160),
                Icon(
                  Icons.event_note_outlined,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 16),
                Center(child: Text('暂无租客预约')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(item.houseTitle),
                  subtitle: Text(
                    '${appointmentStatusLabel(item.status)} · '
                    '${_format(item.appointmentStartAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.pushNamed(
                    RouteNames.landlordAppointmentDetail,
                    pathParameters: {'appointmentId': item.id},
                  ),
                );
              },
            ),
    );
  }
}

String _format(DateTime? value) {
  if (value == null) return '时间待确认';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.month}月${value.day}日 '
      '${two(value.hour)}:${two(value.minute)}';
}
