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
    required List<AccountModel> accounts,
    required List<Content> history,
  }) async* {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    try {
      final accountMap = <String, String>{};
      for (var a in accounts) {
        if (a.id != null) {
          accountMap[a.id!] = a.accountName;
        }
      }

      // Format accounts info
      final accountsStr = accounts.isEmpty
          ? 'No accounts found.'
          : accounts.map((a) => '- Account: ${a.accountName}, Balance: \$${a.balance.toStringAsFixed(2)}').join('\n');

      // Format income info
      final incomeStr = income.isEmpty
          ? 'No income records found.'
          : income.map((i) => '- Source: ${i.source}, Amount: \$${i.amount.toStringAsFixed(2)}, Date: ${i.date.toIso8601String().split('T')[0]}, Account: ${i.accountName}, Description: ${i.description ?? "None"}').join('\n');

      // Format expense info
      final expensesStr = expenses.isEmpty
          ? 'No expense records found.'
          : expenses.map((e) {
              final accountName = accountMap[e.accountId] ?? 'Unknown';
              return '- Title: ${e.title}, Amount: \$${e.amount.toStringAsFixed(2)}, Category: ${e.category}, Date: ${e.date.toIso8601String().split('T')[0]}, Account: $accountName, Description: ${e.description ?? "None"}';
            }).join('\n');

      final systemPrompt = '''
You are a helpful, professional, and friendly personal financial assistant.
You have access to the user's real-time financial database.

Current Database State:
1. Accounts:
$accountsStr

2. Income Records:
$incomeStr

3. Expense Records:
$expensesStr

Guidelines for responding:
- Only answer using the transactions and accounts present in the database.
- If the user asks about a transaction, category, or account that does not exist in the database, clearly state: "I couldn't find any record of that in your database." and offer to help them look for something else or guide them on how to add it. Do NOT make up or assume any transactions.
- Keep your answers concise, accurate, and format them nicely in Markdown.
- If asked for general advice or explanations (e.g., "how can I save money?"), you can answer using your general knowledge, but reference their actual database records where relevant.
- Current date and time: ${DateTime.now().toLocal()}. Use this to reason about "this month", "last week", "yesterday", etc.
''';

      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
        systemInstruction: Content.system(systemPrompt),
      );

      final chat = model.startChat(history: history);
      final response = chat.sendMessageStream(Content.text(message));

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
