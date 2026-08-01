import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/widgets/app_webview_page.dart';

void main() {
  test('in-app webview only accepts valid http and https urls', () {
    expect(
      AppWebViewPage.supportsUrl('https://esign.example.com/sign'),
      isTrue,
    );
    expect(AppWebViewPage.supportsUrl('http://example.com/auth'), isTrue);
    expect(AppWebViewPage.supportsUrl('javascript:alert(1)'), isFalse);
    expect(AppWebViewPage.supportsUrl('esign://sign'), isFalse);
    expect(AppWebViewPage.supportsUrl('not-a-url'), isFalse);
  });
}
