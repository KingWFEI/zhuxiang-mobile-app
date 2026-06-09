import 'package:intl/intl.dart';

class DateTimeUtils {
  const DateTimeUtils._();

  static String formatDate(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  static String formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }
}
