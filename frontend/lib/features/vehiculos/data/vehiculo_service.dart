import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/models/vehiculo_model.dart';

class VehiculoService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  Future<List<VehiculoModel>> fetchVehiculos({required String token}) async {
    final uri = Uri.parse('$_baseUrl/vehi/');

    final response = await http.get(
      uri,
      headers: {
      'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) {
      final map = item as Map<String, dynamic>;
      final id = (map['matricula'] ?? '').toString();
      return VehiculoModel.fromMap(map, id);
      }).toList();
    }

    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['detail'] ?? 'Error al obtener vehiculos');
  }

  Future<void> asignaVehiculo({
    required String token,
    required String matricula,
    required String transportistaId,
    }) async {
    final uri = Uri.parse('$_baseUrl/vehi/assign');

    final response = await http.patch(
      uri,
      headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'matr': matricula,
        'uid': transportistaId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Error al asignar vehiculo');
    }
  }
}

