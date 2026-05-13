import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';
import 'http_headers.dart';

class AuthService {
  static const _baseUrl = 'https://dummyjson.com/auth';

  /// Realiza login e retorna um [AuthUser] com tokens.
  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: HttpHeaders.json,
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 30,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthUser.fromJson(data);
    } else {
      throw Exception('Usuário ou senha inválidos.');
    }
  }

  /// Busca dados do usuário autenticado usando o token.
  Future<AuthUser> getCurrentUser(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // /auth/me não retorna tokens, então reutilizamos o token atual
      return AuthUser.fromJson({
        ...data,
        'accessToken': accessToken,
        'refreshToken': '',
      });
    } else {
      throw Exception('Token inválido ou expirado.');
    }
  }
}
