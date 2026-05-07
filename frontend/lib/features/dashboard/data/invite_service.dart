import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/models/external_user_model.dart';
import '../../auth/providers/token_provider.dart';

class InviteResponse {
  final String? tempPassword;
  final String? resetLink;

  InviteResponse({this.tempPassword, this.resetLink});
}

class InviteService {
  final http.Client _client;
  final AuthTokenProvider _tokenProvider;

  InviteService(this._tokenProvider, {http.Client? client}) : _client = client ?? http.Client();

  Future<InviteResponse> createExternalUser({required String email, required String rol}) async {
		final token = await _tokenProvider.getRequiredToken();
		final uri = Uri.parse('${ApiConfig.baseUrl}/ext/?rol=$rol');

		final payload = {
			'email': email,
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
			final Map<String, dynamic> data = jsonDecode(response.body);
			return InviteResponse(
			tempPassword: data['temp_password']?.toString(),
			resetLink: data['password_reset_link']?.toString(),
			);
		}

		try {
			final errorData = jsonDecode(response.body) as Map<String, dynamic>;
			throw Exception(errorData['detail'] ?? 'Error al invitar usuario');
		} on FormatException {
			throw Exception('Error al invitar usuario: ${response.statusCode}');
		}
	}

	Future<InviteResponse> createCliente(String email) async =>
		createExternalUser(email: email, rol: 'cliente');

	Future<InviteResponse> createSubcontratado(String email) async =>
		createExternalUser(email: email, rol: 'subcontratado');

	Future<List<ExternalUserModel>> fetchGuests() async {
		final token = await _tokenProvider.getRequiredToken();
		final uri = Uri.parse('${ApiConfig.baseUrl}/ext/');

		final response = await _client.get(
			uri,
			headers: {
				'Content-Type': 'application/json',
				'Authorization': 'Bearer $token',
			},
		);
		if (response.statusCode == 200 || response.statusCode == 201) {
			final List<dynamic> data = jsonDecode(response.body);
			return data.map((item) {
				final map = item as Map<String, dynamic>;
				return ExternalUserModel.fromMap(map, map['uid']?.toString() ?? '');
			}).toList();
		} else {
			throw Exception('Error al obtener invitados: ${response.statusCode}');
		}
	}
}
