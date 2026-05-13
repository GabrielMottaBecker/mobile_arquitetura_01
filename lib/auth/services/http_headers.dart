import '../session/session_controller.dart';

/// Classe auxiliar para montar cabeçalhos HTTP reutilizáveis.
class HttpHeaders {
  HttpHeaders._();

  static const Map<String, String> json = {
    'Content-Type': 'application/json',
  };

  /// Retorna headers com Authorization Bearer usando o token da sessão ativa.
  static Map<String, String> get withToken {
    final token = SessionController.instance.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
