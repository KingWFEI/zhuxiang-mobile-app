import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/app_legal_document.dart';

class AppLegalDocumentService {
  const AppLegalDocumentService(this._apiClient);

  final ApiClient _apiClient;

  Future<AppLegalDocument> getDocument(String documentType) async {
    final result = await _apiClient.get('/app/legal-documents/$documentType');
    return result.unwrapData(AppLegalDocument.fromJson);
  }
}
