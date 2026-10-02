import 'package:intl/intl.dart';

/// Polish-locale formatting for the mono data layer: thin-space thousands,
/// comma decimals. Kept in one place so every screen prints `18 430 KM` and
/// `540,00 ZŁ` the same way.
class Fmt {
  Fmt._();

  static final NumberFormat _int = NumberFormat.decimalPattern('pl_PL');
  static final NumberFormat _money = NumberFormat('#,##0.00', 'pl_PL');
  static final NumberFormat _one = NumberFormat('#,##0.0', 'pl_PL');

  /// `18 430`
  static String km(num value) => _int.format(value);

  /// `18 430 KM`
  static String kmUnit(num value) => '${_int.format(value)} KM';

  /// `540,00 ZŁ`
  static String money(num value) => '${_money.format(value)} ZŁ';

  /// `15,5 L`
  static String litres(num value) => '${_one.format(value)} L';

  /// `5,8`
  static String decimal1(num value) => _one.format(value);

  /// `01.10.2026`
  static String date(DateTime value) =>
      '${_pad(value.day)}.${_pad(value.month)}.${value.year}';

  /// `01.10.2026 · 21:47`
  static String dateTime(DateTime value) =>
      '${date(value)} · ${_pad(value.hour)}:${_pad(value.minute)}';

  /// Leading-zero technical numbering: `0007`.
  static String serial(int value, {int width = 4}) =>
      value.toString().padLeft(width, '0');

  /// `CZWARTEK`
  static String weekday(DateTime value) =>
      _weekdays[value.weekday - 1].toUpperCase();

  static const List<String> _weekdays = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
