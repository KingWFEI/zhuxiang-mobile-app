import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/app.dart';
import 'package:zhuxiang_app/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:zhuxiang_app/features/auth/presentation/pages/login_page.dart';
import 'package:zhuxiang_app/features/auth/presentation/pages/register_page.dart';
import 'package:zhuxiang_app/features/home/presentation/pages/home_page.dart';

void main() {
  test('mock auth separates verification code and password login', () async {
    final datasource = MockAuthDatasource();

    await expectLater(
      datasource.loginWithCode(phone: '13800138000', code: '123456'),
      throwsA(isA<MockAuthException>()),
    );

    final codeUser = await datasource.loginWithCode(
      phone: '13800138000',
      code: MockAuthDatasource.validCode,
    );
    expect(codeUser.phone, '13800138000');

    await datasource.logout();

    final passwordUser = await datasource.loginWithPassword(
      phone: '13800138000',
      password: '123456',
    );
    expect(passwordUser.phone, '13800138000');
  });

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

  testWidgets('home page switches house categories without lock content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomePage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('短租'), findsOneWidget);
    expect(find.text('民宿'), findsOneWidget);
    expect(find.text('长租'), findsOneWidget);
    expect(find.text('为你精选'), findsOneWidget);
    expect(find.text('便捷服务'), findsOneWidget);
    expect(find.text('我的租约'), findsOneWidget);
    expect(find.text('开门记录'), findsOneWidget);
    expect(find.text('报修服务'), findsOneWidget);
    expect(find.text('在线客服'), findsOneWidget);
    expect(find.text('我的家'), findsNothing);
    expect(find.text('蓝牙开锁'), findsNothing);
    expect(find.text('远程开锁'), findsNothing);
    expect(find.byType(SliverPersistentHeader), findsOneWidget);
    expect(find.byType(SliverMasonryGrid), findsWidgets);
    expect(find.text('品牌推荐'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('开门记录'));
    await tester.pump();

    expect(find.text('开门记录功能开发中'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('便捷服务').hitTestable(), findsNothing);
    expect(find.text('推荐').hitTestable(), findsOneWidget);
    expect(find.text('住享').hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-category-homestay')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 420));
    await tester.pumpAndSettle();

    expect(find.text('便捷服务').hitTestable(), findsOneWidget);
    expect(find.text('城市民宿'), findsOneWidget);
    expect(find.text('精选专题'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('login page switches between code and password modes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(_textFieldWithHint('验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('密码登录'), findsOneWidget);

    await tester.tap(find.text('密码登录'));
    await tester.pump();

    expect(_textFieldWithHint('密码'), findsOneWidget);
    expect(find.text('获取验证码'), findsNothing);
    expect(find.text('验证码登录'), findsOneWidget);

    final passwordField = tester.widget<TextField>(_textFieldWithHint('密码'));
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.text('验证码登录'));
    await tester.pump();

    expect(_textFieldWithHint('验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
  });

  testWidgets('password value is rejected in verification code mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.enterText(_textFieldWithHint('手机号'), '13800138000');
    await tester.enterText(_textFieldWithHint('验证码'), '123456');
    await tester.tap(find.byIcon(Icons.radio_button_unchecked_outlined));
    await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('手机号或验证码不正确'), findsOneWidget);
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

Finder _textFieldWithHint(String hintText) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hintText,
  );
}
