import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../models/user.dart';
import '../repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthState()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _repository.isLoggedIn();

    if (isLoggedIn) {
      try {
        final user = await _repository.getProfile();
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      } catch (e) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _repository.login(event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: _mapAuthError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, error: e.toString()),
      );
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _repository.register(
        email: event.email,
        username: event.username,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: _mapAuthError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, error: e.toString()),
      );
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _repository.updateProfile(event.data);
      emit(state.copyWith(user: user));
    } on DioException catch (e) {
      emit(state.copyWith(error: _mapAuthError(e)));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  String _mapAuthError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (statusCode == 401) {
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return 'Identifiants invalides ou session expiree.';
    }

    if (statusCode == 400) {
      if (data is Map) {
        final fieldMessages = <String>[];
        for (final entry in data.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            fieldMessages.add('${_labelForField(key)}: ${value.first}');
          } else if (value is String) {
            fieldMessages.add('${_labelForField(key)}: $value');
          }
        }
        if (fieldMessages.isNotEmpty) {
          return fieldMessages.join('\n');
        }
      }
      return 'Donnees invalides. Verifiez les champs saisis.';
    }

    if (statusCode == 409) {
      return 'Compte deja existant. Utilisez un autre email/nom utilisateur.';
    }

    return e.toString();
  }

  String _labelForField(String field) {
    switch (field) {
      case 'email':
        return 'Email';
      case 'username':
        return 'Nom utilisateur';
      case 'password':
        return 'Mot de passe';
      case 'password_confirm':
        return 'Confirmation mot de passe';
      case 'non_field_errors':
        return 'Erreur';
      default:
        return field;
    }
  }
}
