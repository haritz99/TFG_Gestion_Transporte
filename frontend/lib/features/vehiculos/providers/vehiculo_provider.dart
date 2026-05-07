import 'package:flutter/cupertino.dart';

import '../../../core/models/vehiculo_model.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/token_provider.dart';
import '../data/vehiculo_service.dart';

class VehiculoProvider extends ChangeNotifier {
  final VehiculoService _service;
  final AuthTokenProvider _tokenProvider;

  bool _isLoading = false;
  String? _errorMessage;

  int? _totalVehiculos;
  int? _asignados;
  int? _disponibles;
  int? _enMantenimiento;

  List<VehiculoModel> _vehiculos = [];
  bool _hasMore = true;
  bool _isLoadingPage = false;
  String? _lastDocId;

  DateTime? _lastFetchTime;
  final Duration _ttl = const Duration(minutes: 5);

  VehiculoProvider({
    required AuthTokenProvider tokenProvider,
    VehiculoService? service,
  })  : _service = service ?? VehiculoService(),
        _tokenProvider = tokenProvider;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get totalVehiculos => _totalVehiculos;
  int? get asignados => _asignados;
  int? get disponibles => _disponibles;
  int? get enMantenimiento => _enMantenimiento;

  List<VehiculoModel> get vehiculos => _vehiculos;
  bool get hasMore => _hasMore;
  bool get isLoadingPage => _isLoadingPage;

  bool get shouldReload {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _ttl;
  }

  Future<PaginatedResponse<VehiculoModel>> fetchVehiculosPage({int limit = AppConstants.paginationPageSize, String? lastDocId,}) async {
    try {
      final token = await _tokenProvider.getRequiredToken();
      return await _service.fetchVehiculos(token: token, limit: limit, lastDocId: lastDocId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchKpis() async {
    try {
      final token = await _tokenProvider.getRequiredToken();
      final counts = await _service.fetchVehiculosCount(token: token);
      _totalVehiculos = counts['totalVehiculos'];
      _asignados = counts['asignados'];
      _disponibles = counts['disponibles'];
      _enMantenimiento = counts['enMantenimiento'];
      notifyListeners();
    } catch (e) {
      _errorMessage = "Error al obtener KPIs: $e";
      notifyListeners();
    }
  }

  Future<void> loadInitialVehiculos({
    int limit = AppConstants.paginationPageSize,
  }) async {
    if (!shouldReload && _vehiculos.isNotEmpty) return;
    _vehiculos = [];
    _lastDocId = null;
    _hasMore = true;
    notifyListeners();
    await fetchKpis();
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
      final page = await fetchVehiculosPage(limit: limit, lastDocId: reset ? null : _lastDocId);

      if (reset) {
        _vehiculos = [...page.items];
      } else {
        _vehiculos = [..._vehiculos, ...page.items];
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

  void _upsertVehiculo(VehiculoModel item) {
    final index = _vehiculos.indexWhere((v) => v.matricula == item.matricula);
    if (index == -1) {
      _vehiculos = [item, ..._vehiculos];
    } else {
      _vehiculos[index] = item;
      _vehiculos = [..._vehiculos];
    }
    notifyListeners();
  }

  Future<void> asignaVehiculo(String matricula, String transportistaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      await _service.asignaVehiculo(
        token: token,
        matricula: matricula,
        transportistaId: transportistaId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VehiculoModel?> insertaVehiculo(VehiculoModel vehiculoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      final model = await _service.insertaVehiculo(
        token: token,
        vehiculoData: vehiculoData,
      );
      await fetchKpis();
      _upsertVehiculo(model);
      return model;
    } catch (e) {
      _errorMessage = "Error al insertar vehiculo";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VehiculoModel?> saveVehiculo(VehiculoModel vehiculo, {required bool isNew}) async {
    if (isNew) {
      return await insertaVehiculo(vehiculo);
    } else {
      return await actualizaVehiculo(vehiculo.matricula, vehiculo);
    }
  }

  Future<VehiculoModel?> actualizaVehiculo(String matricula, VehiculoModel vehiculo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      final updated = await _service.actualizaVehiculo(
        token: token,
        matricula: matricula,
        vehiculoData: vehiculo,
      );
      await fetchKpis();
      _upsertVehiculo(updated);
      return updated;
    } catch (e) {
      _errorMessage = "Error al actualizar vehiculo";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> eliminarVehiculo(String matricula) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      await _service.eliminaVehiculo(
        token: token,
        matricula: matricula,
      );
      _vehiculos = _vehiculos.where((v) => v.matricula != matricula).toList(growable: false);
      await fetchKpis();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}