import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../constants/app_constants.dart';
import '../bloc/ai_bloc.dart';
import '../bloc/ai_event.dart';
import '../bloc/ai_state.dart';
import '../../income/bloc/income_bloc.dart';
import '../../expenses/bloc/expense_bloc.dart';
import '../../expenses/bloc/expense_state.dart';
import '../../income/bloc/income_state.dart';
import '../../../model/income_model.dart';
import '../../../model/expense_model.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final message = _controller.text;
    setState(() {
      _messages.add(Message(text: message, isUser: true));
      _controller.clear();
    });

    final expenseState = context.read<ExpenseBloc>().state;
    final incomeState = context.read<IncomeBloc>().state;

    // Use current state expenses/income or empty lists if loading/error
    final expenses = expenseState is ExpenseLoaded
        ? expenseState.expenses
        : <ExpenseModel>[];
    // Cast strict type required for IncomeLoaded
    final income = incomeState is IncomeLoaded
        ? incomeState.incomes
        : <IncomeModel>[];

    context.read<AiBloc>().add(
      SendChatMessage(message: message, expenses: expenses, income: income),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'AI Financial Assistant',
          style: TextStyle(color: AppConstants.textOnPrimary),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
      ),
      body: BlocListener<AiBloc, AiState>(
        listener: (context, state) {
          if (state is AiChatResponse) {
            setState(() {
              _messages.add(Message(text: state.response, isUser: false));
            });
          } else if (state is AiError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? AppConstants.primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: msg.isUser
                          ? Text(
                              msg.text,
                              style: const TextStyle(color: Colors.white),
                            )
                          : MarkdownBody(data: msg.text),
                    ),
                  );
                },
              ),
            ),
            if (context.watch<AiBloc>().state is AiLoading)
              const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about your finances...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _sendMessage,
                    backgroundColor: AppConstants.primaryColor,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}
