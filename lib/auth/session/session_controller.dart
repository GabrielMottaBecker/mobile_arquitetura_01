import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class SessionController {
  static final SessionController instance = SessionController._();
  SessionController._();

  AuthUser? _user;

  AuthUser? get user => _user;
  String? get token => _user?.accessToken;
  bool get isLoggedIn => _user != null;

  /// Salva o usuário na sessão em memória e persiste o token localmente.
  Future<void> login(AuthUser user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', user.accessToken);
    await prefs.setString('refresh_token', user.refreshToken);
  }

  /// Remove a sessão da memória e do armazenamento local.
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  /// Lê o token salvo localmente (usado na tela splash).
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
