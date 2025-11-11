import 'package:intl/intl.dart';

class Formatters {
  // Formatar moeda Moçambique
  static String formatarMoeda(double valor) {
    return NumberFormat.currency(
      locale: 'pt_MZ',
      symbol: 'MT ',
      decimalDigits: 2,
    ).format(valor);
  }

  // Formatar data
  static String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(data);
  }

  // Formatar data curta
  static String formatarDataCurta(DateTime data) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(data);
  }
}
