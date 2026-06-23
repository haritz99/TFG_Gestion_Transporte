import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/features/auth/providers/token_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/paginated_response.dart';
import '../data/transportista_service.dart';

class TransportistaProvider extends ChangeNotifier {
  final TransportistaService _service;
  final AuthTokenProvider _tokenProvider;

  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> _transportistas = [];
  bool _hasMore = true;
  bool _isLoadingPage = false;
  String? _lastDocId;

  DateTime? _lastFetchTime;
  final Duration _ttl = const Duration(minutes: 5);

  TransportistaProvider({
    required AuthTokenProvider tokenProvider,
    TransportistaService? service,
  })  : _service = service ?? TransportistaService(),
        _tokenProvider = tokenProvider;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get transportistas => _transportistas;
  bool get hasMore => _hasMore;
  bool get isLoadingPage => _isLoadingPage;

  bool get shouldReload {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _ttl;
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
    if (!shouldReload && _transportistas.isNotEmpty) return;
    _transportistas = [];
    _lastDocId = null;
    _hasMore = true;
    notifyListeners();
    await loadNextPage(limit: limit, reset: true);
    _lastFetchTime = DateTime.now();
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
        //_lastFetchTime = DateTime.now();
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
}