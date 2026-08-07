import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/message/data/providers/message_providers.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';
import 'package:zhuxiang_app/features/message/presentation/pages/message_page.dart';

void main() {
  testWidgets('message page renders reference-style sections and search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
        ],
        child: const MaterialApp(home: MessagePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('消息'), findsOneWidget);
    expect(find.text('系统通知'), findsOneWidget);
    expect(find.text('活动公告'), findsOneWidget);
    expect(find.text('租约提醒'), findsWidgets);
    expect(find.text('服务通知'), findsOneWidget);
    expect(find.text('全部消息'), findsOneWidget);
    expect(find.text('公告'), findsOneWidget);
    expect(find.text('勿忧管家'), findsWidgets);
    expect(find.text('账单通知'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('搜索消息'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('message-search-field')),
      '账单',
    );
    await tester.pump();

    expect(find.text('账单通知'), findsOneWidget);
    expect(find.text('勿忧管家'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeMessageService implements MessageServiceContract {
  static const _messages = [
    AppMessage(
      id: 'system-1',
      title: '勿忧管家',
      content: '您的报修工单已被接单，请保持电话畅通',
      category: MessageCategory.system,
      isRead: false,
    ),
    AppMessage(
      id: 'bill-1',
      title: '账单通知',
      content: '您有一笔待支付的账单，请及时查看',
      category: MessageCategory.bill,
      isRead: false,
    ),
    AppMessage(
      id: 'lease-1',
      title: '租约提醒',
      content: '您的租约即将到期',
      category: MessageCategory.lease,
      isRead: true,
    ),
  ];

  @override
  Future<ApiResult<MessagePageData>> fetchMessages({
    MessageCategory? category,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = category == null
        ? _messages
        : _messages.where((message) => message.category == category).toList();
    return ApiSuccess(
      MessagePageData(
        items: items,
        page: page,
        pageSize: pageSize,
        total: items.length,
        hasMore: false,
      ),
    );
  }

  @override
  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts() async {
    return const ApiSuccess(MessageUnreadCounts(system: 1, bill: 1, total: 2));
  }

  @override
  Future<ApiResult<bool>> markAsRead(String id) async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> markAllAsRead() async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> deleteMessage(String id) async =>
      const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> clearReadMessages() async => const ApiSuccess(true);
}
