import 'package:flutter/cupertino.dart';

import '../../../core/models/vehiculo_model.dart';
import '../../../core/models/paginated_response.dart';
import '../../../core/token_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/auth_service.dart';
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

  VehiculoProvider({
    required AuthService authService,
    VehiculoService? service,
  })  : _service = service ?? VehiculoService(),
        _tokenProvider = AuthTokenProvider(authService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int? get totalVehiculos => _totalVehiculos;
  int? get asignados => _asignados;
  int? get disponibles => _disponibles;
  int? get enMantenimiento => _enMantenimiento;

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
      await fetchKpis();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}