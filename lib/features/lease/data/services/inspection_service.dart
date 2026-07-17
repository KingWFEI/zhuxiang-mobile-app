import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/inspection.dart';

class InspectionService {
  const InspectionService(this._apiClient);

  final ApiClient _apiClient;

  Future<MoveOutInspection> getMoveOutInspection(String contractId) async {
    final result = await _apiClient.get(
      '/app/contracts/$contractId/move-out-inspection',
    );
    return result.unwrapData(MoveOutInspection.fromJson);
  }

  Future<InspectionPhoto> uploadPhoto({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final result = await _apiClient.post(
      '/files/upload',
      data: formData,
      queryParameters: {'bizType': 'move_out_inspection'},
    );
    final payload = await result.unwrapValue(
      (data) => data as Map<String, dynamic>,
    );
    return InspectionPhoto.fromJson(payload);
  }

  Future<MoveOutInspection> submitMoveOutInspection({
    required String contractId,
    required List<InspectionRoom> rooms,
  }) async {
    final result = await _apiClient.post(
      '/app/contracts/$contractId/move-out-inspection/submit',
      data: {
        'items': [
          for (final room in rooms)
            for (final item in room.items)
              {
                'roomCode': room.roomCode,
                'itemCode': item.itemCode,
                'remark': item.remark ?? '',
                'photos': item.photos.map((photo) => photo.toJson()).toList(),
              },
        ],
      },
    );
    return result.unwrapData(MoveOutInspection.fromJson);
  }
}
