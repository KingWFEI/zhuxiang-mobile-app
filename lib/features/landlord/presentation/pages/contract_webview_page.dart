import 'package:flutter/material.dart';

import '../../../../core/widgets/app_webview_page.dart';

class LandlordContractWebviewPage extends StatelessWidget {
  const LandlordContractWebviewPage({required this.signUrl, super.key});
  final String signUrl;

  @override
  Widget build(BuildContext context) {
    return AppWebViewPage(title: '合同签署', initialUrl: signUrl);
  }
}
