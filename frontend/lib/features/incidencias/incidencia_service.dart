import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../auth/providers/token_provider.dart';

class IncidenciaService {
  final AuthTokenProvider _tokenProvider;

  IncidenciaService(this._tokenProvider);

  Future<void> createIncidencia({
    required String cargaId,
    required String tipo,
    required String descripcion,
  }) async {
    final token = await _tokenProvider.getRequiredToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/cargas/$cargaId/incidencia');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'tipo': tipo, 'descripcion': descripcion})
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al crear incidencia');
    }
  }

  Future<void> resolverIncidencia({required String cargaId, required String incidenciaId}) async {
    final token = await _tokenProvider.getRequiredToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/cargas/$cargaId/incidencia/$incidenciaId/resolver');
    final response = await http.patch(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al resolver incidencia');
    }
  }
}