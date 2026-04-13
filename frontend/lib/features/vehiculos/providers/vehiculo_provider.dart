import 'package:flutter/cupertino.dart';

import '../../../core/models/vehiculo_model.dart';
import '../../../core/token_provider.dart';
import '../../auth/auth_service.dart';
import '../data/vehiculo_service.dart';

class VehiculoProvider extends ChangeNotifier {
  final VehiculoService _service;
  final AuthTokenProvider _tokenProvider;

  bool _isLoading = false;
  String? _errorMessage;

  VehiculoProvider({
    required AuthService authService,
    VehiculoService? service,
  })  : _service = service ?? VehiculoService(),
        _tokenProvider = AuthTokenProvider(authService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<VehiculoModel>> fetchVehiculos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      return await _service.fetchVehiculos(token: token);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return [];
    } finally {
      _isLoading = false;
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

  Future<void> insertaVehiculo(VehiculoModel vehiculoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      await _service.insertaVehiculo(
        token: token,
        vehiculoData: vehiculoData,
      );
    } catch (e) {
      _errorMessage = "Error al insertar vehiculo";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveVehiculo(VehiculoModel vehiculo, {required bool isNew}) async {
    if (isNew) {
      await insertaVehiculo(vehiculo);
    } else {
      await actualizaVehiculo(vehiculo.matricula, vehiculo);
    }
  }

  Future<void> actualizaVehiculo(String matricula, VehiculoModel vehiculo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      await _service.actualizaVehiculo(
        token: token,
        matricula: matricula,
        vehiculoData: vehiculo,
      );
    } catch (e) {
      _errorMessage = "Error al actualizar vehiculo";
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
      await fetchVehiculos();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}