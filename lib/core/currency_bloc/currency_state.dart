import '../../model/currency_model.dart';

class CurrencyState {
  final Currency selectedCurrency;

  const CurrencyState(this.selectedCurrency);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyState &&
          runtimeType == other.runtimeType &&
          selectedCurrency == other.selectedCurrency;

  @override
  int get hashCode => selectedCurrency.hashCode;
}
