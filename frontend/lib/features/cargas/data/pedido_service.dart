import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/token_provider.dart';
import '../../../core/api_config.dart';
import '../../../core/models/pedido_model.dart';

class PedidoService {
  final AuthTokenProvider tokenProvider;

  final String _baseUrl = '${ApiConfig.baseUrl}/pedidos';

  PedidoService(this.tokenProvider);

  Future<void> crearPedido({
    required String destinatarioNombre,
    required String destinatarioNif,
    required String destinatarioDireccion,
    String? descripcion,
    required String clienteId,
    required DateTime fechaCarga,
    required DateTime fechaDescarga,
    required List<Map<String, dynamic>> cargas,
  }) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse(_baseUrl);

    final body = {
      'destinatarioNombre': destinatarioNombre,
      'destinatarioNif': destinatarioNif,
      'destinatarioDireccion': destinatarioDireccion,
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

  Future<List<PedidoModel>> getPedidosDelCargador() async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/cargador');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => PedidoModel.fromMap(e, e['id'])).toList();
    } else {
      throw Exception('Error al obtener pedidos: ${response.statusCode} - ${response.body}');
    }
  }
}