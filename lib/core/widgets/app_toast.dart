import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

enum AppToastType { success, error, normal }

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _dismissTimer;
  static _ToastWidgetState? _currentState;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.normal,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _dismiss();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        onMounted: (state) => _currentState = state,
        onDismissRequested: () => _dismiss(),
      ),
    );

    _entry = entry;
    _currentState = null;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    final state = _currentState;
    _currentState = null;
    if (state != null) {
      state.hide(() {
        _entry?.remove();
        _entry = null;
      });
    } else {
      _entry?.remove();
      _entry = null;
    }
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onMounted,
    required this.onDismissRequested,
  });

  final String message;
  final AppToastType type;
  final ValueChanged<_ToastWidgetState> onMounted;
  final VoidCallback onDismissRequested;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.onMounted(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void hide(VoidCallback onDone) {
    if (!mounted) {
      onDone();
      return;
    }
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 200), onDone);
  }

  IconData get _icon => switch (widget.type) {
    AppToastType.success => Icons.check_circle_rounded,
    AppToastType.error => Icons.cancel_rounded,
    AppToastType.normal => Icons.info_rounded,
  };

  Color get _iconColor => switch (widget.type) {
    AppToastType.success => AppColors.success,
    AppToastType.error => AppColors.error,
    AppToastType.normal => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      left: AppSpacing.xl,
      right: AppSpacing.xl,
      bottom: 36 + bottomInset,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_icon, color: _iconColor, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
