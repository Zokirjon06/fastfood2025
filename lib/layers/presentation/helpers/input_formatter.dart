import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class InputFormatters extends MaskTextInputFormatter {
  static MaskTextInputFormatter debtAmountFormatter= MaskTextInputFormatter(
    mask: '###.###.###.###.###.###',
    type: MaskAutoCompletionType.lazy,
  );

  static CurrencyTextInputFormatter moneyFormatter =
      CurrencyTextInputFormatter.currency(symbol: '', decimalDigits: 0,);
}
