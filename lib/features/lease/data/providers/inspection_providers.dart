import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../domain/entities/inspection.dart';
import '../services/inspection_service.dart';

final inspectionServiceProvider = Provider<InspectionService>((ref) {
  return InspectionService(ref.watch(apiClientProvider));
});

final moveOutInspectionProvider = FutureProvider.autoDispose
    .family<MoveOutInspection, String>((ref, contractId) {
      return ref
          .watch(inspectionServiceProvider)
          .getMoveOutInspection(contractId);
    });
