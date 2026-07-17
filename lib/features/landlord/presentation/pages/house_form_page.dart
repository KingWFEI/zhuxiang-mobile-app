import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/landlord_house.dart';
import '../../data/providers/landlord_providers.dart';

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

  late final _titleCtrl = TextEditingController();
  late final _locationCtrl = TextEditingController();
  late final _addressCtrl = TextEditingController();
  late final _buildingCtrl = TextEditingController();
  late final _unitCtrl = TextEditingController();
  late final _roomCtrl = TextEditingController();
  late final _priceCtrl = TextEditingController();
  late final _depositCtrl = TextEditingController();
  late final _areaCtrl = TextEditingController();
  late final _floorCtrl = TextEditingController();
  late final _metroCtrl = TextEditingController();
  late final _descCtrl = TextEditingController();
  late final _availableDateCtrl = TextEditingController();
  late final _roomTypeCtrl = TextEditingController();
  late final _communityIdCtrl = TextEditingController();

  String _rentType = 'long_rent';
  String _paymentMethod = '押一付一';
  String _orientation = '';
  String _decoration = '';
  String _coverUrl = '';
  final _imageUrls = <String>[];
  var _isSmartLock = false;

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
      _locationCtrl.text = house.location;
      _addressCtrl.text = house.address;
      _priceCtrl.text = (house.price / 100).toString();
      _depositCtrl.text = (house.deposit / 100).toString();
      _areaCtrl.text = house.area > 0 ? house.area.toString() : '';
      _floorCtrl.text = house.floor;
      _metroCtrl.text = house.metro;
      _descCtrl.text = house.description;
      _coverUrl = house.coverImage;
      _imageUrls.addAll(house.imageUrls);
      _communityIdCtrl.text = house.communityId;
      _rentType = house.rentType;
      _paymentMethod = house.paymentMethod;
      _roomTypeCtrl.text = house.roomType;
      _orientation = house.orientation;
      _decoration = house.decoration;
      _isSmartLock = house.isSmartLockSupported;
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
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    _buildingCtrl.dispose();
    _unitCtrl.dispose();
    _roomCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _areaCtrl.dispose();
    _floorCtrl.dispose();
    _metroCtrl.dispose();
    _descCtrl.dispose();
    _availableDateCtrl.dispose();
    _roomTypeCtrl.dispose();
    _communityIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑房源' : '发布房源'),
        leading: IconButton(
          icon: AppIcon.iconBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                96,
              ),
              children: [
                _SectionTitle('基本信息'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_titleCtrl, '房源标题', hint: '如：3栋2单元1501'),
                const SizedBox(height: AppSpacing.md),
                _buildRentTypePicker(),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_priceCtrl, '月租金（元）', keyboardType: TextInputType.number),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_depositCtrl, '押金（元）', keyboardType: TextInputType.number),
                const SizedBox(height: AppSpacing.md),
                _buildPaymentMethodPicker(),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_roomTypeCtrl, '户型', hint: '如：1室0厅1卫'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_areaCtrl, '面积（㎡）', keyboardType: TextInputType.number),

                const SizedBox(height: AppSpacing.xl),
                _SectionTitle('位置信息'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_locationCtrl, '所在区域', hint: '如：重庆市渝北区中央公园'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_communityIdCtrl, '小区ID', hint: '请填写小区ID'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_addressCtrl, '详细地址'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_buildingCtrl, '楼栋', hint: '如：3栋'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_unitCtrl, '单元', hint: '如：2单元'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_roomCtrl, '房间号', hint: '如：1501'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_floorCtrl, '楼层', hint: '如：15层'),
                const SizedBox(height: AppSpacing.md),
                _buildOrientationPicker(),
                const SizedBox(height: AppSpacing.md),
                _buildDecorationPicker(),
                const SizedBox(height: AppSpacing.md),
                _buildTextField(_metroCtrl, '地铁', hint: '如：中央公园站'),
                const SizedBox(height: AppSpacing.md),
                _buildDatePicker(context, _availableDateCtrl, '可入住日期'),

                const SizedBox(height: AppSpacing.xl),
                _SectionTitle('房源描述'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: _inputDecoration('描述', hint: '描述房源特点、周边配套等'),
                ),

                const SizedBox(height: AppSpacing.xl),
                _SectionTitle('图片'),
                const SizedBox(height: AppSpacing.md),
                _buildImageSection(),

                const SizedBox(height: AppSpacing.xl),
                SwitchListTile(
                  title: const Text('智能门锁'),
                  subtitle: const Text('房源是否支持智能门锁开门'),
                  value: _isSmartLock,
                  onChanged: (v) => setState(() => _isSmartLock = v),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                            widget.isEdit ? '保存修改' : '立即发布',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, hint: hint),
      validator: (v) {
        if (['房源标题', '所在区域', '小区ID', '月租金（元）'].contains(label)) {
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

  Widget _buildRentTypePicker() {
    const options = [
      ('long_rent', '长租'),
      ('short_rent', '短租'),
    ];
    return _buildDropdown('出租方式', _rentType, options, (v) {
      setState(() => _rentType = v);
    });
  }

  Widget _buildPaymentMethodPicker() {
    const options = [
      ('押一付一', '押一付一'),
      ('押一付三', '押一付三'),
      ('押一付六', '押一付六'),
      ('押一付十二', '押一付年'),
    ];
    return _buildDropdown('付款方式', _paymentMethod, options, (v) {
      setState(() => _paymentMethod = v);
    });
  }

  Widget _buildOrientationPicker() {
    const options = [
      ('朝南', '朝南'),
      ('朝北', '朝北'),
      ('朝东', '朝东'),
      ('朝西', '朝西'),
      ('南北通透', '南北通透'),
    ];
    return _buildDropdown('朝向', _orientation, options, (v) {
      setState(() => _orientation = v);
    });
  }

  Widget _buildDecorationPicker() {
    const options = [
      ('精装', '精装'),
      ('简装', '简装'),
      ('毛坯', '毛坯'),
      ('豪装', '豪装'),
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
    return DropdownButtonFormField<String>(
      initialValue: value.isNotEmpty ? value : null,
      decoration: _inputDecoration(label),
      items: options.map((o) {
        return DropdownMenuItem(value: o.$1, child: Text(o.$2));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
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
        if (_coverUrl.isNotEmpty || _imageUrls.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_coverUrl.isNotEmpty)
                  _imagePreview(_coverUrl, isCover: true),
                for (final url in _imageUrls)
                  _imagePreview(url),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _pickAndUploadImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('上传图片'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePreview(String url, {bool isCover = false}) {
    return Container(
      width: 80,
      height: 80,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md - 2),
            child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image, color: AppColors.textMuted)),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                  if (_coverUrl == url) _coverUrl = '';
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

  Future<void> _pickAndUploadImage() async {
    // TODO: integrate image_picker and call landlordHouseService.uploadImage()
    AppToast.show(context, '图片上传功能请使用系统相册选择', type: AppToastType.normal);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = int.tryParse(_priceCtrl.text) ?? 0;
    final deposit = int.tryParse(_depositCtrl.text);

    setState(() => _submitting = true);

    try {
      final service = ref.read(landlordHouseServiceProvider);
      if (widget.isEdit) {
        await service.updateHouse(
          widget.houseId!,
          UpdateHouseRequest(
            title: _titleCtrl.text.trim(),
            coverImage: _coverUrl,
            imageUrls: _imageUrls,
            location: _locationCtrl.text.trim(),
            communityId: _communityIdCtrl.text.trim(),
            price: price * 100,
            deposit: deposit != null ? deposit * 100 : null,
            rentType: _rentType,
            paymentMethod: _paymentMethod,
            roomType: _roomTypeCtrl.text.trim(),
            area: int.tryParse(_areaCtrl.text),
            floor: _floorCtrl.text.trim(),
            orientation: _orientation,
            decoration: _decoration,
            availableDate: _availableDateCtrl.text.trim(),
            metro: _metroCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            building: _buildingCtrl.text.trim(),
            unit: _unitCtrl.text.trim(),
            room: _roomCtrl.text.trim(),
            isSmartLockSupported: _isSmartLock,
          ),
        );
      } else {
        await service.createHouse(
          CreateHouseRequest(
            title: _titleCtrl.text.trim(),
            coverImage: _coverUrl,
            imageUrls: _imageUrls,
            location: _locationCtrl.text.trim(),
            communityId: _communityIdCtrl.text.trim(),
            price: price * 100,
            rentType: _rentType,
            facilityIds: const [],
            tagIds: const [],
            deposit: deposit != null ? deposit * 100 : null,
            paymentMethod: _paymentMethod,
            roomType: _roomTypeCtrl.text.trim(),
            area: int.tryParse(_areaCtrl.text),
            floor: _floorCtrl.text.trim(),
            orientation: _orientation,
            decoration: _decoration,
            availableDate: _availableDateCtrl.text.trim(),
            metro: _metroCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            building: _buildingCtrl.text.trim(),
            unit: _unitCtrl.text.trim(),
            room: _roomCtrl.text.trim(),
            isSmartLockSupported: _isSmartLock,
          ),
        );
      }

      if (!mounted) return;
      AppToast.show(
        context,
        widget.isEdit ? '房源信息已更新' : '房源发布成功',
        type: AppToastType.success,
      );
      ref.invalidate(landlordHousesProvider(null));
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        '操作失败：${e.toString()}',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
