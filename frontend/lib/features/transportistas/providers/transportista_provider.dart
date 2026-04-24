import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/core/token_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../data/transportista_service.dart';

class TransportistaProvider extends ChangeNotifier {
  final TransportistaService _service;
  final AuthTokenProvider _tokenProvider;

  bool _isLoading = false;
  String? _errorMessage;

  int? _totalEquipo;
  int? _enRuta;
  int? _sinAsignar;
  int? _asignacionParcial;
  int? _inactivos;

  Map<String, dynamic>? _createResponse;
  String? _lastCreatedEmail;
  List<UserModel> _transportistas = [];
  List<UserModel> _transportistasDisponibles = [];
  bool _hasMore = true;
  bool _isLoadingPage = false;
  String? _lastDocId;

  TransportistaProvider({
    required AuthTokenProvider tokenProvider,
    TransportistaService? service,
  })  : _service = service ?? TransportistaService(),
        _tokenProvider = tokenProvider;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get createResponse => _createResponse;
  List<UserModel> get transportistas => _transportistas;
  List<UserModel> get transportistasDisponibles => _transportistasDisponibles;
  bool get hasMore => _hasMore;
  bool get isLoadingPage => _isLoadingPage;

  int? get totalEquipo => _totalEquipo;
  int? get enRuta => _enRuta;
  int? get sinAsignar => _sinAsignar;
  int? get asignacionParcial => _asignacionParcial;
  int? get inactivos => _inactivos;

  List<DropdownMenuEntry<String>> get conductoresDropdown {
    return _transportistasDisponibles
        .map((t) => DropdownMenuEntry<String>(
            value: t.uid,
            label: _buildNombreCompleto(t),
          ),
        )
        .toList(growable: false);
  }

  String _buildNombreCompleto(UserModel t) {
    final nombre = t.nombre.trim();
    final apellido = t.apellido.trim();
    final fullName = '$nombre $apellido'.trim();
    return fullName;
  }

  Future<PaginatedResponse<UserModel>> fetchEquipoPage({
    int limit = AppConstants.paginationPageSize,
    String? lastDocId,
  }) async {
    try {
      final token = await _tokenProvider.getRequiredToken();
      return await _service.fetchTransportistas(
        token: token,
        limit: limit,
        lastDocId: lastDocId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadInitialEquipo({
    int limit = AppConstants.paginationPageSize,
  }) async {
    _transportistas = [];
    _lastDocId = null;
    _hasMore = true;
    notifyListeners();
    await loadNextPage(limit: limit, reset: true);
  }

  Future<void> loadNextPage({
    int limit = AppConstants.paginationPageSize,
    bool reset = false,
  }) async {
    if (_isLoadingPage) return;
    if (!reset && !_hasMore) return;

    _isLoadingPage = true;
    notifyListeners();

    try {
      final page = await fetchEquipoPage(limit: limit, lastDocId: reset ? null : _lastDocId,);

      if (reset) {
        _transportistas = [...page.items];
      } else {
        _transportistas = [..._transportistas, ...page.items];
      }

      _lastDocId = page.lastDocId;
      _hasMore = page.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingPage = false;
      notifyListeners();
    }
  }

  void _upsertTransportista(UserModel item) {
    final index = _transportistas.indexWhere((t) => t.uid == item.uid);
    if (index == -1) {
      _transportistas = [item, ..._transportistas];
    } else {
      _transportistas[index] = item;
      _transportistas = [..._transportistas];
    }
  }

  Future<void> fetchEquipoKpis() async {
    try {
      final token = await _tokenProvider.getRequiredToken();
      final counts = await _service.fetchEquipoCount(token: token);
      _totalEquipo = counts['totalEquipo'];
      _enRuta = counts['en_ruta'];
      _sinAsignar = counts['sin_asignar'];
      _asignacionParcial = counts['asignacion_parcial'];
      _inactivos = counts['inactivos'];
      notifyListeners();
    } catch (e) {
      _errorMessage = "Error al obtener KPIs: $e";
      notifyListeners();
    }
  }

  Future<List<UserModel>> fetchTransportistasDisponibles() async {
    // Solo devuelve los transportistas sin asignar a un vehículo
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      final response = await _service.fetchTransportistas(
        token: token,
        soloDisponibles: true,
        limit: 1000,
      );
      _transportistasDisponibles = response.items;
      return _transportistasDisponibles;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DropdownMenuEntry<String>> getConductoresDropdown() {
    return conductoresDropdown;
  }

  Future<UserModel?> createTransportista({
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
      final token = await _tokenProvider.getRequiredToken();

      final userData = UserModel.fromMap({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'rol': rol,
        'permisosCond': permisosCond,
        'estado': 'Sin Asignar'
      }, '');

      final response = await _service.createTransportista(
        userData: userData,
        token: token,
      );

      final userMap = response['user'];
      _createResponse = {
        'temp_password': response['temp_password'],
        'password_reset_link': response['password_reset_link'],
      };
      _lastCreatedEmail = email;
      final created = UserModel.fromMap(userMap, userMap['uid']);
      _upsertTransportista(created);
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel?> updateTransportista({
    required String uid,
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required List<String> rol,
    required List<String> permisosCond,
    required String estado,
    String? vehiculoId,
    String? cargaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      final index = _transportistas.indexWhere((t) => t.uid == uid);
      final companyId = index != -1 ? _transportistas[index].companyId : '';

      final userData = UserModel(
        uid: uid,
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        rol: rol,
        permisosCond: permisosCond,
        companyId: companyId,
        estado: estado,
        vehiculoId: vehiculoId,
        cargaId: cargaId,
      );

      final updated = await _service.updateTransportista(
        uid: uid,
        userData: userData,
        token: token,
      );

      _upsertTransportista(updated);
      return updated;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransportista(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();

      await _service.deleteTransportista(uid: uid, token: token);
      _transportistas = _transportistas.where((t) => t.uid != uid).toList(growable: false);
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