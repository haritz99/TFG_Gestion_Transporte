import '../features/auth/auth_service.dart';

class AuthTokenProvider {
  final AuthService _authService;

  AuthTokenProvider(this._authService);

  Future<String> getRequiredToken() async {
    final token = await _authService.getIdToken(forceRefresh: false) ??
        await _authService.getIdToken(forceRefresh: true);

    if (token == null || token.isEmpty) {
      throw Exception('No se pudo obtener un token valido. Inicia sesion de nuevo.');
    }

    return token;
  }
}
