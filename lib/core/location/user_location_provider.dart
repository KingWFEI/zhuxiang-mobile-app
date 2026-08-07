import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/storage_keys.dart';
import '../network/api_client_provider.dart';
import '../network/api_result.dart';
import '../storage/storage_service.dart';

/// 用户定位状态。
class UserLocationState {
  const UserLocationState({
    this.city = '',
    this.district = '',
    this.isLoading = false,
    this.hasLocation = false,
    this.error,
  });

  final String city;
  final String district;
  final bool isLoading;
  final bool hasLocation;
  final String? error;

  bool get hasSelection => city.isNotEmpty;

  UserLocationState copyWith({
    String? city,
    String? district,
    bool? isLoading,
    bool? hasLocation,
    String? error,
    bool clearError = false,
  }) {
    return UserLocationState(
      city: city ?? this.city,
      district: district ?? this.district,
      isLoading: isLoading ?? this.isLoading,
      hasLocation: hasLocation ?? this.hasLocation,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// 管理用户 GPS 定位与反向地理编码。
class UserLocationNotifier extends Notifier<UserLocationState> {
  @override
  UserLocationState build() {
    // 从本地存储恢复上次选择的城市
    final storage = StorageService.localStorage;
    final city = storage.getString(StorageKeys.selectedCity) ?? '';
    final district = storage.getString(StorageKeys.selectedDistrict) ?? '';
    debugPrint('[LOCATION] build() city=$city district=$district');
    if (city.isNotEmpty) {
      return UserLocationState(
        city: city,
        district: district,
        hasLocation: true,
      );
    }
    return const UserLocationState();
  }

  /// 请求定位权限并获取当前位置。仅在用户主动触发时调用。
  Future<void> fetch() async {
    // 防止找房页初始化、下拉刷新和手动定位同时触发多个 GPS/逆地理请求。
    if (state.isLoading) return;
    debugPrint('[LOCATION] fetch() started');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[LOCATION] permission=$permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[LOCATION] after request: permission=$permission');
        if (permission == LocationPermission.denied) {
          debugPrint('[LOCATION] ❌ permission denied');
          state = state.copyWith(isLoading: false, error: '定位权限被拒绝');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LOCATION] ❌ permission denied forever');
        state = state.copyWith(isLoading: false, error: '定位权限已关闭，请在设置中开启');
        return;
      }

      debugPrint('[LOCATION] getting position...');

      // 优先用缓存位置（毫秒级），同时发起一次低精度 GPS 用于后续刷新
      final lastPos = await Geolocator.getLastKnownPosition();
      Position? freshPosition;
      try {
        freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.lowest,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(const Duration(seconds: 8));
      } on Exception {
        // GPS 超时不阻塞，后续用缓存
      }

      Position position;
      if (freshPosition != null) {
        position = freshPosition;
        debugPrint('[LOCATION] using fresh GPS');
      } else if (lastPos != null) {
        position = lastPos;
        debugPrint('[LOCATION] using last known cache');
      } else {
        state = state.copyWith(isLoading: false, error: '定位超时，请移至开阔地带或手动选择城市');
        return;
      }
      debugPrint(
        '[LOCATION] position: lat=${position.latitude}, lng=${position.longitude}',
      );

      final address = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      debugPrint(
        '[LOCATION] reverse geocode: city=${address.city}, district=${address.district}',
      );

      if (address.city.isEmpty) {
        debugPrint('[LOCATION] ❌ reverse geocode returned empty, not saving');
        state = state.copyWith(isLoading: false, error: '无法解析当前城市，请手动选择');
        return;
      }

      _saveCity(address.city, address.district);
      state = UserLocationState(
        city: address.city,
        district: address.district,
        isLoading: false,
        hasLocation: true,
      );
      debugPrint('[LOCATION] ✅ state updated: city=${address.city}');
    } on LocationServiceDisabledException {
      debugPrint('[LOCATION] ❌ GPS service disabled');
      state = state.copyWith(isLoading: false, error: '请开启手机定位服务');
    } on TimeoutException {
      debugPrint('[LOCATION] ❌ outer timeout');
      state = state.copyWith(isLoading: false, error: '定位超时，请移至开阔地带或手动选择城市');
    } on Exception catch (e) {
      debugPrint('[LOCATION] ❌ error: $e');
      state = state.copyWith(isLoading: false, error: '定位失败，请检查网络');
    }
  }

  /// 手动选择城市，写入本地存储。
  void setManual(String city, String district) {
    debugPrint('[LOCATION] setManual city=$city district=$district');
    _saveCity(city, district);
    state = UserLocationState(
      city: city,
      district: district,
      hasLocation: true,
    );
  }

  void _saveCity(String city, String district) {
    final storage = StorageService.localStorage;
    storage.setString(StorageKeys.selectedCity, city);
    if (district.isNotEmpty) {
      storage.setString(StorageKeys.selectedDistrict, district);
    }
  }

  /// 通过后端代理调用高德 REST API 进行反向地理编码（key 在后端不泄露）。
  Future<({String city, String district})> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.get(
        '/location/reverse-geocode',
        queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
      );
      if (result is ApiSuccess<Response<dynamic>>) {
        final body = result.data.data;
        if (body is Map<String, dynamic>) {
          final code = body['code'] as int? ?? -1;
          if (code != 200 && code != 0) return (city: '', district: '');
          final data = body['data'] as Map<String, dynamic>?;
          if (data != null) {
            // 直辖市（重庆/北京/上海/天津）的 city 可能为空，退回到 province
            var city = (data['city'] ?? '').toString();
            if (city.isEmpty || city == '[]') {
              city = (data['province'] ?? '').toString();
            }
            final district = (data['district'] ?? '').toString();
            debugPrint(
              '[LOCATION] reverse geocode success: city=$city district=$district',
            );
            return (city: city, district: district);
          }
        }
      }
      debugPrint('[LOCATION] ❌ reverse geocode failed');
      return (city: '', district: '');
    } on Exception catch (e) {
      debugPrint('[LOCATION] ❌ reverse geocode error: $e');
      return (city: '', district: '');
    }
  }

  /// 手动刷新定位。
  Future<void> refresh() => fetch();
}

/// 全局定位 Provider。
final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocationState>(
      UserLocationNotifier.new,
    );
