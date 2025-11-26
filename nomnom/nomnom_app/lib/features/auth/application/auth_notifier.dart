import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/user.dart';
import '../infrasturcture/auth_api.dart';

const _tokenKey = 'nomnom_jwt_token';

class AuthState {
  final AppUser? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AppUser? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => token != null && user != null;
}

final _secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(_secureStorageProvider);
  return AuthNotifier(api, storage)..init();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _api;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthState());

  Future<void> init() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return;

      state = state.copyWith(token: token, isLoading: true);

      final user = await _api.getMe();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      await _storage.delete(key: _tokenKey);
      state = const AuthState();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result =
          await _api.register(username: username, email: email, password: password);

      await _storage.write(key: _tokenKey, value: result.token);

      state = AuthState(
        user: result.user,
        token: result.token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed',
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.login(email: email, password: password);

      await _storage.write(key: _tokenKey, value: result.token);

      state = AuthState(
        user: result.user,
        token: result.token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    state = const AuthState();
  }
}
