import 'package:intl/intl.dart';

final class AppFormatters {
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final DateFormat headerDate = DateFormat('EEEE, d MMM yyyy', 'id_ID');
  static final DateFormat compactDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat apiDate = DateFormat('yyyy-MM-dd', 'id_ID');
  static final DateFormat dateTime = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  static String rupiah(num value) => currency.format(value);

  const AppFormatters._();
}
