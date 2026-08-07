import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/auth/data/auth_models.dart';
import 'package:zhuxiang_app/features/auth/presentation/widgets/auth_text_field.dart';

void main() {
  testWidgets('code button counts down and blocks duplicate requests', (
    tester,
  ) async {
    var requests = 0;
    var now = DateTime(2026, 8, 4, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthCodeButton(
            onPressed: () async {
              requests++;
              return const SmsCodeResult(expiresIn: 300, retryAfter: 3);
            },
            now: () => now,
          ),
        ),
      ),
    );

    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    expect(requests, 1);
    expect(find.text('3秒后重试'), findsOneWidget);

    await tester.tap(find.text('3秒后重试'));
    await tester.pump();
    expect(requests, 1);

    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('重新获取'), findsOneWidget);
  });

  testWidgets('server retryAfter also starts countdown after 429', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthCodeButton(
            onPressed: () async => null,
            retryAfterOnFailure: () => 5,
          ),
        ),
      ),
    );

    await tester.tap(find.text('获取验证码'));
    await tester.pump();

    expect(find.text('5秒后重试'), findsOneWidget);
  });
}
