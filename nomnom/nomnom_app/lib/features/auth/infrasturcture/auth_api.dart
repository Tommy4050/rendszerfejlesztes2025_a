import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user.dart';
import '../../../core/network/dio_client.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(baseDioProvider);
  return AuthApi(dio);
});

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<({String token, AppUser user})> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<({String token, AppUser user})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<AppUser> getMe() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
