import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ttlock_ble_service.dart';

class NearbyLocksState {
  const NearbyLocksState({this.locks = const [], this.isScanning = false});
  final List<ScannedLockDevice> locks;
  final bool isScanning;
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
    state = NearbyLocksState(
      locks: _buffer.values.toList(growable: false),
      isScanning: state.isScanning,
    );
    _buffer.clear();
  }

  void onScanStarted() {
    _debounceTimer?.cancel();
    _buffer.clear();
    state = const NearbyLocksState(isScanning: true);
  }

  void onDeviceFound(ScannedLockDevice device) {
    _buffer[device.mac] = device;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _flush);
  }

  void onScanStopped() {
    _debounceTimer?.cancel();
    _flush();
    state = NearbyLocksState(locks: state.locks, isScanning: false);
    _buffer.clear();
  }
}

final nearbyLocksProvider =
    NotifierProvider<NearbyLocksNotifier, NearbyLocksState>(
      NearbyLocksNotifier.new,
    );
