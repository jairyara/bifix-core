import 'package:intl/intl.dart';

/// Shared formatting helpers (Spanish locale).
class Fmt {
  const Fmt._();

  static final _km = NumberFormat('#,##0.0', 'es');
  static final _int = NumberFormat('#,##0', 'es');
  static final _date = DateFormat('d MMM yyyy', 'es');
  static final _dateShort = DateFormat('d MMM', 'es');

  static String km(num value) => '${_km.format(value)} km';
  static String integer(num value) => _int.format(value);
  static String date(DateTime d) => _date.format(d);
  static String dateShort(DateTime d) => _dateShort.format(d);

  static String money(int cents) {
    final f = NumberFormat.currency(locale: 'es', symbol: '\$');
    return f.format(cents / 100);
  }

  /// "hace 3 días", "hoy", "ayer".
  static String ago(DateTime d, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final days = DateTime(reference.year, reference.month, reference.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (days <= 0) return 'hoy';
    if (days == 1) return 'ayer';
    if (days < 30) return 'hace $days días';
    final months = (days / 30).floor();
    if (months == 1) return 'hace 1 mes';
    if (months < 12) return 'hace $months meses';
    final years = (days / 365).floor();
    return years == 1 ? 'hace 1 año' : 'hace $years años';
  }
}
