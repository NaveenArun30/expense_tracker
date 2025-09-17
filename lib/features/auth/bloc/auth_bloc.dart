import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final supabase.SupabaseClient _supabaseClient =
      supabase.Supabase.instance.client;

  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    // Check initial auth status
    _checkInitialAuthStatus();

    // Listen to real-time auth state changes from Supabase
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((
      data,
    ) {
      final session = data.session;
      if (session != null) {
        // User is authenticated
        add(_AuthInternalAuthenticated(session.user));
      } else {
        // User is not authenticated or logged out
        add(_AuthInternalUnauthenticated());
      }
    });

    on<CheckAuthStatus>((event, emit) async {
      try {
        final session = _supabaseClient.auth.currentSession;
        if (session != null && session.user != null) {
          emit(
            AuthAuthenticated(
              session.user!.email ?? '',
              userId: session.user!.id,
              userMetadata: session.user!.userMetadata,
            ),
          );
        } else {
          emit(AuthInitial());
        }
      } catch (e) {
        emit(AuthInitial());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await _supabaseClient.auth.signInWithPassword(
          email: event.email.trim(),
          password: event.password,
        );

        // Check if user exists in users table, if not create them
        if (response.user != null) {
          await _ensureUserExists(response.user!);
        }

        // The state will be updated by the onAuthStateChange listener
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        emit(AuthError('An unexpected error occurred. Please try again.'));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await _supabaseClient.auth.signUp(
          email: event.email.trim(),
          password: event.password,
          data: event.userData,
        );

        if (response.user != null) {
          if (response.session == null) {
            // Email confirmation is required
            emit(
              AuthEmailConfirmationRequired(
                'Please check your email and click the verification link to complete registration.',
              ),
            );
          } else {
            // User is automatically signed in after registration
            // Insert user data into the users table
            await _insertUserData(response.user!, event.userData);
            // The state will be updated by the onAuthStateChange listener
          }
        } else {
          emit(AuthError('Registration failed. Please try again.'));
        }
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        print('Registration error: $e');
        emit(AuthError('An unexpected error occurred. Please try again.'));
      }
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _supabaseClient.auth.signOut();
        emit(AuthInitial()); // 👈 ensures UI reacts immediately
      } catch (e) {
        emit(AuthError('Failed to logout. Please try again.'));
      }
    });

    on<SocialLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _supabaseClient.auth.signInWithOAuth(
          event.provider,
          redirectTo: event.redirectTo,
        );
        // The state will be updated by the onAuthStateChange listener
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        emit(AuthError('Social login failed. Please try again.'));
      }
    });

    on<PasswordResetRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _supabaseClient.auth.resetPasswordForEmail(
          event.email.trim(),
          redirectTo: event.redirectTo,
        );
        emit(
          AuthPasswordResetSent(
            'Password reset instructions have been sent to ${event.email}',
          ),
        );
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        emit(
          AuthError('Failed to send password reset email. Please try again.'),
        );
      }
    });

    on<ResendEmailConfirmation>((event, emit) async {
      emit(AuthLoading());
      try {
        await _supabaseClient.auth.resend(
          type: supabase.OtpType.signup,
          email: event.email.trim(),
        );
        emit(
          AuthEmailConfirmationRequired(
            'Confirmation email has been resent to ${event.email}',
          ),
        );
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        emit(
          AuthError('Failed to resend confirmation email. Please try again.'),
        );
      }
    });

    on<UpdateProfile>((event, emit) async {
      emit(AuthLoading());
      try {
        final userResponse = await _supabaseClient.auth.updateUser(
          supabase.UserAttributes(data: event.userData),
        );

        if (userResponse.user != null) {
          // Also update the users table
          await _supabaseClient
              .from('users')
              .update(event.userData)
              .eq('id', userResponse.user!.id);
          emit(
            AuthAuthenticated(
              userResponse.user!.email ?? '',
              userId: userResponse.user!.id,
              userMetadata: userResponse.user!.userMetadata,
            ),
          );
        } else {
          emit(AuthError('Failed to update profile.'));
        }
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        emit(AuthError('Failed to update profile. Please try again.'));
      }
    });

    // Internal events for handling state changes from the listener
    on<_AuthInternalAuthenticated>((event, emit) {
      if (state is! AuthAuthenticated) {
        emit(
          AuthAuthenticated(
            event.user.email ?? '',
            userId: event.user.id,
            userMetadata: event.user.userMetadata,
          ),
        );
      }
    });

    on<_AuthInternalUnauthenticated>((event, emit) {
      if (state is AuthAuthenticated || state is AuthLoading) {
        emit(AuthInitial());
      }
    });
  }

  void _checkInitialAuthStatus() {
    final session = _supabaseClient.auth.currentSession;
    if (session != null && session.user != null) {
      emit(
        AuthAuthenticated(
          session.user!.email ?? '',
          userId: session.user!.id,
          userMetadata: session.user!.userMetadata,
        ),
      );
    }
  }

  void _handleAuthError(Emitter<AuthState> emit, AuthException e) {
    String errorMessage;
    switch (e.message) {
      case 'Invalid login credentials':
        errorMessage =
            'Invalid email or password. Please check your credentials.';
        break;
      case 'Email not confirmed':
        errorMessage = 'Please verify your email address before logging in.';
        break;
      case 'Too many requests':
        errorMessage = 'Too many login attempts. Please try again later.';
        break;
      case 'User already registered':
        errorMessage =
            'An account with this email already exists. Please sign in instead.';
        break;
      case 'Password should be at least 6 characters':
        errorMessage = 'Password must be at least 6 characters long.';
        break;
      case 'Unable to validate email address: invalid format':
        errorMessage = 'Please enter a valid email address.';
        break;
      case 'Signup is disabled':
        errorMessage = 'New registrations are currently disabled.';
        break;
      default:
        errorMessage = e.message;
    }
    emit(AuthError(errorMessage));
  }

  Future<void> _insertUserData(
    supabase.User user,
    Map<String, dynamic>? userData,
  ) async {
    try {
      if (userData != null && userData.containsKey('name')) {
        await _supabaseClient.from('users').insert({
          'user_id': user
              .id, // This is now a UUID string, matching the UUID column type
          'email': user.email,
          'name': userData['name'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error inserting user data: $e');
      // You can log this error, but the user is still registered in Supabase auth.
    }
  }

  // Helper method to ensure user exists in users table (for login)
  Future<void> _ensureUserExists(supabase.User user) async {
    try {
      // Check if user exists in users table
      final existingUser = await _supabaseClient
          .from('users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      // If user doesn't exist, create them
      if (existingUser == null) {
        await _supabaseClient.from('users').insert({
          'user_id': user.id, // This is now correctly a UUID
          'email': user.email,
          'name':
              user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('User created successfully in users table');
      } else {
        print('User already exists in users table');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
      // Don't throw error here as auth is still successful
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

// Internal Events for the listener
class _AuthInternalAuthenticated extends AuthEvent {
  final supabase.User user;
  _AuthInternalAuthenticated(this.user);
}

class _AuthInternalUnauthenticated extends AuthEvent {}
