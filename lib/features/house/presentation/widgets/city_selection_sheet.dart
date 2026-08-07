import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/location/user_location_provider.dart';
import '../../../../core/storage/storage_service.dart';

String _displayCityName(String city) {
  return city.endsWith('市') ? city : '$city市';
}

/// 热门城市列表。
const _hotCities = <String>[
  '重庆',
  '北京',
  '上海',
  '广州',
  '深圳',
  '成都',
  '杭州',
  '武汉',
  '南京',
  '西安',
  '天津',
  '苏州',
  '长沙',
  '郑州',
  '青岛',
];

/// 完整城市索引（拼音首字母分组）。
const _allCities = <String, List<String>>{
  'A': ['鞍山', '安庆', '安阳', '安康'],
  'B': ['北京', '保定', '包头', '蚌埠', '宝鸡'],
  'C': ['重庆', '成都', '长沙', '长春', '常州', '沧州', '承德', '郴州'],
  'D': ['大连', '东莞', '大庆', '大同', '德阳'],
  'F': ['福州', '佛山', '抚顺', '阜阳'],
  'G': ['广州', '贵阳', '桂林', '赣州', '广元'],
  'H': ['杭州', '哈尔滨', '合肥', '海口', '呼和浩特', '惠州', '邯郸', '衡阳'],
  'J': ['济南', '吉林', '济宁', '嘉兴', '金华', '锦州', '九江'],
  'K': ['昆明', '开封'],
  'L': ['兰州', '洛阳', '柳州', '聊城', '临沂', '连云港'],
  'M': ['绵阳', '牡丹江', '马鞍山'],
  'N': ['南京', '宁波', '南昌', '南宁', '南通', '南阳'],
  'P': ['平顶山', '莆田'],
  'Q': ['青岛', '秦皇岛', '泉州', '齐齐哈尔'],
  'S': ['上海', '深圳', '沈阳', '石家庄', '苏州', '汕头', '绍兴'],
  'T': ['天津', '太原', '唐山', '泰安', '台州'],
  'W': ['武汉', '无锡', '乌鲁木齐', '温州', '威海', '芜湖', '潍坊'],
  'X': ['西安', '厦门', '徐州', '西宁', '襄阳', '咸阳', '新乡'],
  'Y': ['银川', '扬州', '烟台', '宜昌', '岳阳', '运城'],
  'Z': ['郑州', '珠海', '中山', '镇江', '淄博', '株洲'],
};

class CitySelectionSheet extends ConsumerStatefulWidget {
  const CitySelectionSheet({super.key});

  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final storage = StorageService.localStorage;
    final saved = storage.getString(StorageKeys.selectedCity);
    if (saved != null && saved.isNotEmpty) return;
    await show(context);
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CitySelectionSheet(),
    );
  }

  @override
  ConsumerState<CitySelectionSheet> createState() => _CitySelectionSheetState();
}

class _CitySelectionSheetState extends ConsumerState<CitySelectionSheet> {
  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(userLocationProvider);
    final height = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖拽条
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题
          const Text(
            '选择城市',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          // ── 当前定位状态 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _LocationBar(state: locationState, onRefresh: _locate),
          ),
          const Divider(height: 24),
          // ── 列表 ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              children: [
                Text(
                  '热门城市',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _HotCityGrid(onSelect: _selectCity),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '全部城市',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final letter in _allCities.keys)
                  _CityGroup(
                    letter: letter,
                    cities: _allCities[letter]!,
                    onSelect: _selectCity,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectCity(String city) {
    ref.read(userLocationProvider.notifier).setManual(city, '');
    Navigator.of(context).pop();
  }

  Future<void> _locate() async {
    final notifier = ref.read(userLocationProvider.notifier);
    debugPrint('[CITY_SHEET] re-locating');
    await notifier.fetch();
    // 不关闭弹窗，让用户看到定位结果
  }
}

// ── 定位状态栏 ──────────────────────────────────────────────

class _LocationBar extends StatelessWidget {
  const _LocationBar({required this.state, required this.onRefresh});

  final UserLocationState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.hasLocation
                      ? '${state.city} · ${state.district}'
                      : '未定位',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!state.hasLocation && state.error != null)
                  Text(
                    state.error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: state.isLoading ? null : onRefresh,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '重新定位',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 热门城市 ─────────────────────────────────────────────────

class _HotCityGrid extends StatelessWidget {
  const _HotCityGrid({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _hotCities.map((city) {
        return Material(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onSelect(city),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width:
                  (MediaQuery.of(context).size.width - 56 - AppSpacing.sm * 2) /
                  3,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              alignment: Alignment.center,
              child: Text(
                _displayCityName(city),
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 字母分组 ─────────────────────────────────────────────────

class _CityGroup extends StatelessWidget {
  const _CityGroup({
    required this.letter,
    required this.cities,
    required this.onSelect,
  });

  final String letter;
  final List<String> cities;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            letter,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 2,
            children: cities.map((city) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(city),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      _displayCityName(city),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
