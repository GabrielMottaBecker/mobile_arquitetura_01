class Failure implements Exception {
  final String message;
  Failure(this.message);

  @override
  String toString() => message;
}

class UnauthorizedFailure extends Failure {
  UnauthorizedFailure() : super('Sessão expirada. Faça login novamente.');
}