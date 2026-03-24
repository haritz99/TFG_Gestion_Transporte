import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/models/user_model.dart';

class TransportistaService {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> createTransportista({
    required UserModel userData,
    required String token,
    bool? disponible,
  }) async {
    final uri = Uri.parse('$_baseUrl/trans/');

    final payload = {
      'nombre': userData.nombre,
      'apellido': userData.apellido,
      'email': userData.email,
      'tfn': userData.telefono,
      'rol': userData.rol,
      'permisosCond': userData.permisosCond,
      if (disponible != null) 'disponible': disponible,
    };

    final response = await http.post(
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
}