import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final supabase.SupabaseClient _supabaseClient = supabase.Supabase.instance.client;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    // Register event handlers
    on<CheckAuthStatus>((event, emit) async {
      try {
        final session = _supabaseClient.auth.currentSession;
        if (session != null) {
          emit(
            AuthAuthenticated(
              session.user.email ?? '',
              userId: session.user.id,
              userMetadata: session.user.userMetadata,
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

        if (response.user != null) {
          await _ensureUserExists(response.user!);
          emit(
            AuthAuthenticated(
              response.user!.email ?? '',
              userId: response.user!.id,
              userMetadata: response.user!.userMetadata,
            ),
          );
        } else {
          emit(AuthError('Login failed. Please try again.'));
        }
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
            emit(
              AuthEmailConfirmationRequired(
                'Please check your email and click the verification link to complete registration.',
              ),
            );
          } else {
            await _insertUserData(response.user!, event.userData);
            emit(
              AuthAuthenticated(
                response.user!.email ?? '',
                userId: response.user!.id,
                userMetadata: response.user!.userMetadata,
              ),
            );
          }
        } else {
          emit(AuthError('Registration failed. Please try again.'));
        }
      } on AuthException catch (e) {
        _handleAuthError(emit, e);
      } catch (e) {
        emit(AuthError('An unexpected error occurred. Please try again.'));
      }
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _supabaseClient.auth.signOut();
        emit(AuthInitial());
      } catch (e) {
        emit(AuthError('Failed to logout. Please try again.'));
      }
    });

    // ... other handlers ...

    // Internal events
    on<_AuthInternalAuthenticated>((event, emit) {
      if (state is! AuthAuthenticated ||
          (state as AuthAuthenticated).userId != event.user.id) {
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

    // Set up auth state listener
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      print('Auth state changed: ${event.toString()}, Session: ${session?.user.email}');

      if (session != null) {
        add(_AuthInternalAuthenticated(session.user));
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        add(_AuthInternalUnauthenticated());
      }
    });
  }

  Future<void> _insertUserData(
    supabase.User user,
    Map<String, dynamic>? userData,
  ) async {
    try {
      if (userData != null && userData.containsKey('name')) {
        await _supabaseClient.from('users').insert({
          'user_id': user.id,
          'email': user.email,
          'name': userData['name'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error inserting user data: $e');
    }
  }

  Future<void> _ensureUserExists(supabase.User user) async {
    try {
      final existingUser = await _supabaseClient
          .from('users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        await _supabaseClient.from('users').insert({
          'user_id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
    }
  }

  void _handleAuthError(Emitter<AuthState> emit, AuthException e) {
    String errorMessage;
    print('Auth error: ${e.message}');

    switch (e.message) {
      case 'Invalid login credentials':
        errorMessage = 'Invalid email or password. Please check your credentials.';
        break;
      case 'Email not confirmed':
        errorMessage = 'Please verify your email address before logging in.';
        break;
      case 'Too many requests':
        errorMessage = 'Too many login attempts. Please try again later.';
        break;
      case 'User already registered':
        errorMessage = 'An account with this email already exists. Please sign in instead.';
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

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

// Internal Events
class _AuthInternalAuthenticated extends AuthEvent {
  final supabase.User user;
  _AuthInternalAuthenticated(this.user);
}

class _AuthInternalUnauthenticated extends AuthEvent {}

// Event and state classes are the same as you posted earlier
