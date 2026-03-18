import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // localhost desde emulador Android

  Future<Map<String, dynamic>> detectIntent(String text, String idToken) async {
    final uri = Uri.parse('$_baseUrl/intent');
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
