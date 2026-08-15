import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/app_constants.dart';
import '../../core/models/vehiculo_model.dart';
import '../../core/models/paginated_response.dart';

class VehiculoService {
  final http.Client _client;
  VehiculoService({http.Client? client}) : _client = client ?? http.Client();

  Future<PaginatedResponse<VehiculoModel>> fetchVehiculos({required String token, int limit = AppConstants.paginationPageSize, String? lastDocId,}) async {

    String url = '${ApiConfig.baseUrl}/vehi/?limit=$limit';
    if (lastDocId != null) {
      url += '&last_doc_id=$lastDocId';
    }
    final uri = Uri.parse(url);

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
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];
      
      final items = itemsData.map((item) {
        final map = item as Map<String, dynamic>;
        final id = (map['matricula'] ?? '').toString();
        return VehiculoModel.fromMap(map, id);
      }).toList();

      return PaginatedResponse<VehiculoModel>(
        items: items,
        lastDocId: data['last_doc_id']?.toString(),
        hasMore: data['has_more'] ?? false,
      );
    }

    final errorData = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(errorData['detail'] ?? 'Error al obtener vehiculos');
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

  Future<VehiculoModel> actualizaVehiculo({
    required String token,
    required String matricula,
    required VehiculoModel vehiculoData,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/vehi/$matricula');

    final response = await _client.put(
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
      throw Exception(errorData['detail'] ?? 'Error al actualizar vehículo');
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
