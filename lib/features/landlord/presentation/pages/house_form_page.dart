import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/community.dart';
import '../../data/models/landlord_house.dart';
import '../../data/providers/landlord_providers.dart';
import '../widgets/community_picker.dart';

class LandlordHouseFormPage extends ConsumerStatefulWidget {
  const LandlordHouseFormPage({this.houseId, super.key});

  final String? houseId;

  bool get isEdit => houseId != null;

  @override
  ConsumerState<LandlordHouseFormPage> createState() =>
      _LandlordHouseFormPageState();
}

class _LandlordHouseFormPageState extends ConsumerState<LandlordHouseFormPage> {
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;
  var _uploadingImages = false;

  late final _titleCtrl = TextEditingController();
  late final _buildingCtrl = TextEditingController();
  late final _unitCtrl = TextEditingController();
  late final _roomCtrl = TextEditingController();
  late final _priceCtrl = TextEditingController();
  late final _areaCtrl = TextEditingController();
  late final _floorCtrl = TextEditingController();
  late final _metroCtrl = TextEditingController();
  late final _descCtrl = TextEditingController();
  late final _availableDateCtrl = TextEditingController();
  late final _roomTypeCtrl = TextEditingController();

  Community? _community;
  String _rentMode = 'WHOLE_RENT';
  String _rentType = 'LONG_RENT';
  String _paymentMethod = '押一付一';
  String _orientation = '';
  String _decoration = '';
  String _coverUrl = '';
  final _imageUrls = <String>[];
  XFile? _propertyCertificateFile;
  String _propertyCertificateName = '';
  String _propertyCertificateStatus = '';
  String _propertyCertificateRemark = '';
  final _selectedFacilityIds = <String>{};
  final _selectedTagIds = <String>{};
  var _isSmartLock = false;
  var _isSelfViewingSupported = false;
  var _showDictionaryErrors = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadHouse();
  }

  Future<void> _loadHouse() async {
    try {
      final house = await ref
          .read(landlordHouseServiceProvider)
          .getHouseDetail(widget.houseId!);
      if (!mounted) return;
      _titleCtrl.text = house.title;
      _priceCtrl.text = house.priceYuan;
      _areaCtrl.text = house.area > 0 ? house.area.toString() : '';
      _floorCtrl.text = house.floor;
      _metroCtrl.text = house.metro;
      _descCtrl.text = house.description;
      _availableDateCtrl.text = house.availableDate;
      _buildingCtrl.text = house.building;
      _unitCtrl.text = house.unit;
      _roomCtrl.text = house.room;
      _coverUrl = house.coverImage;
      _imageUrls.addAll(house.imageUrls);
      _selectedFacilityIds.addAll(house.facilityIds);
      _selectedTagIds.addAll(house.tagIds);
      if (house.communityId.isNotEmpty) {
        _community = Community(
          id: house.communityId,
          name: house.communityName.isNotEmpty
              ? house.communityName
              : house.location,
          address: house.address,
          province: house.province,
          city: house.city,
          district: house.district,
          longitude: house.longitude,
          latitude: house.latitude,
        );
      }
      _rentMode = house.rentMode == 'SHARED_RENT'
          ? 'SHARED_RENT'
          : 'WHOLE_RENT';
      _rentType = switch (house.rentType) {
        'SHORT_RENT' => 'SHORT_RENT',
        'HOMESTAY' => 'HOMESTAY',
        _ => 'LONG_RENT',
      };
      _paymentMethod = _normalizePaymentMethod(house.paymentMethod);
      _roomTypeCtrl.text = house.roomType;
      _orientation = switch (house.orientation) {
        '朝南' || '南' => '南',
        '朝北' || '北' => '北',
        '朝东' || '东' => '东',
        '朝西' || '西' => '西',
        '南北通透' || '南北' => '南北',
        _ => '',
      };
      _decoration = _normalizeDecoration(house.decoration);
      _isSmartLock = house.isSmartLockSupported;
      _isSelfViewingSupported = house.isSelfViewingSupported;
      _propertyCertificateName = house.propertyCertificate?.originalName ?? '';
      _propertyCertificateStatus = house.propertyCertificate?.statusLabel ?? '';
      _propertyCertificateRemark =
          house.propertyCertificate?.reviewRemark ?? '';
      setState(() {});
    } on Object {
      if (mounted) {
        AppToast.show(context, '加载房源信息失败', type: AppToastType.error);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _buildingCtrl.dispose();
    _unitCtrl.dispose();
    _roomCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _floorCtrl.dispose();
    _metroCtrl.dispose();
    _descCtrl.dispose();
    _availableDateCtrl.dispose();
    _roomTypeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facilities = ref.watch(houseFacilitiesProvider);
    final tags = ref.watch(houseTagsProvider);
    final roomTypes = ref.watch(landlordHouseRoomTypesProvider);
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑房源' : '新增房源'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: AppIcon.iconBack,
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                AppSpacing.xl,
              ),
              children: [
                _buildIntroCard(),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.home_work_outlined,
                  title: '基本信息',
                  subtitle: '展示给租客的核心房源信息',
                  children: [
                    _buildTextField(_titleCtrl, '房源标题', hint: '如：采光通透的两居室'),
                    _fieldGap,
                    _buildRentModePicker(),
                    _fieldGap,
                    _buildRentTypePicker(),
                    _fieldGap,
                    _fieldRow([
                      _buildTextField(
                        _priceCtrl,
                        '月租金（元）',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      _buildCalculatedDepositField(),
                    ]),
                    _fieldGap,
                    _buildPaymentMethodPicker(),
                    _fieldGap,
                    _fieldRow([
                      _buildRoomTypePicker(roomTypes),
                      _buildTextField(
                        _areaCtrl,
                        '面积（㎡）',
                        keyboardType: TextInputType.number,
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.location_on_outlined,
                  title: '位置与门牌',
                  subtitle: '小区地址和坐标将自动带入',
                  children: [
                    CommunityPicker(
                      selected: _community,
                      onChanged: (community) {
                        setState(() => _community = community);
                      },
                    ),
                    if (_community != null &&
                        _community!.regionLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CommunityAddressHint(community: _community!),
                    ],
                    _fieldGap,
                    _fieldRow([
                      _buildTextField(_buildingCtrl, '楼栋', hint: '3栋'),
                      _buildTextField(_unitCtrl, '单元', hint: '2单元'),
                      _buildTextField(_roomCtrl, '房号', hint: '1501'),
                    ]),
                    _fieldGap,
                    _fieldRow([
                      _buildTextField(_floorCtrl, '楼层', hint: '15层'),
                      _buildOrientationPicker(),
                    ]),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.tune_rounded,
                  title: '配置与入住',
                  subtitle: '完善房源条件，减少租客反复咨询',
                  children: [
                    _fieldRow([
                      _buildDecorationPicker(),
                      _buildDatePicker(context, _availableDateCtrl, '可入住日期'),
                    ]),
                    _fieldGap,
                    _buildTextField(_metroCtrl, '附近地铁', hint: '如：中央公园站 600m'),
                    const SizedBox(height: AppSpacing.sm),
                    Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            title: Text(
                              '智能门锁',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text('支持租客在线授权开门'),
                            value: _isSmartLock,
                            onChanged: (value) {
                              setState(() => _isSmartLock = value);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            title: Text(
                              '自主看房',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text('允许租客在线预约并自助看房'),
                            value: _isSelfViewingSupported,
                            onChanged: (value) {
                              setState(() => _isSelfViewingSupported = value);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.checklist_rounded,
                  title: '设施与标签',
                  subtitle: '设施和标签均为必选，可多选',
                  children: [
                    _buildDictionarySelector(
                      title: '房屋设施',
                      items: facilities,
                      selectedIds: _selectedFacilityIds,
                      emptyMessage: '暂无可选设施',
                      errorText:
                          _showDictionaryErrors &&
                              !_hasDictionarySelection(
                                _selectedFacilityIds,
                                facilities,
                              )
                          ? '请至少选择一项设施'
                          : null,
                      onRetry: () => ref.invalidate(houseFacilitiesProvider),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDictionarySelector(
                      title: '房源标签',
                      items: tags,
                      selectedIds: _selectedTagIds,
                      emptyMessage: '暂无可选标签',
                      errorText:
                          _showDictionaryErrors &&
                              !_hasDictionarySelection(_selectedTagIds, tags)
                          ? '请至少选择一项标签'
                          : null,
                      onRetry: () => ref.invalidate(houseTagsProvider),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.notes_rounded,
                  title: '房源描述',
                  subtitle: '突出采光、装修和周边配套等优势',
                  children: [
                    TextField(
                      controller: _descCtrl,
                      minLines: 4,
                      maxLines: 7,
                      decoration: _inputDecoration(
                        '房源介绍',
                        hint: '例如：朝南采光好，家电齐全，步行可到地铁站…',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.photo_library_outlined,
                  title: '房源图片',
                  subtitle: '建议上传 6–12 张清晰实拍图',
                  children: [_buildImageSection()],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  icon: Icons.verified_user_outlined,
                  title: '房产证明',
                  subtitle: '提交管理员审核前必须上传，替换后会保留历史记录',
                  children: [_buildPropertyCertificateSection()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _fieldGap = SizedBox(height: AppSpacing.md);

  Widget _fieldRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: children[index]),
        ],
      ],
    );
  }

  Widget _buildDictionarySelector({
    required String title,
    required AsyncValue<List<HouseDictionaryItem>> items,
    required Set<String> selectedIds,
    required String emptyMessage,
    required VoidCallback onRetry,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: title,
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        items.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.authBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '选项加载失败，请重试',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('重新加载')),
              ],
            ),
          ),
          data: (values) {
            if (values.isEmpty) {
              return Text(
                emptyMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              );
            }
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in values)
                  FilterChip(
                    label: Text(item.name),
                    selected: _isDictionaryItemSelected(selectedIds, item),
                    showCheckmark: true,
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(
                      color: _isDictionaryItemSelected(selectedIds, item)
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedIds.add(item.id);
                        } else {
                          selectedIds.remove(item.id);
                          selectedIds.remove(item.name);
                        }
                      });
                    },
                  ),
              ],
            );
          },
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  bool _isDictionaryItemSelected(
    Set<String> selectedReferences,
    HouseDictionaryItem item,
  ) {
    return selectedReferences.contains(item.id) ||
        selectedReferences.contains(item.name);
  }

  bool _hasDictionarySelection(
    Set<String> selectedReferences,
    AsyncValue<List<HouseDictionaryItem>> items,
  ) {
    return _resolveDictionaryIds(
      selectedReferences,
      items.valueOrNull ?? const [],
    ).isNotEmpty;
  }

  List<String> _resolveDictionaryIds(
    Set<String> selectedReferences,
    List<HouseDictionaryItem> items,
  ) {
    return items
        .where((item) => _isDictionaryItemSelected(selectedReferences, item))
        .map((item) => item.id)
        .toSet()
        .toList();
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF5AAAF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.add_home_work_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? '完善房源信息' : '录入房源草稿',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '标准小区信息将用于地图展示和精准搜索',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.md,
            AppSpacing.pageHorizontal,
            AppSpacing.md,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _submitting || _uploadingImages ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEdit ? '保存修改' : '保存草稿',
                      style: AppTextStyles.labelLarge,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: _inputDecoration(label, hint: hint),
      validator: (v) {
        if (['房源标题', '月租金（元）'].contains(label)) {
          if (v == null || v.trim().isEmpty) return '请输入$label';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildRentModePicker() {
    const options = [('WHOLE_RENT', '整租'), ('SHARED_RENT', '合租')];
    return _buildDropdown('出租方式', _rentMode, options, (v) {
      setState(() => _rentMode = v);
    });
  }

  Widget _buildRentTypePicker() {
    const options = [
      ('LONG_RENT', '长租'),
      ('SHORT_RENT', '短租'),
      ('HOMESTAY', '民宿'),
    ];
    return _buildDropdown('租赁类型', _rentType, options, (v) {
      setState(() => _rentType = v);
    });
  }

  Widget _buildRoomTypePicker(AsyncValue<List<HouseDictionaryItem>> roomTypes) {
    return roomTypes.when(
      loading: () => InputDecorator(
        decoration: _inputDecoration('户型'),
        child: const LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, _) => InkWell(
        onTap: () => ref.invalidate(landlordHouseRoomTypesProvider),
        child: InputDecorator(
          decoration: _inputDecoration('户型'),
          child: const Text('加载失败，点击重试'),
        ),
      ),
      data: (items) {
        final options = items.map((item) => (item.id, item.name)).toList();
        final current = _roomTypeCtrl.text;
        if (current.isNotEmpty && !options.any((item) => item.$1 == current)) {
          options.add((current, '$current（已停用）'));
        }
        return _buildDropdown('户型', current, options, (value) {
          setState(() => _roomTypeCtrl.text = value);
        });
      },
    );
  }

  Widget _buildPaymentMethodPicker() {
    const options = [
      ('无押金月付', '无押金（月付）'),
      ('押一付一', '押一付一'),
      ('押一付三', '押一付三'),
      ('押一付六', '押一付六'),
      ('押一付十二', '押一付十二'),
      ('押二付一', '押二付一'),
    ];
    return _buildDropdown('付款方式', _paymentMethod, options, (v) {
      setState(() => _paymentMethod = v);
    });
  }

  Widget _buildOrientationPicker() {
    const options = [
      ('南', '南'),
      ('北', '北'),
      ('东', '东'),
      ('西', '西'),
      ('南北', '南北通透'),
    ];
    return _buildDropdown('朝向', _orientation, options, (v) {
      setState(() => _orientation = v);
    });
  }

  Widget _buildDecorationPicker() {
    const options = [
      ('精装修', '精装修'),
      ('简装修', '简装修'),
      ('毛坯', '毛坯'),
      ('豪华装修', '豪华装修'),
    ];
    return _buildDropdown('装修', _decoration, options, (v) {
      setState(() => _decoration = v);
    });
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) {
    final uniqueOptions = <String, String>{};
    for (final option in options) {
      uniqueOptions.putIfAbsent(option.$1, () => option.$2);
    }
    final selectedValue = value.trim();
    if (selectedValue.isNotEmpty && !uniqueOptions.containsKey(selectedValue)) {
      uniqueOptions[selectedValue] = '$selectedValue（原值）';
    }
    return DropdownButtonFormField<String>(
      initialValue: selectedValue.isNotEmpty ? selectedValue : null,
      decoration: _inputDecoration(label),
      items: uniqueOptions.entries.map((option) {
        return DropdownMenuItem(value: option.key, child: Text(option.value));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _normalizePaymentMethod(String value) {
    return switch (value.trim()) {
      '无押金' || '免押' || '零押金' => '无押金月付',
      '月付' => '押一付一',
      '季付' => '押一付三',
      '半年付' => '押一付六',
      '押一付年' || '年付' => '押一付十二',
      '无押金月付' ||
      '押一付一' ||
      '押一付三' ||
      '押一付六' ||
      '押一付十二' ||
      '押二付一' => value.trim(),
      _ => '押一付一',
    };
  }

  int get _depositMonths {
    return switch (_paymentMethod) {
      '无押金月付' => 0,
      '押二付一' => 2,
      _ => 1,
    };
  }

  int get _monthlyRentCents {
    final monthlyRentYuan = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    return (monthlyRentYuan * 100).round();
  }

  int get _calculatedDepositCents {
    return _monthlyRentCents * _depositMonths;
  }

  String _formatCentsAsYuan(int cents) {
    final yuan = cents / 100;
    return yuan == yuan.roundToDouble()
        ? yuan.toInt().toString()
        : yuan.toStringAsFixed(2);
  }

  Widget _buildCalculatedDepositField() {
    return InputDecorator(
      isEmpty: false,
      decoration: _inputDecoration(
        '押金（自动计算）',
        hint: '由付款方式决定',
      ).copyWith(helperText: '按 $_depositMonths 个月租金计算'),
      child: Text(
        '¥${_formatCentsAsYuan(_calculatedDepositCents)}',
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _normalizeDecoration(String value) {
    return switch (value.trim()) {
      '精装' || '精装房' => '精装修',
      '简装' || '简装房' => '简装修',
      '豪装' || '豪华装' => '豪华装修',
      '毛坯房' => '毛坯',
      final normalized => normalized,
    };
  }

  Widget _buildDatePicker(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(label, hint: '点击选择日期'),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          controller.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '封面图',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: _uploadingImages ? null : _pickAndUploadCover,
          child: Container(
            width: double.infinity,
            height: 168,
            decoration: BoxDecoration(
              color: AppColors.authBackground,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.inputBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: _coverUrl.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '点击上传封面图',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('建议使用客厅或房源全景图', style: AppTextStyles.bodySmall),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: AppColors.authBackground,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          color: Colors.black54,
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  '当前封面',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '点击更换',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                '房源图片',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text('${_imageUrls.length}/12', style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_imageUrls.isNotEmpty)
          SizedBox(
            height: 94,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [for (final url in _imageUrls) _imagePreview(url)],
            ),
          ),
        if (_imageUrls.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploadingImages || _imageUrls.length >= 12
                ? null
                : _pickAndUploadImages,
            icon: _uploadingImages
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.collections_outlined),
            label: Text(_uploadingImages ? '图片上传中…' : '添加房源图片'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('点击已上传的房源图片可将其设为封面', style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildPropertyCertificateSection() {
    final hasCertificate = _propertyCertificateName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.authBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Icon(
                hasCertificate
                    ? Icons.description_outlined
                    : Icons.upload_file_outlined,
                color: hasCertificate ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCertificate ? _propertyCertificateName : '尚未上传房产证',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_propertyCertificateStatus.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '材料状态：$_propertyCertificateStatus',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _propertyCertificateStatus == '已驳回'
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_propertyCertificateRemark.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '驳回原因：$_propertyCertificateRemark',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _submitting ? null : _pickPropertyCertificate,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(hasCertificate ? '替换房产证照片' : '选择房产证照片'),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '支持 JPG、PNG、WebP，最大 10MB。材料仅供本人和管理员查看。',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _pickPropertyCertificate() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null || !mounted) return;
    setState(() {
      _propertyCertificateFile = file;
      _propertyCertificateName = file.name;
      _propertyCertificateStatus = '待保存';
      _propertyCertificateRemark = '';
    });
  }

  Widget _imagePreview(String url) {
    final isCover = _coverUrl == url;
    return Container(
      width: 94,
      height: 94,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCover ? AppColors.primary : AppColors.border,
          width: isCover ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => setState(() => _coverUrl = url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md - 2),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: AppColors.primary,
                child: const Text(
                  '封面',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _imageUrls.remove(url);
                  if (_coverUrl == url) {
                    _coverUrl = _imageUrls.isEmpty ? '' : _imageUrls.first;
                  }
                });
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.sm),
                  ),
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadCover() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      setState(() => _uploadingImages = true);
      final url = await ref
          .read(landlordHouseServiceProvider)
          .uploadImage(file.path, file.name);
      if (!mounted) return;
      if (url.isEmpty) throw StateError('服务器未返回图片地址');
      setState(() => _coverUrl = url);
    } on Object catch (error) {
      if (mounted) {
        AppToast.show(context, '封面上传失败：$error', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  Future<void> _pickAndUploadImages() async {
    final remaining = 12 - _imageUrls.length;
    if (remaining <= 0) return;
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2400,
        imageQuality: 88,
        limit: remaining,
        requestFullMetadata: false,
      );
      if (files.isEmpty || !mounted) return;
      setState(() => _uploadingImages = true);
      var uploadedCount = 0;
      for (final file in files) {
        final url = await ref
            .read(landlordHouseServiceProvider)
            .uploadImage(file.path, file.name);
        if (!mounted) return;
        if (url.isEmpty) throw StateError('服务器未返回图片地址');
        setState(() {
          if (!_imageUrls.contains(url)) _imageUrls.add(url);
          _coverUrl = _coverUrl.isEmpty ? url : _coverUrl;
        });
        uploadedCount++;
      }
      if (mounted) {
        AppToast.show(
          context,
          '已上传 $uploadedCount 张图片',
          type: AppToastType.success,
        );
      }
    } on Object catch (error) {
      if (mounted) {
        AppToast.show(context, '图片上传失败：$error', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roomTypeCtrl.text.trim().isEmpty) {
      AppToast.show(context, '请选择户型', type: AppToastType.error);
      return;
    }
    final community = _community;
    if (community == null || community.id.isEmpty) return;
    final facilityIds = _resolveDictionaryIds(
      _selectedFacilityIds,
      ref.read(houseFacilitiesProvider).valueOrNull ?? const [],
    );
    final tagIds = _resolveDictionaryIds(
      _selectedTagIds,
      ref.read(houseTagsProvider).valueOrNull ?? const [],
    );
    if (facilityIds.isEmpty || tagIds.isEmpty) {
      setState(() => _showDictionaryErrors = true);
      AppToast.show(context, '请至少选择一项设施和一项标签', type: AppToastType.error);
      return;
    }
    if (_coverUrl.isEmpty) {
      AppToast.show(context, '请先上传封面图', type: AppToastType.error);
      return;
    }
    final price = _monthlyRentCents;
    final deposit = _calculatedDepositCents;

    setState(() => _submitting = true);

    try {
      final service = ref.read(landlordHouseServiceProvider);
      late final LandlordHouseItem savedHouse;
      if (widget.isEdit) {
        savedHouse = await service.updateHouse(
          widget.houseId!,
          UpdateHouseRequest(
            title: _titleCtrl.text.trim(),
            coverImage: _coverUrl,
            imageUrls: _imageUrls,
            location: community.regionLabel.isNotEmpty
                ? community.regionLabel
                : community.name,
            communityId: community.id,
            price: price,
            deposit: deposit,
            rentMode: _rentMode,
            rentType: _rentType,
            facilityIds: facilityIds,
            tagIds: tagIds,
            paymentMethod: _paymentMethod,
            roomType: _roomTypeCtrl.text.trim(),
            area: double.tryParse(_areaCtrl.text),
            floor: _floorCtrl.text.trim(),
            orientation: _orientation,
            decoration: _decoration,
            availableDate: _availableDateCtrl.text.trim(),
            metro: _metroCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            address: _buildHouseAddress(community),
            building: _buildingCtrl.text.trim(),
            unit: _unitCtrl.text.trim(),
            room: _roomCtrl.text.trim(),
            isSmartLockSupported: _isSmartLock,
            isSelfViewingSupported: _isSelfViewingSupported,
          ),
        );
      } else {
        savedHouse = await service.createHouse(
          CreateHouseRequest(
            title: _titleCtrl.text.trim(),
            coverImage: _coverUrl,
            imageUrls: _imageUrls,
            location: community.regionLabel.isNotEmpty
                ? community.regionLabel
                : community.name,
            communityId: community.id,
            price: price,
            rentMode: _rentMode,
            rentType: _rentType,
            facilityIds: facilityIds,
            tagIds: tagIds,
            deposit: deposit,
            paymentMethod: _paymentMethod,
            roomType: _roomTypeCtrl.text.trim(),
            area: double.tryParse(_areaCtrl.text),
            floor: _floorCtrl.text.trim(),
            orientation: _orientation,
            decoration: _decoration,
            availableDate: _availableDateCtrl.text.trim(),
            metro: _metroCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            address: _buildHouseAddress(community),
            building: _buildingCtrl.text.trim(),
            unit: _unitCtrl.text.trim(),
            room: _roomCtrl.text.trim(),
            isSmartLockSupported: _isSmartLock,
            isSelfViewingSupported: _isSelfViewingSupported,
          ),
        );
      }

      final certificateFile = _propertyCertificateFile;
      if (certificateFile != null) {
        await service.uploadPropertyCertificate(
          savedHouse.id,
          certificateFile.path,
          certificateFile.name,
        );
      }

      if (!mounted) return;
      AppToast.show(
        context,
        certificateFile != null
            ? '房源和房产证已保存，请在房源列表提交审核'
            : widget.isEdit
            ? '房源信息已更新'
            : '房源草稿已保存，请上传房产证后提交审核',
        type: AppToastType.success,
      );
      ref.invalidate(landlordHousesProvider(null));
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      AppToast.show(context, '操作失败：${e.toString()}', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _buildHouseAddress(Community community) {
    return [
      community.address,
      _buildingCtrl.text.trim(),
      _unitCtrl.text.trim(),
      _roomCtrl.text.trim(),
    ].where((value) => value.isNotEmpty).join(' ');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _CommunityAddressHint extends StatelessWidget {
  const _CommunityAddressHint({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              [
                community.regionLabel,
                community.address,
              ].where((value) => value.isNotEmpty).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
