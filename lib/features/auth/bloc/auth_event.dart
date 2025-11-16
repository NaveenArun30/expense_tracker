abstract class AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final Map<String, dynamic>? userData; // Optional additional user data

  RegisterRequested(this.email, this.password, {this.userData});
}

class LogoutRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;
  final String? redirectTo; // Optional redirect URL after password reset

  PasswordResetRequested(this.email, {this.redirectTo});
}

class ResendEmailConfirmation extends AuthEvent {
  final String email;

  ResendEmailConfirmation(this.email);
}

class SocialLoginRequested extends AuthEvent {
  final provider; // Google, Apple, GitHub, etc.
  final String? redirectTo;

  SocialLoginRequested(this.provider, {this.redirectTo});
}

class UpdateProfile extends AuthEvent {
  final Map<String, dynamic> userData;

  UpdateProfile(this.userData);
}
