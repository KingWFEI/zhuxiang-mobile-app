import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/community.dart';
import '../../data/providers/landlord_providers.dart';

class MapPoiSelector extends ConsumerStatefulWidget {
  const MapPoiSelector({required this.initialKeyword, super.key});

  final String initialKeyword;

  @override
  ConsumerState<MapPoiSelector> createState() => _MapPoiSelectorState();
}

class _MapPoiSelectorState extends ConsumerState<MapPoiSelector> {
  static const _defaultCenter = LatLng(29.563, 106.5516);

  late final MapController _mapController;
  late final TextEditingController _searchController;
  Timer? _moveDebounce;
  List<MapPoi> _pois = const [];
  bool _loading = false;
  bool _importing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController(text: widget.initialKeyword);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchByKeyword());
  }

  @override
  void dispose() {
    _moveDebounce?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchByKeyword() async {
    final keyword = _searchController.text.trim();
    if (keyword.length < 2) return;
    await _runSearch(
      () => ref.read(communityServiceProvider).searchMapPois(keyword: keyword),
      moveToFirst: true,
    );
  }

  void _onMapMoved(MapEvent event) {
    if (event is! MapEventMoveEnd) return;
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 450), () {
      final center = event.camera.center;
      final keyword = _searchController.text.trim();
      if (keyword.length < 2) return;
      _runSearch(
        () => ref
            .read(communityServiceProvider)
            .searchMapPois(
              keyword: keyword,
              longitude: center.longitude,
              latitude: center.latitude,
            ),
      );
    });
  }

  Future<void> _runSearch(
    Future<List<MapPoi>> Function() request, {
    bool moveToFirst = false,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pois = await request();
      if (!mounted) return;
      setState(() => _pois = pois);
      if (moveToFirst && pois.isNotEmpty) {
        final first = pois.first;
        _mapController.move(LatLng(first.latitude, first.longitude), 16);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPoi(MapPoi poi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认小区'),
        content: Text('是否选择「${poi.name}」作为房源小区？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认选择'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);
    try {
      final community = await ref
          .read(communityServiceProvider)
          .createFromMap(poi);
      if (!mounted) return;
      Navigator.of(context).pop(community);
    } on Object catch (error) {
      if (mounted) {
        AppToast.show(context, '保存小区失败：$error', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        title: const Text('从地图中查找小区'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultCenter,
                        initialZoom: 12,
                        minZoom: 5,
                        maxZoom: 18,
                        onMapEvent: _onMapMoved,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}',
                          subdomains: const ['1', '2', '3', '4'],
                          maxZoom: 18,
                          userAgentPackageName: 'com.zhuxiang.zhuxiang_app',
                        ),
                      ],
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 38),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: AppColors.primary,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      top: AppSpacing.md,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.card,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _searchByKeyword(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: '搜索小区名称',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              onPressed: _searchByKeyword,
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.card,
                        ),
                        child: IconButton(
                          tooltip: '刷新当前区域',
                          onPressed: () {
                            final center = _mapController.camera.center;
                            _runSearch(
                              () => ref
                                  .read(communityServiceProvider)
                                  .searchMapPois(
                                    keyword: _searchController.text.trim(),
                                    longitude: center.longitude,
                                    latitude: center.latitude,
                                  ),
                            );
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '附近小区',
                                style: AppTextStyles.titleMedium,
                              ),
                            ),
                            Text('拖动地图刷新', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Expanded(child: _buildPoiList()),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_importing)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppSpacing.md),
                        Text('正在保存小区…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPoiList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }
    if (_pois.isEmpty) {
      return Center(child: Text('当前区域暂无搜索结果', style: AppTextStyles.bodyMedium));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: _pois.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
      itemBuilder: (context, index) {
        final poi = _pois[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            child: Icon(Icons.location_on_outlined),
          ),
          title: Text(
            poi.name,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: poi.locationLabel.isEmpty
              ? null
              : Text(
                  poi.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _selectPoi(poi),
        );
      },
    );
  }
}
