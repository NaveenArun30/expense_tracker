import 'package:equatable/equatable.dart';

abstract class AiState extends Equatable {
  const AiState();

  @override
  List<Object?> get props => [];
}

class AiInitial extends AiState {}

class AiLoading extends AiState {}

class AiInsightsLoaded extends AiState {
  final String insights;

  const AiInsightsLoaded(this.insights);

  @override
  List<Object?> get props => [insights];
}

class AiError extends AiState {
  final String message;

  const AiError(this.message);

  @override
  List<Object?> get props => [message];
}

class AiChatResponse extends AiState {
  final String response;

  const AiChatResponse(this.response);

  @override
  List<Object?> get props => [response];
}
