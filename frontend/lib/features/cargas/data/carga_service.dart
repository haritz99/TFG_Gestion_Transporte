import 'dart:convert';
import 'package:gestion_transporte/core/models/external_user_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/models/carga_model.dart';
import '../../auth/providers/token_provider.dart';
import '../../../core/api_config.dart';

class CargaService {
  final AuthTokenProvider tokenProvider;

  final String _baseUrl = '${ApiConfig.baseUrl}/cargas';

  CargaService(this.tokenProvider);

  Future<List<CargaModel>> getCargasDelMes(DateTime start, DateTime end) async {
    final token = await tokenProvider.getRequiredToken();

    final formato = DateFormat('yyyy-MM-dd');
    final inicio = formato.format(start);
    final fin = formato.format(end);

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'fecha_inicio': inicio,
      'fecha_fin': fin,
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CargaModel.fromMap(json, json['id'])).toList();
    } else {
      throw Exception('Error al cargar las cargas');
    }
  }

  Future<List<TipoCargaModel>> fetchTiposCarga(String cargadorId) async {
    final token = await tokenProvider.getRequiredToken();

    final uri = Uri.parse('$_baseUrl/tipos').replace(queryParameters: {
      'cliente_id': cargadorId,
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener tipos de carga: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => TipoCargaModel.fromMap(e, e['id'])).toList();
  }

  Future<TipoCargaModel> createTipoCarga(TipoCargaModel tipo) async {
    final token = await tokenProvider.getRequiredToken();

    final uri = Uri.parse('$_baseUrl/tipos');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(tipo.toMap()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear tipo de carga: ${response.statusCode} - ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return TipoCargaModel.fromMap(data, data['id']);
  }

  Future<void> updateCargas(List<CargaModel> cargas) async {
    final token = await tokenProvider.getRequiredToken();

    final uri = Uri.parse('$_baseUrl/bulk');

    final body = jsonEncode(cargas.map((c) => c.toMap()).toList());

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar las cargas: ${response.statusCode} - ${response.body}');
    }
  }

  Future<CargaModel> cederCarga({required String cargaId, required String subcontratadoUid}) async {
    final token = await tokenProvider.getRequiredToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/$cargaId/subcontratar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'subcontratadoId': subcontratadoUid}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al ceder la carga: ${response.statusCode} - ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return CargaModel.fromMap(data, data['id'] as String);
  }

  Future<List<CargaModel>> getCargasCedidas() async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/subcontratado');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => CargaModel.fromMap(e, e['id'])).toList();
    } else {
      throw Exception('Error al obtener cargas cedidas');
    }
  }

  Future<CargaModel> updateCargaSubcontratado({
    required String cargaId,
    required UpdateCargaSubcontratadoDto dto,
  }) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/sub/$cargaId');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dto.toMap()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CargaModel.fromMap(data, data['id']);
    } else {
      throw Exception('Error al actualizar carga cedida: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> generarCartaDePorte(String cargaId) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/$cargaId/carta-porte');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al generar carta de porte: ${response.statusCode} - ${response.body}');
    }
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    return responseData['url'] as String;
  }

  Future<CargaModel> updateEstado(String cargaId, EstadoCarga estado) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/$cargaId/estado');

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'estado': estado.value}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CargaModel.fromMap(data, data['id']);
    } else {
      throw Exception('Error al actualizar estado: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateBufferHours(String cargaId, int bufferHours) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/$cargaId/buffer-hours');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bufferHours': bufferHours}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar horas de buffer: ${response.statusCode} - ${response.body}');
    }
  }

  Future<CargaModel> updateCargaDetalles(String cargaId, Map<String, dynamic> cambios) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/$cargaId');

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cambios),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la carga: ${response.statusCode} - ${response.body}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return CargaModel.fromMap(data, data['id']);
  }
}