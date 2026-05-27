import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker_app/core/currency_bloc/currency_cubit.dart';
import 'package:expense_tracker_app/model/currency_model.dart';
import 'package:expense_tracker_app/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferencesService;
  late CurrencyCubit currencyCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferencesService = PreferencesService();
    currencyCubit = CurrencyCubit(preferencesService: preferencesService);
  });

  tearDown(() {
    currencyCubit.close();
  });

  group('CurrencyCubit Tests', () {
    test('initial state is INR (₹)', () {
      expect(
        currencyCubit.state.selectedCurrency,
        const Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
      );
    });

    test('loadCurrency returns default when not set', () async {
      await currencyCubit.loadCurrency();
      expect(
        currencyCubit.state.selectedCurrency,
        const Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
      );
    });

    test('setCurrency updates state and persists it', () async {
      const usd = Currency(code: 'USD', symbol: '\$', name: 'US Dollar');
      await currencyCubit.setCurrency(usd);

      expect(currencyCubit.state.selectedCurrency, usd);

      final savedCode = await preferencesService.getCurrencyCode();
      expect(savedCode, 'USD');
    });

    test('loadCurrency loads persisted currency code', () async {
      await preferencesService.saveCurrencyCode('EUR');

      final newCubit = CurrencyCubit(preferencesService: preferencesService);
      await newCubit.loadCurrency();

      expect(
        newCubit.state.selectedCurrency,
        const Currency(code: 'EUR', symbol: '€', name: 'Euro'),
      );
      newCubit.close();
    });
  });
}
