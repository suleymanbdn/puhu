import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Auth durumu
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

/// Auth state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  static const String _currentUserKey = 'current_user_id';

  Box<User>? _usersBox;

  Future<void> _init() async {
    _usersBox = Hive.box<User>(AppConstants.usersBox);
    await _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);

      if (userId != null && _usersBox != null) {
        final user = _usersBox!.get(userId);
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
          );
          return;
        }
      }

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Giriş yap
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_usersBox == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Veritabanı hatası',
        );
        return false;
      }

      // Kullanıcıyı bul
      final users = _usersBox!.values.toList();
      final user = users.where((u) => u.username == username).firstOrNull;

      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Kullanıcı bulunamadı',
        );
        return false;
      }

      if (user.password != password) {
        state = state.copyWith(
          isLoading: false,
          error: 'Hatalı parola',
        );
        return false;
      }

      // Giriş başarılı
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _usersBox!.put(user.id, updatedUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, user.id);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: updatedUser,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Giriş hatası: $e',
      );
      return false;
    }
  }

  /// Üye ol
  Future<bool> register(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_usersBox == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Veritabanı hatası',
        );
        return false;
      }

      // Kullanıcı adı kontrolü
      final users = _usersBox!.values.toList();
      final existingUser = users.where((u) => u.username == username).firstOrNull;

      if (existingUser != null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Bu kullanıcı adı zaten kullanılıyor',
        );
        return false;
      }

      // Yeni kullanıcı oluştur
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = User(
        id: userId,
        username: username,
        password: password,
        createdAt: DateTime.now(),
      );

      await _usersBox!.put(userId, newUser);

      // Otomatik giriş yap
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, userId);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: newUser,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Kayıt hatası: $e',
      );
      return false;
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Hata mesajını temizle
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});





