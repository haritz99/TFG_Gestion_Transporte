import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/external_user_model.dart';
import '../../auth/providers/token_provider.dart';
import '../data/invite_service.dart';

class InviteProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isCreated = false;
  List<ExternalUserModel> _guests = [];
  String? tempPassword;
  String? resetLink;
  final InviteService _service;
  Map<String, dynamic>? _createResponse;

  InviteProvider({
    required AuthTokenProvider tokenProvider,
    InviteService? service,
  }) : _service = service ?? InviteService(tokenProvider);

  Map<String, dynamic>? get createResponse => _createResponse;
  List<ExternalUserModel> get guests => _guests;

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
    if (_createResponse == null) {
      try {
        final link = await _service.getResetLink(email);
        _createResponse = {'password_reset_link': link};
      } catch (e) {
        debugPrint('Error obteniendo reset link: $e');
      }
    }

    final String? tempPassword = _createResponse?['temp_password'] as String?;
    final String? resetLink = _createResponse?['password_reset_link'] as String?;
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

  Future<void> getGuests() async {
    isLoading = true;
    notifyListeners();
    try {
      if (_guests.isNotEmpty) return;
      _guests = await _service.fetchGuests();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGuest(String uid) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.deleteGuest(uid);
      _guests.removeWhere((guest) => guest.uid == uid);
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}