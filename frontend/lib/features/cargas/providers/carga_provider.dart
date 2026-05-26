import 'package:flutter/foundation.dart';
import '../../../../core/models/carga_model.dart';
import '../../auth/providers/token_provider.dart';
import '../data/carga_service.dart';

class CargaProvider extends ChangeNotifier {
  final CargaService _service;

  List<CargaModel> _cargas = [];
  List<CargaModel> get cargas => _cargas;

  List<CargaModel> get cargasSemanaAnterior {
    final now = DateTime.now();
    final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
    final inicioSemanaSinHora = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);

    return _cargas.where((c) =>
      c.estado == EstadoCarga.pendiente &&
      c.fechaDescarga.isBefore(inicioSemanaSinHora)
    ).toList();
  }

  List<TipoCargaModel> _tiposCarga = [];

  final Set<String> _cargasModificadas = {};
  bool get hayCambiosSinGuardar => _cargasModificadas.isNotEmpty;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  List<TipoCargaModel> get tiposCarga => _tiposCarga;

  List<CargaModel> _cargasCedidas = [];
  List<CargaModel> get cargasCedidas => _cargasCedidas;

  Future<void> fetchCargasCedidas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cargasCedidas = await _service.getCargasCedidas();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CargaProvider({
    required AuthTokenProvider tokenProvider,
    CargaService? service,
  })  : _service = service ?? CargaService(tokenProvider);

  Future<void> fetchCargasDelMes(DateTime start, DateTime end) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cargas = await _service.getCargasDelMes(start, end);
      _cargasModificadas.clear();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCargasIniciales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    await fetchCargasDelMes(start, end);
  }

  Future<void> fetchTiposCarga(String cargadorId) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tiposCarga = await _service.fetchTiposCarga(cargadorId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void actualizarFechasCarga(String cargaId, DateTime start, DateTime end) {
    final idx = _cargas.indexWhere((c) => c.id == cargaId);
    if (idx != -1) {
      _cargas[idx] = _cargas[idx].copyWith(
        fechaCarga: start,
        fechaDescarga: end,
      );
      _cargasModificadas.add(cargaId);
      notifyListeners();
    }
  }

  void asignarVehiculo(String cargaId, String? matricula) {
    final idx = _cargas.indexWhere((c) => c.id == cargaId);
    if (idx != -1) {
      final old = _cargas[idx];
      final newEstado = (matricula != null && old.transportistaId != null)
          ? EstadoCarga.asignado
          : EstadoCarga.pendiente;

      _cargas[idx] = old.copyWith(
        estado: newEstado,
        vehiculoId: matricula,
        clearVehiculoId: matricula == null,
      );
      _cargasModificadas.add(cargaId);
      notifyListeners();
    }
  }

  void asignarConductor(String cargaId, String? conductorId, String? nombre) {
    final idx = _cargas.indexWhere((c) => c.id == cargaId);
    if (idx != -1) {
      final old = _cargas[idx];
      final newEstado = (conductorId != null && old.vehiculoId != null)
          ? EstadoCarga.asignado
          : EstadoCarga.pendiente;

      _cargas[idx] = old.copyWith(
        estado: newEstado,
        transportistaId: conductorId,
        clearTransportistaId: conductorId == null,
        transportistaNombre: nombre,
        clearTransportistaNombre: nombre == null,
      );
      _cargasModificadas.add(cargaId);
      notifyListeners();
    }
  }

  void traerCargasEstaSemana() {
    final now = DateTime.now();

    for (final carga in cargasSemanaAnterior) {
      final idx = _cargas.indexWhere((c) => c.id == carga.id);
      if (idx != -1) {
        final duracion = carga.fechaDescarga.difference(carga.fechaCarga);
        final nuevaFechaCarga = DateTime(now.year, now.month, now.day, now.hour);
        final nuevaFechaDescarga = nuevaFechaCarga.add(duracion);

        _cargas[idx] = carga.copyWith(
          fechaCarga: nuevaFechaCarga,
          fechaDescarga: nuevaFechaDescarga,
        );
        _cargasModificadas.add(carga.id!);
      }
    }
    notifyListeners();
  }

  Future<void> guardarCambios() async {
    if (_cargasModificadas.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cargasAGuardar = _cargas.where((c) => _cargasModificadas.contains(c.id)).toList();
      await _service.updateCargas(cargasAGuardar);
      _cargasModificadas.clear();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cederCargaASubcontratado({required String cargaId, required String subcontratadoId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedCarga = await _service.cederCarga(cargaId: cargaId, subcontratadoUid: subcontratadoId);
      final idx = _cargas.indexWhere((c) => c.id == cargaId);
      if (idx != -1) {
        _cargas[idx] = updatedCarga;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
