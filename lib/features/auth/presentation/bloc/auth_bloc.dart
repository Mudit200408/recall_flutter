import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recall/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  static const String _prefIsGuest = 'is_guest_mode';

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSkippedLogin>(_onAuthSkippedLogin);
  }

  FutureOr<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = authRepository.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      // Check if guest mode was previously saved
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_prefIsGuest) ?? false;
      if (isGuest) {
        emit(AuthGuest());
      } else {
        emit(AuthUnauthenticated());
      }
    }
  }

  FutureOr<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      if (user != null) {
        // Clear guest flag when signing in with Google
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefIsGuest);
        emit(AuthAuthenticated(user: user.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  FutureOr<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefIsGuest);
    emit(AuthUnauthenticated());
  }

  FutureOr<void> _onAuthSkippedLogin(
    AuthSkippedLogin event,
    Emitter<AuthState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsGuest, true);
    emit(AuthGuest());
  }
}
