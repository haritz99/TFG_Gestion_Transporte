import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/models/vehiculo_model.dart';

class VehiculoService {
  final http.Client _client;
  VehiculoService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<VehiculoModel>> fetchVehiculos({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/vehi/');

    final response = await _client.get(
      uri,
      headers: {
      'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Tiempo de espera agotado al obtener vehiculos'),
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/vehi/assign');

    final response = await _client.patch(
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

  Future<VehiculoModel> insertaVehiculo({
    required String token,
    required VehiculoModel vehiculoData,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/vehi/');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(vehiculoData.toMap()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String id = (data['matricula'] ?? '').toString();
      return VehiculoModel.fromMap(data, id);
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Error al insertar vehículo');
    }
  }

  Future<void> eliminaVehiculo({
    required String token,
    required String matricula,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/vehi/$matricula');

    final response = await _client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Error al eliminar vehiculo');
    }
  }
}
