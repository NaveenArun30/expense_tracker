import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker_app/core/budget_bloc/budget_cubit.dart';
import 'package:expense_tracker_app/core/budget_bloc/budget_state.dart';
import 'package:expense_tracker_app/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferencesService;
  late BudgetCubit budgetCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferencesService = PreferencesService();
    budgetCubit = BudgetCubit(preferencesService: preferencesService);
  });

  tearDown(() {
    budgetCubit.close();
  });

  group('BudgetCubit Tests', () {
    test('initial state is monthly=0.0, yearly=0.0', () {
      expect(budgetCubit.state.monthlyBudget, 0.0);
      expect(budgetCubit.state.yearlyBudget, 0.0);
    });

    test('loadBudgets returns default 0.0 when not set', () async {
      await budgetCubit.loadBudgets();
      expect(budgetCubit.state.monthlyBudget, 0.0);
      expect(budgetCubit.state.yearlyBudget, 0.0);
    });

    test('setMonthlyBudget updates state and persists it', () async {
      await budgetCubit.setMonthlyBudget(5000.0);

      expect(budgetCubit.state.monthlyBudget, 5000.0);

      final savedMonthly = await preferencesService.getMonthlyBudget();
      expect(savedMonthly, 5000.0);
    });

    test('setYearlyBudget updates state and persists it', () async {
      await budgetCubit.setYearlyBudget(60000.0);

      expect(budgetCubit.state.yearlyBudget, 60000.0);

      final savedYearly = await preferencesService.getYearlyBudget();
      expect(savedYearly, 60000.0);
    });

    test('loadBudgets loads persisted budget amounts', () async {
      await preferencesService.saveMonthlyBudget(12000.0);
      await preferencesService.saveYearlyBudget(150000.0);

      final newCubit = BudgetCubit(preferencesService: preferencesService);
      await newCubit.loadBudgets();

      expect(newCubit.state.monthlyBudget, 12000.0);
      expect(newCubit.state.yearlyBudget, 150000.0);
      newCubit.close();
    });
  });
}
