import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/token_provider.dart';
import '../data/invite_service.dart';

class InviteProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isCreated = false;
  String? tempPassword;
  String? resetLink;
  final InviteService _service;
  Map<String, dynamic>? _createResponse;

  InviteProvider({
    required AuthTokenProvider tokenProvider,
    InviteService? service,
  }) : _service = service ?? InviteService(tokenProvider);

  Map<String, dynamic>? get createResponse => _createResponse;


  Future<void> createUser(String email, String rol) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = rol == 'cliente'
          ? await _service.createCliente(email)
          : await _service.createSubcontratado(email);

      tempPassword = response.tempPassword;
      resetLink = response.resetLink;
      _createResponse = {'temp_password': tempPassword, 'password_reset_link': resetLink};
      isCreated = true;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendInviteEmail(String email, String rol) async {
    if (_createResponse == null) return false;

    final String? tempPassword = _createResponse!['temp_password'] as String?;
    final String? resetLink = _createResponse!['password_reset_link'] as String?;
    final roleName = rol == 'cliente' ? 'Cargador' : 'Subcontratado';
    final body = StringBuffer()
      ..writeln('Hola,')
      ..writeln()
      ..writeln('Has sido invitado a la plataforma como $roleName.')
      ..writeln();

    if (tempPassword != null && tempPassword.isNotEmpty) {
      body
        ..writeln('Tu contraseña temporal es: $tempPassword')
        ..writeln();
    }

    if (resetLink != null && resetLink.isNotEmpty) {
      body
        ..writeln(
          'Por favor, entra en el siguiente enlace para completar tu registro y cambiar tu contraseña:',
        )
        ..writeln(resetLink)
        ..writeln();
    }

    body.write('Un saludo.');

    final mailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Invitación a la plataforma de transporte',
        'body': body.toString(),
      },
    );

    try {
      final opened = await launchUrl(mailUri, mode: LaunchMode.externalApplication);
      return opened;
    } catch (e) {
      return false;
    }
  }
}