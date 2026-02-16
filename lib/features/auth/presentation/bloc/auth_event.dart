part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {}
class AuthSkippedLogin extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}