import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/ai_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/supabase_service.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiService _aiService;
  final PreferencesService _preferencesService;
  final List<Content> _chatHistory = [];

  AiBloc({
    required AiService aiService,
    required PreferencesService preferencesService,
  }) : _aiService = aiService,
       _preferencesService = preferencesService,
       super(AiInitial()) {
    on<GenerateInsights>(_onGenerateInsights);
    on<SendChatMessage>(_onSendChatMessage);
  }

  Future<void> _onGenerateInsights(
    GenerateInsights event,
    Emitter<AiState> emit,
  ) async {
    emit(AiLoading());
    try {
      final apiKey = await _preferencesService.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        emit(const AiError('API Key not found. Please set it in Settings.'));
        return;
      }

      final insights = await _aiService.getFinancialInsights(
        apiKey: apiKey,
        expenses: event.expenses,
        income: event.income,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(AiInsightsLoaded(insights));
    } catch (e) {
      emit(AiError(e.toString()));
    }
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<AiState> emit,
  ) async {
    emit(AiLoading());
    try {
      final apiKey = await _preferencesService.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        emit(const AiError('API Key not found. Please set it in Settings.'));
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        emit(const AiError('User not authenticated. Please log in.'));
        return;
      }

      // Fetch all real-time transaction data and accounts from database
      final expenses = await SupabaseService.getAllExpenses(userId: userId);
      final income = await SupabaseService.getAllIncome(userId: userId);
      final accounts = await SupabaseService.getAccounts(userId: userId);

      // We collect the full response string for simplicity in this iteration
      final stream = _aiService.chatWithAi(
        apiKey: apiKey,
        message: event.message,
        expenses: expenses,
        income: income,
        accounts: accounts,
        history: _chatHistory,
      );

      final StringBuffer fullResponse = StringBuffer();
      await for (final chunk in stream) {
        fullResponse.write(chunk);
      }

      final responseText = fullResponse.toString();

      // Update history
      _chatHistory.add(Content.text(event.message));
      _chatHistory.add(Content.model([TextPart(responseText)]));

      emit(AiChatResponse(responseText));
    } catch (e) {
      emit(AiError(e.toString()));
    }
  }
}
