import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/models/user_model.dart';

class TransportistaService {
  final http.Client _client;
  TransportistaService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> createTransportista({
    required UserModel userData,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/trans/');

    final payload = {
      'nombre': userData.nombre,
      'apellido': userData.apellido,
      'email': userData.email,
      'telefono': userData.telefono,
      'rol': userData.rol,
      'permisosCond': userData.permisosCond,
    };

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Error al crear transportista');
    }
  }

  Future<List<UserModel>> fetchTransportistas({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/trans/');

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        final uid = (map['uid'] ?? '').toString();
        return UserModel.fromMap(map, uid);
      }).toList();
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Error al obtener transportistas');
    }
  }

  Future<Map<String, dynamic>> updateTransportista({
    required String uid,
    required UserModel userData,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/trans/$uid');

    final payload = {
      'nombre': userData.nombre,
      'apellido': userData.apellido,
      'email': userData.email,
      'telefono': userData.telefono,
      'rol': userData.rol,
      'permisosCond': userData.permisosCond,
      'vehiculoId': userData.vehiculoId,
    };

    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['detail'] ?? 'Error al actualizar transportista');
  }

  Future<Map<String, dynamic>> deleteTransportista({
    required String uid,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/trans/$uid');

    final response = await _client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['detail'] ?? 'Error al eliminar transportista');
  }

}