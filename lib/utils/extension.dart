import 'package:intl/intl.dart';

extension CurrencyExtension on double {
  // TODO: Change your currency here
  String toCurrency({int decimalDigits = 2, String currencySymbol = "₦"}) {
    final formatter = NumberFormat.currency(locale: 'en_US', decimalDigits: decimalDigits, symbol: currencySymbol);
    return formatter.format(this);
  }

// TODO: Change your currency here
// String toProperDouble({int decimalDigits = 2, String currencySymbol = "₦"}) {
//   final formatter = NumberFormat.currency(locale: 'en_US', decimalDigits: decimalDigits, symbol: currencySymbol);
//   return formatter.format(this);
// }

}
