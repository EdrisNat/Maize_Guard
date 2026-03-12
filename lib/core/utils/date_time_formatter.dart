import 'package:intl/intl.dart';

class DateTimeFormatter {
  static final _formatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _timeFormatter = DateFormat('hh:mm a');

  static String format(DateTime value) => _formatter.format(value);
  static String formatDate(DateTime value) => _dateFormatter.format(value);
  static String formatTime(DateTime value) => _timeFormatter.format(value);
}
