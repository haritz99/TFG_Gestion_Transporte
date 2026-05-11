import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/token_provider.dart';
import '../../../core/config/api_config.dart';


class PedidoService {
  final AuthTokenProvider tokenProvider;

  final String _baseUrl = '${ApiConfig.baseUrl}/pedidos';

  PedidoService(this.tokenProvider);

  Future<void> crearPedido({
    required String descripcion,
    required String clienteId,
    required DateTime fechaCarga,
    required DateTime fechaDescarga,
    required List<Map<String, dynamic>> cargas,
  }) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse(_baseUrl);

    final body = {
      'descripcion': descripcion,
      'clienteId': clienteId,
      'fechaCarga': fechaCarga.toIso8601String(),
      'fechaDescarga': fechaDescarga.toIso8601String(),
      'cargas': cargas,
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear el pedido: ${response.statusCode} - ${response.body}');
    }
  }
}