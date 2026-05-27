import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/models/carga_model.dart';
import '../../auth/providers/token_provider.dart';
import '../../../core/config/api_config.dart';

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
    EstadoCarga? estado,
    String? transportistaId,
    String? conductorNombre,
    String? subVehiculoMatricula,
    String? subRemolqueMatricula,
  }) async {
    final token = await tokenProvider.getRequiredToken();
    final uri = Uri.parse('$_baseUrl/sub/$cargaId');

    final Map<String, dynamic> body = {};
    if (estado != null) body['estado'] = estado.value;
    if (transportistaId != null) body['transportistaId'] = transportistaId;
    if (conductorNombre != null) body['conductorNombre'] = conductorNombre;
    if (subVehiculoMatricula != null) body['subVehiculoMatricula'] = subVehiculoMatricula;
    if (subRemolqueMatricula != null) body['subRemolqueMatricula'] = subRemolqueMatricula;

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CargaModel.fromMap(data, data['id']);
    } else {
      throw Exception('Error al actualizar carga cedida: ${response.statusCode} - ${response.body}');
    }
  }
}
