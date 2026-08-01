import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/config/app_config.dart';
import 'package:zhuxiang_app/core/constants/app_constants.dart';

void main() {
  test('runtime brand name is unified', () {
    expect(AppConstants.appName, '勿忧管家');
    expect(AppConfig.appName, '勿忧管家');
  });
}
