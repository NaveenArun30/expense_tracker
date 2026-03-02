import 'package:google_generative_ai/google_generative_ai.dart';
import '../model/expense_model.dart';
import '../model/income_model.dart';

class AiService {
  Future<String> getFinancialInsights({
    required String apiKey,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> income,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    // Filter data for the selected period if not already filtered,
    // but typically the bloc handles filtering.
    // We'll assume the lists passed are already relevant.

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );

      final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalIncome = income.fold(0.0, (sum, e) => sum + e.amount);

      final prompt =
          '''
Analyze the following financial data for the period ${startDate.toLocal()} to ${endDate.toLocal()}:

Total Income: $totalIncome
Total Expenses: $totalExpense

Expense Breakdown:
${expenses.map((e) => '- ${e.title} (${e.category}): ${e.amount} on ${e.date.toLocal()}').join('\n')}

Income Breakdown:
${income.map((e) => '- ${e.source} : ${e.amount} on ${e.date.toLocal()}').join('\n')}

Please provide a brief summary of spending habits and 3 actionable, concise bullet points on how to save money. 
Format the response in Markdown.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? 'Unable to generate insights at this time.';
    } catch (e) {
      throw Exception('Failed to generate insights: $e');
    }
  }

  Stream<String> chatWithAi({
    required String apiKey,
    required String message,
    required List<ExpenseModel> expenses,
    required List<IncomeModel> income,
    required List<Content> history,
  }) async* {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );

      final chat = model.startChat(history: history);

      final contextPrompt =
          '''
Context - User's Financial Data:
Expenses: ${expenses.length} transactions.
Income: ${income.length} transactions.

User Message: $message
''';

      final response = chat.sendMessageStream(Content.text(contextPrompt));

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      throw Exception('Failed to chat: $e');
    }
  }
}
