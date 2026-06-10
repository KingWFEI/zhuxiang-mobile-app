import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/app.dart';
import 'package:zhuxiang_app/features/auth/presentation/pages/login_page.dart';
import 'package:zhuxiang_app/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('Zhuxiang app renders loading page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZhuxiangApp()));
    await tester.pump();

    expect(find.text('住享'), findsWidgets);
    expect(find.text('把租住安排得更简单'), findsOneWidget);
    expect(find.text('正在加载房源与租约信息'), findsOneWidget);
    expect(find.bySemanticsLabel('加载页占位图'), findsOneWidget);
  });

  testWidgets('loading page enters bottom navigation shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZhuxiangApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('找房'), findsWidgets);
    expect(find.text('消息'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('租约'), findsNothing);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('未登录'), findsOneWidget);
  });

  testWidgets('login page validates empty phone', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    final loginButton = find.widgetWithText(ElevatedButton, '登录');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('请输入手机号'), findsOneWidget);
  });

  testWidgets('register page validates empty phone', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterPage())),
    );

    final registerButton = find.widgetWithText(ElevatedButton, '注册');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('请输入手机号'), findsOneWidget);
  });
}
