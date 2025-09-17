abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String email;
  final String? userId;
  final Map<String, dynamic>? userMetadata;
  
  AuthAuthenticated(
    this.email, {
    this.userId,
    this.userMetadata,
  });
}

class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
}

class AuthEmailConfirmationRequired extends AuthState {
  final String message;
  
  AuthEmailConfirmationRequired(this.message);
}

class AuthPasswordResetSent extends AuthState {
  final String message;
  
  AuthPasswordResetSent(this.message);
}