import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/network/api_result.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../application/message_controller.dart';
import '../../application/message_realtime_coordinator.dart';
import '../realtime/message_sse_client.dart';
import '../services/message_service.dart';

final messageServiceProvider = Provider<MessageServiceContract>((ref) {
  return MessageService(ref.watch(apiClientProvider));
});

final messageControllerProvider =
    StateNotifierProvider<MessageController, MessageState>((ref) {
      final userId = ref.watch(
        authControllerProvider.select((state) => state.user?.id),
      );
      final controller = MessageController(ref.watch(messageServiceProvider));
      if (userId != null) unawaited(controller.loadInitial());
      return controller;
    });

final messageSseClientProvider = Provider<MessageSseClient>((ref) {
  return MessageSseClient(ref.watch(dioProvider));
});

final messageRealtimeCoordinatorProvider = Provider<MessageRealtimeCoordinator>(
  (ref) {
    final coordinator = MessageRealtimeCoordinator(
      client: ref.watch(messageSseClientProvider),
      enabled: AppConfig.messageSseEnabled,
      readAccessToken: () => ref.read(tokenStorageProvider).readAccessToken(),
      refreshAccessToken: () =>
          ref.read(authControllerProvider.notifier).refreshSession(),
      onAuthFailure: () => ref.read(authControllerProvider.notifier).logout(),
      reconcileInterval: Duration(seconds: AppConfig.messageReconcileSeconds),
      onReconcile: () => ref
          .read(messageControllerProvider.notifier)
          .handleRealtimeConnected(),
      onEvent: (event) async {
        await ref
            .read(messageControllerProvider.notifier)
            .handleRealtimeEvent(event);
        if (event.type == 'message.created' &&
            event.message?.actionTarget == '/landlord/workbench') {
          try {
            final result = await ref.read(apiClientProvider).get('/profile');
            final user = await result.unwrapData(AuthUser.fromJson);
            await ref.read(authControllerProvider.notifier).updateUser(user);
          } on Object {
            // 消息仍会保留；用户下次进入认证页或重新登录时会再次同步角色。
          }
        }
      },
    );

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      coordinator.updateUser(next.isInitialized ? next.user?.id : null);
    }, fireImmediately: true);
    ref.onDispose(coordinator.dispose);
    return coordinator;
  },
);
