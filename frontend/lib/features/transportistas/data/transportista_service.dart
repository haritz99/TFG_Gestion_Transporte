import 'dart:convert';
import 'package:gestion_transporte/core/models/paginated_response.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/constants/app_constants.dart';
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['user'] == null) {
        throw Exception('La API no devolvio el objeto user al crear transportista');
      }
      return data;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['detail'] ?? 'Error al crear transportista');
    }
  }

  Future<PaginatedResponse<UserModel>> fetchTransportistas({required String token, int limit = AppConstants.paginationPageSize, String? lastDocId, bool? soloDisponibles,}) async {
    String url = '${ApiConfig.baseUrl}/trans/?limit=$limit';
    if (lastDocId != null) {
      url += '&last_doc_id=$lastDocId';
    }
    if (soloDisponibles != null) {
      url += '&solodis=$soloDisponibles';
    }
    final uri = Uri.parse(url);

    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Tiempo de espera agotado al obtener transportistas'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];

      final items = itemsData.map((item) {
        final map = item as Map<String, dynamic>;
        final uid = (map['uid'] ?? '').toString();
        return UserModel.fromMap(map, uid);
      }).toList();

      return PaginatedResponse<UserModel>(
        items: items,
        lastDocId: data['last_doc_id']?.toString(),
        hasMore: data['has_more'] ?? false,
      );
    }

    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['detail'] ?? 'Error al obtener transportistas');
  }

  Future<UserModel> updateTransportista({
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
      final Map<String, dynamic> userData = jsonDecode(response.body);
      final user = UserModel.fromMap(userData, userData['uid']);
      return user;
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