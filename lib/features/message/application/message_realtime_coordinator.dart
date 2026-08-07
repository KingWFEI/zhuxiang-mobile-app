import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../data/realtime/message_sse_client.dart';
import '../domain/entities/message_realtime_event.dart';

class MessageRealtimeCoordinator with WidgetsBindingObserver {
  MessageRealtimeCoordinator({
    required MessageSseClient client,
    required Future<void> Function() onReconcile,
    required Future<void> Function(MessageRealtimeEvent event) onEvent,
    required bool enabled,
    Future<String?> Function()? readAccessToken,
    Future<bool> Function()? refreshAccessToken,
    Future<void> Function()? onAuthFailure,
    Duration reconcileInterval = const Duration(minutes: 5),
    Duration heartbeatTimeout = const Duration(seconds: 70),
    Duration Function(int attempt)? retryDelay,
  }) : _client = client,
       _onReconcile = onReconcile,
       _onEvent = onEvent,
       _enabled = enabled,
       _readAccessToken = readAccessToken,
       _refreshAccessToken = refreshAccessToken,
       _onAuthFailure = onAuthFailure,
       _reconcileInterval = reconcileInterval,
       _heartbeatTimeout = heartbeatTimeout,
       _retryDelay = retryDelay {
    WidgetsBinding.instance.addObserver(this);
  }

  final MessageSseClient _client;
  final Future<void> Function() _onReconcile;
  final Future<void> Function(MessageRealtimeEvent event) _onEvent;
  final bool _enabled;
  final Future<String?> Function()? _readAccessToken;
  final Future<bool> Function()? _refreshAccessToken;
  final Future<void> Function()? _onAuthFailure;
  final Duration _reconcileInterval;
  final Duration _heartbeatTimeout;
  final Duration Function(int attempt)? _retryDelay;
  final Random _random = Random();

  String? _userId;
  CancelToken? _cancelToken;
  Timer? _reconnectTimer;
  Timer? _reconcileTimer;
  Timer? _heartbeatWatchdog;
  bool _connecting = false;
  bool _disposed = false;
  int _generation = 0;
  int _retryAttempt = 0;
  bool _disabledForSession = false;
  bool _tokenReady = false;
  Duration _serverRetry = const Duration(seconds: 1);

  bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  bool get _shouldConnect =>
      !_disposed &&
      _enabled &&
      !_disabledForSession &&
      _userId != null &&
      _tokenReady &&
      _isForeground;

  void updateUser(String? userId) {
    if (_userId == userId) return;
    _stopConnection();
    _userId = userId;
    _tokenReady = false;
    _retryAttempt = 0;
    _disabledForSession = false;
    if (userId != null && _isForeground) {
      unawaited(_waitForTokenAndStart(_generation));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_userId != null && !_tokenReady) {
        unawaited(_waitForTokenAndStart(_generation));
      } else if (_shouldConnect) {
        _startConnection();
      }
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopConnection();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopConnection();
  }

  void _startConnection() {
    if (!_shouldConnect || _connecting || _reconnectTimer != null) return;
    final generation = _generation;
    unawaited(_connect(generation));
  }

  Future<void> _waitForTokenAndStart(int generation) async {
    if (_readAccessToken == null) {
      _tokenReady = true;
      _startConnection();
      return;
    }
    for (var attempt = 0; attempt < 30; attempt++) {
      if (_disposed || generation != _generation || _userId == null || !_isForeground) return;
      final token = await _readAccessToken();
      if (token != null && token.isNotEmpty) {
        if (generation != _generation) return;
        _tokenReady = true;
        _startConnection();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _connect(int generation) async {
    if (!_shouldConnect || _connecting || generation != _generation) return;
    _connecting = true;
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    try {
      await for (final rawEvent in _client.connect(cancelToken)) {
        if (!_shouldConnect || generation != _generation) return;
        _resetHeartbeatWatchdog();
        if (rawEvent.retry != null) _serverRetry = rawEvent.retry!;
        final event = MessageRealtimeEvent.fromSse(rawEvent);
        if (event.type == 'connected') {
          _retryAttempt = 0;
          _startReconciliation();
          await _onReconcile();
        } else if (event.type != 'heartbeat') {
          await _onEvent(event);
        }
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        _tokenReady = false;
        final refreshed = await (_refreshAccessToken?.call() ?? Future.value(false));
        if (refreshed && generation == _generation && !_disposed) {
          _tokenReady = true;
          _retryAttempt = 0;
        } else if (generation == _generation) {
          _disabledForSession = true;
          await _onAuthFailure?.call();
        }
      } else if (statusCode == 403 || statusCode == 404) {
        _disabledForSession = true;
      } else if (!CancelToken.isCancel(error) && generation == _generation) {
        _scheduleReconnect();
      }
    } on Object {
      if (generation == _generation) _scheduleReconnect();
    } finally {
      if (identical(_cancelToken, cancelToken)) {
        _cancelToken = null;
        _connecting = false;
        if (_shouldConnect && generation == _generation) {
          _scheduleReconnect();
        }
      }
    }
  }

  void _scheduleReconnect() {
    if (!_shouldConnect || _disabledForSession || _reconnectTimer != null) {
      return;
    }
    final delay = _retryDelay?.call(_retryAttempt) ?? _defaultRetryDelay();
    _retryAttempt++;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _startConnection();
    });
  }

  Duration _defaultRetryDelay() {
    final baseSeconds = min(30, 1 << min(_retryAttempt, 5));
    final serverMilliseconds = _serverRetry.inMilliseconds;
    final baseMilliseconds = max(baseSeconds * 1000, serverMilliseconds);
    final jitter = _random.nextInt(max(1, baseMilliseconds ~/ 5));
    return Duration(milliseconds: baseMilliseconds + jitter);
  }

  void _startReconciliation() {
    _reconcileTimer?.cancel();
    _reconcileTimer = Timer.periodic(_reconcileInterval, (_) {
      if (_shouldConnect) unawaited(_onReconcile());
    });
  }

  void _resetHeartbeatWatchdog() {
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = Timer(_heartbeatTimeout, () {
      _cancelToken?.cancel('message realtime heartbeat timeout');
    });
  }

  void _stopConnection() {
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _cancelToken?.cancel('message realtime connection stopped');
    _cancelToken = null;
    _connecting = false;
  }
}
