import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final _date = DateFormat('d MMMM yyyy', 'id_ID');
  static final _dayDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _dayShortDate = DateFormat('EEEE, d MMM yyyy', 'id_ID');
  static final _shortDate = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _compactDate = DateFormat('dd MMM yyyy', 'id_ID');
  static final _time = DateFormat('HH.mm.ss', 'id_ID');
  static final _shortTime = DateFormat('HH.mm', 'id_ID');
  static final _clockTime = DateFormat('HH:mm');

  static String rupiah(num value) => _rupiah.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dayDate(DateTime value) => _dayDate.format(value);
  static String dayShortDate(DateTime value) => _dayShortDate.format(value);
  static String shortDate(DateTime value) => _shortDate.format(value);
  static String compactDate(DateTime value) => _compactDate.format(value);
  static String time(DateTime value) => _time.format(value);
  static String shortTime(DateTime? value) =>
      value == null ? '--.--' : _shortTime.format(value);
  static String clockTime(DateTime value) => _clockTime.format(value);
}
