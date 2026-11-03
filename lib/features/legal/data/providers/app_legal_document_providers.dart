import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../services/app_legal_document_service.dart';

final appLegalDocumentServiceProvider = Provider<AppLegalDocumentService>((
  ref,
) {
  return AppLegalDocumentService(ref.watch(apiClientProvider));
});
