import 'package:intl/intl.dart';
import '../../config/constants.dart' as constants;

class DateUtils {
  static String formatDateTime(DateTime date) {
    return DateFormat(constants.AppConstants.dateTimeFormat).format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat(constants.AppConstants.dateFormat).format(date);
  }
}