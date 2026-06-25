import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/repair_providers.dart';
import '../../domain/entities/repair_order.dart';
import '../widgets/repair_type_grid.dart';

class CreateRepairPage extends ConsumerStatefulWidget {
  const CreateRepairPage({super.key, this.initialType});

  final RepairType? initialType;

  @override
  ConsumerState<CreateRepairPage> createState() => _CreateRepairPageState();
}

class _CreateRepairPageState extends ConsumerState<CreateRepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController(text: '王小明');
  final _phoneController = TextEditingController(text: '13812342468');
  RepairType? _selectedType;
  DateTime? _expectedVisitTime;
  final List<String> _mockImages = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _expectedVisitTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repairControllerProvider);
    final house = state.overview?.currentHouse;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _SimpleHeader(title: '新建报修')),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardSection(
                            title: '房屋信息',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(house?.houseName ?? '3栋2单元1201'),
                              subtitle: Text(
                                house?.leaseStatus ?? '履约中',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardSection(
                            title: '报修类型',
                            child: RepairTypeGrid(
                              selectedType: _selectedType,
                              onSelected: (type) =>
                                  setState(() => _selectedType = type),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardSection(
                            title: '问题描述',
                            child: TextFormField(
                              controller: _descriptionController,
                              minLines: 4,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText: '请描述维修问题，例如故障位置、出现时间、影响范围',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.length < 5) return '问题描述至少填写 5 个字';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardSection(
                            title: '问题图片',
                            child: _ImagePlaceholder(
                              images: _mockImages,
                              onAdd: () => setState(
                                () => _mockImages.add(
                                  'mock://${_mockImages.length + 1}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardSection(
                            title: '联系人信息',
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: '联系人',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      (value?.trim().isEmpty ?? true)
                                      ? '请输入联系人'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: '联系电话',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      (value?.trim().isEmpty ?? true)
                                      ? '请输入联系电话'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardSection(
                            title: '期望上门时间',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_formatDateTime(_expectedVisitTime)),
                              trailing: const Icon(Icons.event_rounded),
                              onTap: _pickExpectedDate,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : _submitRepair,
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('提交报修'),
                            ),
                          ),
                        ],
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

  Future<void> _pickExpectedDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedVisitTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null) return;
    setState(() {
      _expectedVisitTime = DateTime(date.year, date.month, date.day, 10);
    });
  }

  Future<void> _submitRepair() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择报修类型')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final house = ref.read(repairControllerProvider).overview?.currentHouse;
    final request = CreateRepairRequest(
      houseId: house?.houseId ?? 'house-001',
      houseName: house?.houseName ?? '3栋2单元1201',
      roomName: house?.roomName ?? '3栋2单元1201',
      repairType: _selectedType!,
      description: _descriptionController.text.trim(),
      imageUrls: List.of(_mockImages),
      contactName: _nameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      expectedVisitTime: _expectedVisitTime,
    );
    final order = await ref
        .read(repairControllerProvider.notifier)
        .createRepair(request);
    if (!mounted || order == null) return;
    context.goNamed(
      RouteNames.repairDetail,
      pathParameters: {'repairId': order.id},
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: AppSpacing.sm,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed(RouteNames.repairs);
              },
              icon: AppIcon.iconBack,
            ),
          ),
          Text(title, style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.images, required this.onAdd});

  final List<String> images;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final _ in images)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.image_rounded, color: AppColors.primary),
          ),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add_a_photo_rounded),
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime? time) {
  if (time == null) return '请选择期望上门时间';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
}
