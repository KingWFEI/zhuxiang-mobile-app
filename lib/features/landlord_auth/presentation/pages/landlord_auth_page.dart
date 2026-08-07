import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_mode_controller.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/landlord_auth_models.dart';
import '../../data/landlord_auth_providers.dart';

const _blue = Color(0xFF2878F6);
const _background = Color(0xFFF5F8FD);

class LandlordAuthPage extends ConsumerStatefulWidget {
  const LandlordAuthPage({super.key});

  @override
  ConsumerState<LandlordAuthPage> createState() => _LandlordAuthPageState();
}

class _LandlordAuthBackButton extends StatelessWidget {
  const _LandlordAuthBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.goNamed(RouteNames.profile);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: AppIcon.iconBack,
      ),
    );
  }
}

class _LandlordAuthPageState extends ConsumerState<LandlordAuthPage> {
  final _picker = ImagePicker();
  final _realName = TextEditingController();
  final _idCardNo = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _wechat = TextEditingController();
  final _email = TextEditingController();
  final _contactTime = TextEditingController();
  final _note = TextEditingController();

  LandlordAuthStatus? _status;
  bool _loading = true;
  bool _editing = false;
  bool _submitting = false;
  bool _replaceExisting = false;
  int _step = 0;
  String? _error;
  String? _frontUrl;
  String? _backUrl;
  String? _frontLocal;
  String? _backLocal;
  String? _uploadingKey;
  String _proofType = 'PROPERTY_CERTIFICATE';
  final List<LandlordAuthProof> _proofs = [];

  static const _proofMeta = <String, ({String label, String bizType})>{
    'PROPERTY_CERTIFICATE': (label: '房产证', bizType: 'landlord_proof_property'),
    'PURCHASE_CONTRACT': (label: '购房合同', bizType: 'landlord_proof_purchase'),
    'LEASE_CERTIFICATE': (label: '租赁凭证', bizType: 'landlord_proof_lease'),
    'COURT_DECISION': (label: '判决书/继承公证书', bizType: 'landlord_proof_court'),
    'OTHER': (label: '其他权属证明', bizType: 'landlord_proof_other'),
  };

