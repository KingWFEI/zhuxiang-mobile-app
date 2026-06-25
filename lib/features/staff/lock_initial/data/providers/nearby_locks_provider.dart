import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ttlock_ble_service.dart';

class NearbyLocksState {
  const NearbyLocksState({this.locks = const [], this.isScanning = false});
  final List<ScannedLockDevice> locks;
  final bool isScanning;
  NearbyLocksState copyWith({
    List<ScannedLockDevice>? locks,
    bool? isScanning,
  }) {
    return NearbyLocksState(
      locks: locks ?? this.locks,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class NearbyLocksNotifier extends Notifier<NearbyLocksState> {
  Timer? _debounceTimer;
  final Map<String, ScannedLockDevice> _buffer = {};

  @override
  NearbyLocksState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _buffer.clear();
    });

    return const NearbyLocksState();
  }

  void _flush() {
    if (_buffer.isEmpty) return;
    state = state.copyWith(locks: _buffer.values.toList(growable: false));
    _buffer.clear();
  }

  void onScanStarted() {
    _debounceTimer?.cancel();
    _buffer.clear();
    state = const NearbyLocksState(isScanning: true);
  }

  void onDeviceFound(ScannedLockDevice device) {
    if (device.mac.isEmpty) return;

    _buffer[device.mac] = device;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _flush);
  }

  void onScanStopped() {
    _debounceTimer?.cancel();
    _flush();
    state = state.copyWith(isScanning: false);
    _buffer.clear();
  }

  /// 管理员初始化流程专用：
  /// 停止扫描后，只展示找到的这一把未初始化门锁
  void setFoundLockAfterStopped(ScannedLockDevice device) {
    _debounceTimer?.cancel();
    _buffer.clear();

    state = NearbyLocksState(locks: [device], isScanning: false);
  }

  void clear() {
    _debounceTimer?.cancel();
    _buffer.clear();

    state = const NearbyLocksState();
  }
}

final nearbyLocksProvider =
    NotifierProvider<NearbyLocksNotifier, NearbyLocksState>(
      NearbyLocksNotifier.new,
    );
