import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../application/message_controller.dart';
import '../services/message_service.dart';

final messageServiceProvider = Provider<MessageServiceContract>((ref) {
  return MessageService(ref.watch(apiClientProvider));
});

final messageControllerProvider =
    StateNotifierProvider<MessageController, MessageState>((ref) {
      final controller = MessageController(ref.watch(messageServiceProvider));
      controller.loadInitial();
      return controller;
    });
