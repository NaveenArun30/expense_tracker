import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/currency_model.dart';
import '../../services/preferences_service.dart';
import 'currency_state.dart';

class CurrencyCubit extends Cubit<CurrencyState> {
  final PreferencesService _preferencesService;

  CurrencyCubit({required PreferencesService preferencesService})
      : _preferencesService = preferencesService,
        super(const CurrencyState(
          Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
        ));

  Future<void> loadCurrency() async {
    final code = await _preferencesService.getCurrencyCode();
    if (code != null) {
      final currency = availableCurrencies.firstWhere(
        (c) => c.code == code,
        orElse: () => const Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
      );
      emit(CurrencyState(currency));
    }
  }

  Future<void> setCurrency(Currency currency) async {
    await _preferencesService.saveCurrencyCode(currency.code);
    emit(CurrencyState(currency));
  }
}

extension CurrencyContext on BuildContext {
  Currency get currency => watch<CurrencyCubit>().state.selectedCurrency;
  String get currencySymbol => currency.symbol;
  String get currencyCode => currency.code;
}