  @override
  void initState() {
    super.initState();
    _phone.text = ref.read(authControllerProvider).user?.phone ?? '';
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _realName,
      _idCardNo,
      _address,
      _phone,
      _wechat,
      _email,
      _contactTime,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await ref.read(landlordAuthServiceProvider).getStatus();
      if (!mounted) return;
      _syncApprovedRole(value);
      setState(() {
        _status = value;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(error);
        });
      }
    }
  }

  void _syncApprovedRole(LandlordAuthStatus value) {
    if (!value.landlord) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null || user.role == UserRole.landlord) return;
    ref
        .read(authControllerProvider.notifier)
        .updateUser(
          AuthUser(
            id: user.id,
            phone: user.phone,
            nickname: user.nickname,
            avatarUrl: user.avatarUrl,
            isVerified: user.isVerified,
            role: UserRole.landlord,
            hasPassword: user.hasPassword,
          ),
        );
  }

  void _start({bool replace = false}) {
    final latest = _status?.latest;
    if (latest != null) {
      _realName.text = latest.realName;
      _address.text = latest.contactAddress ?? '';
      _phone.text = latest.contactPhone;
      _wechat.text = latest.contactWechat ?? '';
      _email.text = latest.contactEmail ?? '';
      _contactTime.text = latest.preferredContactTime ?? '';
      _note.text = latest.applicantNote ?? '';
      _frontUrl = latest.idCardFrontUrl;
      _backUrl = latest.idCardBackUrl;
      _proofs
        ..clear()
        ..addAll(latest.proofs);
    }
    setState(() {
      _editing = true;
      _replaceExisting = replace;
      _step = 0;
      _error = null;
    });
  }

  Future<void> _uploadId(bool front) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (picked == null) return;
    final key = front ? 'front' : 'back';
    setState(() => _uploadingKey = key);
    try {
      final result = await ref
          .read(landlordAuthServiceProvider)
          .upload(
            picked.path,
            front ? 'landlord_id_card_front' : 'landlord_id_card_back',
          );
      if (!mounted) return;
      setState(() {
        if (front) {
          _frontUrl = result.url;
          _frontLocal = picked.path;
        } else {
          _backUrl = result.url;
          _backLocal = picked.path;
        }
      });
    } on Object catch (error) {
      _toast(_message(error));
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  Future<void> _uploadProof() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (picked == null) return;
    setState(() => _uploadingKey = 'proof');
    try {
      final result = await ref
          .read(landlordAuthServiceProvider)
          .upload(picked.path, _proofMeta[_proofType]!.bizType);
      if (!mounted) return;
      setState(
        () => _proofs.add(
          LandlordAuthProof(
            proofType: _proofType,
            fileId: result.fileId,
            fileUrl: result.url,
          ),
        ),
      );
    } on Object catch (error) {
      _toast(_message(error));
    } finally {
      if (mounted) setState(() => _uploadingKey = null);
    }
  }

  bool _validateStep() {
    String? message;
    if (_step == 0) {
      if (_realName.text.trim().isEmpty) {
        message = '请填写真实姓名';
      } else if (!RegExp(r'^\d{17}[0-9Xx]$').hasMatch(_idCardNo.text.trim())) {
        message = '请填写正确的18位身份证号';
      }
    } else if (_step == 1 && (_frontUrl == null || _backUrl == null)) {
      message = '身份证人像面和国徽面都必须上传';
    } else if (_step == 2 && _proofs.isEmpty) {
      message = '请至少上传一种房源权属证明';
    } else if (_step == 3 &&
        !RegExp(r'^1[3-9]\d{9}$').hasMatch(_phone.text.trim())) {
      message = '请填写正确的联系手机号';
    }
    if (message != null) {
      _toast(message);
      return false;
    }
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(landlordAuthServiceProvider)
          .submit(
            realName: _realName.text.trim(),
            idCardNo: _idCardNo.text.trim(),
            idCardFrontUrl: _frontUrl!,
            idCardBackUrl: _backUrl!,
            proofs: _proofs,
            contactPhone: _phone.text.trim(),
            replaceExisting: _replaceExisting,
            contactWechat: _nullable(_wechat.text),
            contactEmail: _nullable(_email.text),
            contactAddress: _nullable(_address.text),
            preferredContactTime: _nullable(_contactTime.text),
            applicantNote: _nullable(_note.text),
          );
      if (!mounted) return;
      _editing = false;
      _idCardNo.clear();
      _toast('认证申请提交成功');
      await _load();
    } on Object catch (error) {
      _toast(_message(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        toolbarHeight: 44,
        leadingWidth: 80,
        leading: const _LandlordAuthBackButton(),
        titleTextStyle: AppTextStyles.normalPageTitle,
        title: const Text('房东认证', style: AppTextStyles.normalPageTitle),
        centerTitle: true,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        actions: const [SizedBox(width: 80)],
        /*
          TextButton.icon(
            onPressed: () {},
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCustomerService01,
              size: 19,
            ),
            label: const Text('帮助'),
          ),
        ],
        */
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _editing
          ? _buildFlow()
          : _buildStatus(),
    );
  }

  Widget _buildStatus() {
    final status = _status!;
    if (status.landlord || status.status == 'APPROVED') return _approved();
    if (status.status == 'PENDING' || status.status == 'REJECTED') {
      return _progress(status);
    }
    return _intro();
  }

  Widget _intro() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
    children: [
      _PrivacyHero(status: '未认证'),
      const SizedBox(height: 14),
      _RequirementCard(
        icon: HugeIcons.strokeRoundedUser02,
        title: '个人信息',
        subtitle: '填写真实姓名、身份证号和联系地址',
      ),
      _RequirementCard(
        icon: HugeIcons.strokeRoundedFile01,
        title: '身份证照片上传',
        subtitle: '身份证人像面和国徽面均需清晰完整',
      ),
      _RequirementCard(
        icon: HugeIcons.strokeRoundedRealEstate01,
        title: '房源权属证明',
        subtitle: '房产证、购房合同等材料至少上传一种',
      ),
      _RequirementCard(
        icon: HugeIcons.strokeRoundedSmartPhone01,
        title: '联系方式',
        subtitle: '填写常用手机号，方便接收审核通知',
      ),
      const _MaterialNotice(),
      const SizedBox(height: 18),
      _PrimaryButton(label: '开始认证', onPressed: () => _start()),
      const SizedBox(height: 10),
      const Text(
        '认证信息仅用于身份审核，我们将严格保护您的隐私',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Color(0xFF929DAD)),
      ),
    ],
  );

  Widget _progress(LandlordAuthStatus status) {
    final pending = status.status == 'PENDING';
    final latest = status.latest!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PrivacyHero(status: pending ? '审核中' : '未通过'),
          const SizedBox(height: 16),
          _WhiteCard(
            child: Column(
              children: [
                HugeIcon(
                  icon: pending
                      ? HugeIcons.strokeRoundedClock01
                      : HugeIcons.strokeRoundedSecurityValidation,
                  size: 58,
                  color: pending
                      ? const Color(0xFFF6A623)
                      : const Color(0xFFE95353),
                ),
                const SizedBox(height: 12),
                Text(
                  pending ? '资料正在审核中' : '认证暂未通过',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pending
                      ? '预计1～3个工作日完成，请留意消息通知'
                      : (latest.rejectReason ?? '请完善材料后重新提交'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF778294),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                _InfoLine(label: '申请编号', value: latest.applicationNo),
                _InfoLine(label: '申请人', value: latest.realName),
                _InfoLine(label: '提交材料', value: '${latest.proofs.length + 2}份'),
                _InfoLine(label: '当前进度', value: pending ? '平台审核' : '需要补充材料'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _start(replace: pending),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01),
            label: Text(pending ? '重新认证（替换当前申请）' : '重新认证'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: _blue,
              side: const BorderSide(color: Color(0xFFB9D4FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _load,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01),
            label: const Text('刷新认证进度'),
          ),
        ],
      ),
    );
  }

  Widget _approved() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _PrivacyHero(status: '已认证'),
      const SizedBox(height: 16),
      _WhiteCard(
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE7F7EF),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Color(0xFF24AE72),
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '房东认证已通过',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '您现在可以发布房源、处理预约并管理租约',
              style: TextStyle(color: Color(0xFF778294)),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(label: '进入房东工作台', onPressed: _enterWorkbench),
          ],
        ),
      ),
    ],
  );

  Widget _buildFlow() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: _StepHeader(step: _step),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _WhiteCard(child: _stepBody()),
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x160B366C),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => setState(() => _step--),
                  style: _buttonStyle(false),
                  child: const Text('上一步'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _submitting ? null : _next,
                style: _buttonStyle(true),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_step == 3 ? '提交认证' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _stepBody() => switch (_step) {
    0 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormTitle(
          icon: HugeIcons.strokeRoundedUser02,
          title: '填写个人信息',
          subtitle: '请确保信息与身份证保持一致',
        ),
        _field(_realName, '真实姓名', '请输入身份证上的姓名'),
        _field(_idCardNo, '身份证号', '请输入18位身份证号', keyboard: TextInputType.text),
        _field(_address, '联系地址（选填）', '请输入当前常住地址'),
      ],
    ),
    1 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormTitle(
          icon: HugeIcons.strokeRoundedFile01,
          title: '上传身份证照片',
          subtitle: '正反面必须上传，边缘完整且文字清晰',
        ),
        _UploadTile(
          title: '身份证人像面',
          subtitle: '上传带有头像的一面',
          localPath: _frontLocal,
          remoteUrl: _frontUrl,
          loading: _uploadingKey == 'front',
          onTap: () => _uploadId(true),
        ),
        const SizedBox(height: 14),
        _UploadTile(
          title: '身份证国徽面',
          subtitle: '上传带有国徽的一面',
          localPath: _backLocal,
          remoteUrl: _backUrl,
          loading: _uploadingKey == 'back',
          onTap: () => _uploadId(false),
        ),
        const SizedBox(height: 12),
        const _SafeNotice(text: '身份证照片仅用于房东身份审核，不会展示给其他用户。'),
      ],
    ),
    2 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormTitle(
          icon: HugeIcons.strokeRoundedRealEstate01,
          title: '上传房源权属证明',
          subtitle: '请至少上传一种能够证明房源归属或出租权的材料',
        ),
        DropdownButtonFormField<String>(
          initialValue: _proofType,
          decoration: _inputDecoration('材料类型'),
          items: _proofMeta.entries
              .map(
                (item) => DropdownMenuItem(
                  value: item.key,
                  child: Text(item.value.label),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _proofType = value!),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: _uploadingKey == null ? _uploadProof : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 116,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFD7FF)),
            ),
            child: Center(
              child: _uploadingKey == 'proof'
                  ? const CircularProgressIndicator()
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedFile01,
                          color: _blue,
                          size: 34,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '上传证明材料',
                          style: TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_proofs.isNotEmpty) ...[
          const SizedBox(height: 18),
          ..._proofs.asMap().entries.map(
            (entry) => _ProofRow(
              proof: entry.value,
              label: _proofMeta[entry.value.proofType]?.label ?? '其他证明',
              onDelete: () => setState(() => _proofs.removeAt(entry.key)),
            ),
          ),
        ],
      ],
    ),
    _ => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormTitle(
          icon: HugeIcons.strokeRoundedSmartPhone01,
          title: '填写联系方式',
          subtitle: '用于平台核实材料和发送审核通知',
        ),
        _field(_phone, '手机号码', '请输入常用手机号', keyboard: TextInputType.phone),
        _field(_wechat, '微信号（选填）', '方便审核人员联系您'),
        _field(
          _email,
          '电子邮箱（选填）',
          'name@example.com',
          keyboard: TextInputType.emailAddress,
        ),
        _field(_contactTime, '方便联系时间（选填）', '例如：工作日18:00后'),
        _field(_note, '补充说明（选填）', '可填写材料说明或其他情况', maxLines: 3),
        const _SafeNotice(text: '提交即表示您确认以上资料真实有效。虚假材料将导致认证失败。'),
      ],
    ),
  };

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E8F2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1E8F2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );
  ButtonStyle _buttonStyle(bool primary) =>
      (primary
              ? FilledButton.styleFrom(backgroundColor: _blue)
              : OutlinedButton.styleFrom(foregroundColor: _blue))
          .copyWith(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );

  Future<void> _enterWorkbench() async {
    await ref.read(appModeProvider.notifier).setMode(AppMode.landlord);
    if (mounted) context.goNamed(RouteNames.landlordWorkbench);
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFDDEEFF), Color(0xFFEAF5FF), Color(0xFFF7FBFF)],
        stops: [0, 0.52, 1],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x162B72C9),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 1,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0, 0.48],
                ).createShader(bounds),
                child: Image.asset(
                  'assets/landord/landord_bk.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (status != '\u672a\u8ba4\u8bc1')
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status == '已认证'
                        ? const Color(0xFF8DDBB9)
                        : const Color(0xFFFFB68F),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == '已认证'
                        ? const Color(0xFF1FA36A)
                        : const Color(0xFFF36B2B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 88,
            top: 30,
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedSecurityValidation,
                  color: _blue,
                  size: 50,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '平台将保护您的隐私信息',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '认证信息严格保密\n仅用于房东身份审核',
                        style: TextStyle(
                          color: Color(0xFF596679),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PrivacyBenefit(
                    icon: HugeIcons.strokeRoundedLockPassword,
                    label: '信息加密保护',
                  ),
                  _PrivacyBenefit(
                    icon: HugeIcons.strokeRoundedFile01,
                    label: '仅审核使用',
                  ),
                  _PrivacyBenefit(
                    icon: HugeIcons.strokeRoundedShield01,
                    label: '隐私不泄露',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PrivacyBenefit extends StatelessWidget {
  const _PrivacyBenefit({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: _blue, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF52647A),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1C4D85),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEDF5FF),
          ),
          child: Transform.scale(
            scale: 0.72,
            child: HugeIcon(icon: icon, color: _blue, size: 18),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF8792A3), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MaterialNotice extends StatelessWidget {
  const _MaterialNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF6FF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD5E7FF)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 哪些材料可用于房东认证？',
          style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10),
        Text(
          '房产证｜购房合同及发票｜房屋租赁凭证\n法院判决书或继承公证书｜其他权属证明',
          style: TextStyle(
            color: Color(0xFF64748A),
            height: 1.65,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x101A4C84),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8792A3))),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _FormTitle extends StatelessWidget {
  const _FormTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFEDF5FF),
            shape: BoxShape.circle,
          ),
          child: Transform.scale(
            scale: 0.72,
            child: HugeIcon(icon: icon, color: _blue, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF8792A3), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SafeNotice extends StatelessWidget {
  const _SafeNotice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F6FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedLockPassword,
          color: _blue,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF66758B),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;
  static const labels = ['个人信息', '身份证', '权属证明', '联系方式'];
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      4,
      (index) => Expanded(
        child: Column(
          children: [
            Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index <= step ? _blue : const Color(0xFFDCE5F1),
                    ),
                  ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= step ? _blue : const Color(0xFFE8EEF6),
                  ),
                  child: Center(
                    child: index < step
                        ? const HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            size: 17,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index <= step
                                  ? Colors.white
                                  : const Color(0xFF8B98AA),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < step ? _blue : const Color(0xFFDCE5F1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 11,
                color: index == step ? _blue : const Color(0xFF8B98AA),
                fontWeight: index == step ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.localPath,
    required this.remoteUrl,
    required this.loading,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String? localPath;
  final String? remoteUrl;
  final bool loading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final hasImage = localPath != null || remoteUrl?.isNotEmpty == true;
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 172,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasImage ? const Color(0xFF77B1FF) : const Color(0xFFBDD5F6),
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    localPath != null
                        ? Image.file(File(localPath!), fit: BoxFit.cover)
                        : Image.network(remoteUrl!, fit: BoxFit.cover),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.black54,
                        child: Text(
                          '$title · 点击更换',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedFile01,
                    size: 34,
                    color: _blue,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8A96A8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({
    required this.proof,
    required this.label,
    required this.onDelete,
  });
  final LandlordAuthProof proof;
  final String label;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F9FD),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.network(
            proof.fileUrl,
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                '已上传',
                style: TextStyle(color: Color(0xFF25A86B), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedDelete02,
            color: Color(0xFFE35858),
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedCloudOff,
            size: 56,
            color: Color(0xFF9AA7B8),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    ),
  );
}
