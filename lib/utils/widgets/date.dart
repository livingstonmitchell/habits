// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class DateUtilsX {
  static final _fmt = DateFormat('yyyy-MM-dd');

  static String dateKey(DateTime d) => _fmt.format(DateTime(d.year, d.month, d.day));
  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
}
