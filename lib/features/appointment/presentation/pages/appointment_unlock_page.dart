import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../staff/lock_initial/services/ttlock_ble_service.dart';
import '../../data/models/appointment_models.dart';
import '../../data/providers/appointment_providers.dart';

final _appointmentAccessProvider = FutureProvider.autoDispose
    .family<AppointmentAccess, String>((ref, appointmentId) {
      return ref.watch(appointmentServiceProvider).access(appointmentId);
    });

class AppointmentUnlockPage extends ConsumerStatefulWidget {
  const AppointmentUnlockPage({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  ConsumerState<AppointmentUnlockPage> createState() =>
      _AppointmentUnlockPageState();
}

class _AppointmentUnlockPageState extends ConsumerState<AppointmentUnlockPage> {
  bool _unlocking = false;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(_appointmentAccessProvider(widget.appointmentId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('预约开门'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.lock_open_rounded,
              size: 72,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 18),
            Text(
              '权限状态：${value.status}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 26),
            if (value.passcodeAvailable)
              _CredentialCard(
                title: '临时开门密码',
                value: value.passcode,
                validity: _formatPasscodeValidity(
                  value.passcodeValidFrom,
                  value.passcodeValidTo,
                ),
                onCopy: () async {
                  await Clipboard.setData(ClipboardData(text: value.passcode));
                  if (context.mounted) {
                    AppToast.show(context, '密码已复制', type: AppToastType.success);
                  }
                },
              ),
            if (value.bluetoothEnabled) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _unlocking ? null : () => _unlock(value.lockData),
                  icon: _unlocking
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_rounded),
                  label: Text(_unlocking ? '正在开门' : '蓝牙开门'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              '开门凭证仅在本次预约时间内有效，请勿转发给他人。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlock(String lockData) async {
    setState(() => _unlocking = true);
    try {
      final service = TtlockBleService();
      await service.init();
      final result = await service.unlockByLockData(lockData);
      await ref
          .read(appointmentServiceProvider)
          .reportUnlock(
            widget.appointmentId,
            success: result.success,
            errorMessage: result.errorMessage,
          );
      if (!mounted) return;
      AppToast.show(
        context,
        result.success ? '开门成功' : (result.errorMessage ?? '开门失败'),
        type: result.success ? AppToastType.success : AppToastType.error,
      );
    } on Object catch (error) {
      await ref
          .read(appointmentServiceProvider)
          .reportUnlock(
            widget.appointmentId,
            success: false,
            errorMessage: '$error',
          );
      if (mounted) {
        AppToast.show(context, '开门失败：$error', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.title,
    required this.value,
    required this.validity,
    required this.onCopy,
  });

  final String title;
  final String value;
  final String validity;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (validity.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '密码有效时间',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    validity,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1E3A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('复制密码'),
          ),
          const Text(
            '到达门锁后输入密码，并按 # 键确认',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _formatPasscodeValidity(DateTime? from, DateTime? to) {
  if (from == null || to == null) return '';
  final start = from.toLocal();
  final end = to.toLocal();
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (sameDay) {
    return '${_date(start)} ${_time(start)}–${_time(end)}';
  }
  return '${_date(start)} ${_time(start)} 至 ${_date(end)} ${_time(end)}';
}

String _date(DateTime value) =>
    '${value.year}-${_two(value.month)}-${_two(value.day)}';

String _time(DateTime value) => '${_two(value.hour)}:${_two(value.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');
