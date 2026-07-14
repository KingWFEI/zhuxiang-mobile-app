import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// 房源位置地图页 —— 底部信息卡 + 清晰瓦片 + 缩放限制
class HouseMapPage extends StatefulWidget {
  const HouseMapPage({
    required this.latitude,
    required this.longitude,
    required this.houseTitle,
    this.houseAddress = '',
    super.key,
  });

  final double latitude;
  final double longitude;
  final String houseTitle;
  final String houseAddress;

  @override
  State<HouseMapPage> createState() => _HouseMapPageState();
}

class _HouseMapPageState extends State<HouseMapPage> {
  late final MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = LatLng(widget.latitude, widget.longitude);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        title: Text(widget.houseTitle, style: AppTextStyles.titleMedium),
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: pos,
              initialZoom: 17,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              // 高德矢量瓦片（retina，清晰度高）
              TileLayer(
                urlTemplate:
                    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                maxZoom: 18,
                userAgentPackageName: 'com.zhuxiang.zhuxiang_app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: pos,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
          // 底部信息卡
          Positioned(
            left: AppSpacing.pageHorizontal,
            right: AppSpacing.pageHorizontal,
            bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.houseTitle,
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.textPrimary)),
                  if (widget.houseAddress.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(widget.houseAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
