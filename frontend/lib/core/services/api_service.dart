import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  Future<Map<String, dynamic>> detectIntent(String text, String idToken) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/intent');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al detectar intención: ${response.statusCode}');
    }
  }
}
