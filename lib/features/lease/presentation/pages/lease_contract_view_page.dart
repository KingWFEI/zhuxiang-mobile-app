import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/lease_contract_document.dart';
import '../widgets/current_lease_card.dart';

class LeaseContractViewPage extends ConsumerWidget {
  const LeaseContractViewPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contract = ref.watch(leaseContractProvider(leaseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('电子合同')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: contract.when(
            loading: () => const AppLoadingView(message: '正在加载电子合同'),
            error: (error, stackTrace) => AppApiErrorView(
              error: error,
              message: '电子合同加载失败',
              onRetry: () => ref.invalidate(leaseContractProvider(leaseId)),
            ),
            data: (document) => _ContractContent(document: document),
          ),
        ),
      ),
    );
  }
}

class _ContractContent extends StatelessWidget {
  const _ContractContent({required this.document});

  final LeaseContractDocument document;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        _CardSection(
          title: '合同信息',
          child: Column(
            children: [
              _InfoRow(label: '合同编号', value: document.contractNo),
              _InfoRow(label: '合同状态', value: document.statusText),
              _InfoRow(label: '房源', value: _fallback(document.houseName)),
              _InfoRow(label: '签约人', value: _fallback(document.tenantName)),
              if (document.signedAt != null)
                _InfoRow(
                  label: '签约时间',
                  value: formatLeaseDate(document.signedAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CardSection(
          title: '租约摘要',
          child: Column(
            children: [
              _InfoRow(
                label: '租期',
                value:
                    '${formatLeaseDate(document.startDate)} - ${formatLeaseDate(document.endDate)}',
              ),
              _InfoRow(
                label: '月租金',
                value: '￥${formatLeaseMoney(document.monthlyRent)}',
              ),
              _InfoRow(
                label: '押金',
                value: '￥${formatLeaseMoney(document.deposit)}',
              ),
              _InfoRow(label: '付款方式', value: _fallback(document.paymentMethod)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CardSection(
          title: '合同正文',
          child: _ContractText(document: document),
        ),
        if (document.fileUrl.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _CardSection(
            title: '合同文件',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  document.fileUrl,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: document.fileUrl),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('合同链接已复制')));
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('复制合同链接'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _fallback(String value) {
    final text = value.trim();
    return text.isEmpty ? '暂无' : text;
  }
}

class _ContractText extends StatelessWidget {
  const _ContractText({required this.document});

  final LeaseContractDocument document;

  @override
  Widget build(BuildContext context) {
    final content = document.content.trim();
    if (content.isNotEmpty) {
      return SelectableText(
        content,
        style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
      );
    }

    if (document.clauses.isNotEmpty) {
      return SelectableText(
        document.clauses.map((item) => '· $item').join('\n\n'),
        style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
      );
    }

    return Text('合同正文暂未同步，请联系管家确认合同文件。', style: AppTextStyles.bodyMedium);
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
