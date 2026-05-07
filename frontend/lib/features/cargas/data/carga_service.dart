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
}

