import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/auth_service.dart';
import '../data/transportista_service.dart';

class TransportistaProvider extends ChangeNotifier {
  final TransportistaService _service = TransportistaService();
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _createResponse;
  String? _lastCreatedEmail;
  List<UserModel> _transportistas = [];

  TransportistaProvider({
    required AuthService authService,
  })  : _authService = authService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get createResponse => _createResponse;
  List<UserModel> get transportistas => _transportistas;


  Future<List<UserModel>> fetchTransportistas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: false) ??
          await _authService.getIdToken(forceRefresh: true);

      if (token == null) {
        throw Exception("No se pudo obtener un token valido. Inicia sesion de nuevo.");
      }

      _transportistas = await _service.fetchTransportistas(token: token);
      return _transportistas;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTransportista({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    List<String> rol = const ['transportista'],
    required List<String> permisosCond,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _createResponse = null;
    notifyListeners();

    try {
      final token = await _authService.getIdToken(forceRefresh: false) ??
          await _authService.getIdToken(forceRefresh: true);

      if (token == null) {
        throw Exception("No se pudo obtener un token valido. Inicia sesion de nuevo.");
      }

      final userData = UserModel.fromMap({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'rol': rol,
        'permisosCond': permisosCond,
      }, '');

      final response = await _service.createTransportista(
        userData: userData,
        token: token,
      );

      _createResponse = response;
      _lastCreatedEmail = email;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCreateResponse() {
    _createResponse = null;
    _lastCreatedEmail = null;
    notifyListeners();
  }

  Future<bool> sendCredentialsEmail() async {
    if (_createResponse == null || _lastCreatedEmail == null) {
      _errorMessage = 'No hay credenciales para enviar.';
      notifyListeners();
      return false;
    }

    final tempPassword = _createResponse!['temp_password'] as String?;
    final resetLink = _createResponse!['password_reset_link'] as String?;

    if (tempPassword == null || resetLink == null) {
      _errorMessage = 'La respuesta de la API no incluye las credenciales necesarias.';
      notifyListeners();
      return false;
    }

    final mailUri = Uri(
      scheme: 'mailto',
      path: _lastCreatedEmail,
      queryParameters: {
        'subject': 'Credenciales de acceso',
        'body':
            'Hola,\n\n'
            'Tu cuenta de transportista ha sido creada.\n\n'
            'Contrasena temporal: $tempPassword\n\n'
            'Para establecer tu contrasena definitiva, abre este enlace:\n$resetLink\n\n'
            'Un saludo.',
      },
    );

    final opened = await launchUrl(mailUri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _errorMessage = 'No se pudo abrir una app de correo en este dispositivo.';
      notifyListeners();
      return false;
    }

    return true;
  }
}