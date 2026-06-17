import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../errors/failure.dart';

class HttpResponse {
  final dynamic data;

  HttpResponse({required this.data});
}

class HttpClient {
  static const _headers = {'Content-Type': 'application/json'};
  static const _timeout = Duration(seconds: 10);

  Future<HttpResponse> get(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Failure('Sem conexão com a internet.');
    } on Failure {
      rethrow;
    } catch (_) {
      throw Failure('Erro inesperado ao buscar dados.');
    }
  }

  Future<HttpResponse> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse(url),
              headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response, acceptedCodes: [200, 201]);
    } on SocketException {
      throw Failure('Sem conexão com a internet.');
    } on Failure {
      rethrow;
    } catch (_) {
      throw Failure('Erro inesperado ao criar produto.');
    }
  }

  Future<HttpResponse> put(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(Uri.parse(url),
              headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Failure('Sem conexão com a internet.');
    } on Failure {
      rethrow;
    } catch (_) {
      throw Failure('Erro inesperado ao atualizar produto.');
    }
  }

  Future<HttpResponse> delete(String url) async {
    try {
      final response =
          await http.delete(Uri.parse(url)).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Failure('Sem conexão com a internet.');
    } on Failure {
      rethrow;
    } catch (_) {
      throw Failure('Erro inesperado ao remover produto.');
    }
  }

  HttpResponse _handleResponse(http.Response response,
    {List<int> acceptedCodes = const [200]}) {
    if (acceptedCodes.contains(response.statusCode)) {
      final data = jsonDecode(response.body);
      return HttpResponse(data: data);
    } else if (response.statusCode == 401) {
      throw UnauthorizedFailure();
    } else {
      throw Failure('Erro no servidor: ${response.statusCode}');
    }
  }
}
