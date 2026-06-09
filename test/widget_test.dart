import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/app.dart';

void main() {
  testWidgets('Zhuxiang app renders splash placeholder', (tester) async {
    await tester.pumpWidget(const ZhuxiangApp());
    await tester.pumpAndSettle();

    expect(find.text('住享'), findsWidgets);
    expect(find.text('App 启动页占位'), findsOneWidget);
  });
}
