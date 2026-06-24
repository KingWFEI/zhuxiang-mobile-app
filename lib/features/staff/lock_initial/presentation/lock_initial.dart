import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../data/staff_house.dart';
import '../data/staff_house_providers.dart';
import '../services/ttlock_ble_service.dart';

class LockInitial extends ConsumerStatefulWidget {
  const LockInitial({super.key});

  @override
  ConsumerState<LockInitial> createState() => _LockInitialState();
}

class _LockInitialState extends ConsumerState<LockInitial> {
  final _searchController = TextEditingController();
  final _ttlockService = TtlockBleService();

  StaffHouse? _selectedHouse;
  bool _isScanningLocks = false;
  List<ScannedLockDevice> _nearbyLocks = const [];
  String _keyword = '';

  bool get _canScanLocks => _selectedHouse != null && !_isScanningLocks;

  @override
  void dispose() {
    _searchController.dispose();
    _ttlockService.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final housesAsync = ref.watch(unboundSmartLockHousesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('初始化门锁')),
      body: SafeArea(
        child: housesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorView(
            message: '房源列表加载失败',
            onRetry: () => ref.invalidate(unboundSmartLockHousesProvider),
          ),
          data: (houses) {
            final filteredHouses = _filterHouses(houses);
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(unboundSmartLockHousesProvider);
                await ref.read(unboundSmartLockHousesProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _SelectedHousePanel(
                    house: _selectedHouse,
                    resultCount: _nearbyLocks.length,
                    isScanningLocks: _isScanningLocks,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _HouseSearchField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _keyword = value.trim().toLowerCase());
                    },
                    onClear: _keyword.isEmpty
                        ? null
                        : () {
                            _searchController.clear();
                            setState(() => _keyword = '');
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HouseListHeader(
                    totalCount: houses.length,
                    filteredCount: filteredHouses.length,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (houses.isEmpty)
                    const _EmptyView(message: '暂无支持智能锁且未绑定门锁的房源')
                  else if (filteredHouses.isEmpty)
                    const _EmptyView(message: '没有匹配的房源')
                  else
                    _HousePickerList(
                      houses: filteredHouses,
                      selectedHouseId: _selectedHouse?.id,
                      onSelected: _selectHouse,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: _canScanLocks ? _startScanLocks : null,
                    icon: _isScanningLocks
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bluetooth_searching, size: 18),
                    label: Text(_isScanningLocks ? '正在搜索' : '开始搜索附近门锁'),
                  ),
                  if (_nearbyLocks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _NearbyLockList(locks: _nearbyLocks),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<StaffHouse> _filterHouses(List<StaffHouse> houses) {
    if (_keyword.isEmpty) return houses;
    return houses
        .where((house) => house.searchText.contains(_keyword))
        .toList(growable: false);
  }

  void _selectHouse(StaffHouse house) {
    setState(() {
      _selectedHouse = house;
      _nearbyLocks = const [];
    });
  }

  Future<void> _startScanLocks() async {
    if (!_canScanLocks) return;

    setState(() {
      _isScanningLocks = true;
      _nearbyLocks = const [];
    });

    try {
      await _ttlockService.init();
      await _ttlockService.startScanning(
        onDeviceFound: (device) {
          if (!mounted) return;
          setState(() {
            final existingIndex = _nearbyLocks.indexWhere(
              (item) => item.mac == device.mac,
            );
            if (existingIndex == -1) {
              _nearbyLocks = [..._nearbyLocks, device];
              return;
            }
            final updated = _nearbyLocks.toList();
            updated[existingIndex] = device;
            _nearbyLocks = updated;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isScanningLocks = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('扫描门锁失败：$error')));
    }
  }
}

class _SelectedHousePanel extends StatelessWidget {
  const _SelectedHousePanel({
    required this.house,
    required this.resultCount,
    required this.isScanningLocks,
  });

  final StaffHouse? house;
  final int resultCount;
  final bool isScanningLocks;

  @override
  Widget build(BuildContext context) {
    final statusText = isScanningLocks
        ? '正在搜索附近门锁'
        : resultCount > 0
        ? '已发现 $resultCount 个门锁'
        : house == null
        ? '请选择需要初始化门锁的房源'
        : house!.roomLabel.isEmpty
        ? house!.title
        : '${house!.title} · ${house!.roomLabel}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.lock_outline, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('初始化门锁', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(statusText, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseSearchField extends StatelessWidget {
  const _HouseSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: '搜索房源',
        hintText: '输入标题、位置、楼栋、房间号',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: onClear),
      ),
    );
  }
}

class _HouseListHeader extends StatelessWidget {
  const _HouseListHeader({
    required this.totalCount,
    required this.filteredCount,
  });

  final int totalCount;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '未绑定门锁房源 $filteredCount/$totalCount',
      style: AppTextStyles.bodySmall,
    );
  }
}

class _HousePickerList extends StatelessWidget {
  const _HousePickerList({
    required this.houses,
    required this.selectedHouseId,
    required this.onSelected,
  });

  final List<StaffHouse> houses;
  final String? selectedHouseId;
  final ValueChanged<StaffHouse> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < houses.length; index++) ...[
            _HouseTile(
              house: houses[index],
              isSelected: houses[index].id == selectedHouseId,
              onTap: () => onSelected(houses[index]),
            ),
            if (index != houses.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _HouseTile extends StatelessWidget {
  const _HouseTile({
    required this.house,
    required this.isSelected,
    required this.onTap,
  });

  final StaffHouse house;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (house.location.isNotEmpty) house.location,
      if (house.roomLabel.isNotEmpty) house.roomLabel,
      if (house.address.isNotEmpty) house.address,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? AppColors.primary
            : AppColors.primaryLight,
        child: Icon(
          isSelected ? Icons.check : Icons.home_work_outlined,
          color: isSelected ? Colors.white : AppColors.primary,
        ),
      ),
      title: Text(house.title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _NearbyLockList extends StatelessWidget {
  const _NearbyLockList({required this.locks});

  final List<ScannedLockDevice> locks;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text('附近门锁', style: AppTextStyles.titleMedium),
          ),
          for (final lock in locks) _NearbyLockTile(lock: lock),
        ],
      ),
    );
  }
}

class _NearbyLockTile extends StatelessWidget {
  const _NearbyLockTile({required this.lock});

  final ScannedLockDevice lock;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.lock, color: AppColors.primary),
      ),
      title: Text(lock.name.isEmpty ? '未命名门锁' : lock.name),
      subtitle: Text(
        '${lock.mac}  信号 ${lock.rssi} dBm  ${lock.isInited ? '已初始化' : '未初始化'}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        lock.battery < 0 ? '--%' : '${lock.battery}%',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message, style: AppTextStyles.bodyMedium),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 36),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}
