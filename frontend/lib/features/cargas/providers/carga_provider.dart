import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../../../../core/models/carga_model.dart';
import '../../../core/models/external_user_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/vehiculo_model.dart';
import '../../../core/pdf/pdf_handler.dart';
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
      (c.estado == EstadoCarga.pendiente || c.estado == EstadoCarga.planificado) &&
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

  void refresh() => notifyListeners();

  String estadoConductor(String conductorId) {
    final cargasDelConductor = _cargas.where((c) =>
    c.transportistaId == conductorId &&
        c.estado != EstadoCarga.cedido &&
        c.estado != EstadoCarga.entregado
    ).toList();

    if (cargasDelConductor.isEmpty) return 'sin_asignar';

    if (cargasDelConductor.any((c) => c.estado == EstadoCarga.enTransito)) {
      return 'en_ruta';
    }
    if (cargasDelConductor.any((c) => c.estado == EstadoCarga.asignado)) {
      return 'asignado';
    }
    if (cargasDelConductor.any((c) => c.estado == EstadoCarga.planificado)) {
      return 'asignacion_parcial';
    }

    return 'sin_asignar';
  }

  String estadoVehiculo(String matricula) {
    final cargasDelVehiculo = _cargas.where((c) =>
    c.vehiculoId == matricula &&
        c.estado != EstadoCarga.cedido &&
        c.estado != EstadoCarga.entregado
    ).toList();

    if (cargasDelVehiculo.isEmpty) return 'disponible';
    if (cargasDelVehiculo.any((c) => c.estado == EstadoCarga.enTransito)) {
      return 'asignado';
    }
    if (cargasDelVehiculo.any((c) => c.estado == EstadoCarga.asignado ||
        c.estado == EstadoCarga.planificado)) {
      return 'asignado';
    }
    return 'disponible';
  }

  String? conductorDeVehiculo(String matricula) {
    final carga = _cargas.firstWhereOrNull((c) =>
    c.vehiculoId == matricula &&
        (c.estado == EstadoCarga.asignado ||
            c.estado == EstadoCarga.enTransito ||
            c.estado == EstadoCarga.planificado)
    );
    return carga?.transportistaNombre;
  }

  bool _hayColisionHoraria({
    required DateTime inicioTarget,
    required DateTime finTarget,
    required Duration bufferTarget,
    required DateTime inicioExistente,
    required DateTime finExistente,
    required Duration bufferExistente,
  }) {
    final finTargetAmpliado = finTarget.add(bufferTarget);
    final finExistenteAmpliado = finExistente.add(bufferExistente);

    return inicioTarget.isBefore(finExistenteAmpliado) && finTargetAmpliado.isAfter(inicioExistente);
  }



  List<UserModel> conductoresDisponibles({
    required List<UserModel> todosLosConductores,
    required DateTime fechaInicioTarget,
    required DateTime fechaFinTarget,
    required int companyDefaultBuffer,
    int? targetBufferOverride,
    String? idCargaActual,
  }) {
    final bufferTarget = Duration(hours: targetBufferOverride ?? companyDefaultBuffer);

    final conductoresOcupados = _cargas.where((carga) {

      if (idCargaActual != null && carga.id == idCargaActual) return false;

      if (carga.transportistaId == null) return false;

      final estadoOcupado = carga.estado == EstadoCarga.planificado || carga.estado == EstadoCarga.asignado || carga.estado == EstadoCarga.enTransito;

      if (!estadoOcupado) return false;

      final bufferExistente = Duration(hours: carga.bufferHours ?? companyDefaultBuffer);
      return _hayColisionHoraria(
        inicioTarget: fechaInicioTarget,
        finTarget: fechaFinTarget,
        bufferTarget: bufferTarget,
        inicioExistente: carga.fechaCarga,
        finExistente: carga.fechaDescarga,
        bufferExistente: bufferExistente,
      );
    }).map((carga) => carga.transportistaId!).toSet();

    return todosLosConductores
        .where((conductor) => !conductoresOcupados.contains(conductor.uid))
        .toList();
  }

  List<VehiculoModel> vehiculosDisponibles({
    required List<VehiculoModel> todosLosVehiculos,
    required DateTime fechaInicioTarget,
    required DateTime fechaFinTarget,
    required int companyDefaultBuffer,
    int? targetBufferOverride,
    String? idCargaActual,
  }) {
    final bufferTarget = Duration(hours: targetBufferOverride ?? companyDefaultBuffer);

    final vehiculosOcupados = _cargas.where((carga) {
      if (idCargaActual != null && carga.id == idCargaActual) return false;

      if (carga.vehiculoId == null) return false;

      final estadoOcupado = carga.estado == EstadoCarga.planificado ||
          carga.estado == EstadoCarga.asignado ||
          carga.estado == EstadoCarga.enTransito;

      if (!estadoOcupado) return false;

      final bufferExistente = Duration(hours: carga.bufferHours ?? companyDefaultBuffer);
      return _hayColisionHoraria(
        inicioTarget: fechaInicioTarget,
        finTarget: fechaFinTarget,
        bufferTarget: bufferTarget,
        inicioExistente: carga.fechaCarga,
        finExistente: carga.fechaDescarga,
        bufferExistente: bufferExistente,
      );
    }).map((carga) => carga.vehiculoId!).toSet();

    return todosLosVehiculos.where((vehiculo) => !vehiculosOcupados.contains(vehiculo.matricula)).toList();
  }

  Future<void> actualizarBufferHours(String cargaId, int nuevasHoras) async {
    try {
      await _service.updateBufferHours(cargaId, nuevasHoras);

      final index = _cargas.indexWhere((c) => c.id == cargaId);
      if (index != -1) {
        _cargas[index] = _cargas[index].copyWith(bufferHours: nuevasHoras);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "No se pudo actualizar el margen de tiempo: $e";
      notifyListeners();
    }
  }

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

  Future<void> fetchCargasDelMes(DateTime start, DateTime end, {bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    if (!forceRefresh && _cargas.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }
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

  Future<void> updateCargaSubcontratado({
    required String cargaId,
    EstadoCarga? estado,
    String? transportistaId,
    String? conductorNombre,
    String? subVehiculoMatricula,
    String? subRemolqueMatricula,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final dto = UpdateCargaSubcontratadoDto(
      estado: estado,
      conductorNombre: conductorNombre,
      subVehiculoMatricula: subVehiculoMatricula,
      subRemolqueMatricula: subRemolqueMatricula,
    );

    try {
      final updatedCarga = await _service.updateCargaSubcontratado(
        cargaId: cargaId,
        dto: dto,
      );

      final idx = _cargasCedidas.indexWhere((c) => c.id == cargaId);
      if (idx != -1) {
        _cargasCedidas[idx] = updatedCarga;
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CargaModel> cargasCedidasFiltradas(String estado) {
    if (estado == 'Todos') return _cargasCedidas;
    return _cargasCedidas
        .where((c) => c.estado.name == estado.toLowerCase())
        .toList();
  }

  Future<void> fetchCargasIniciales({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final realStart = start.subtract(const Duration(days: 7));

    final endRaw = start.add(const Duration(days: 35));
    final end = DateTime(endRaw.year, endRaw.month, endRaw.day, 23, 59, 59);

    await fetchCargasDelMes(realStart, end, forceRefresh: forceRefresh);
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
      print("Error al obtener tipos de carga: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TipoCargaModel> crearTipoCarga(TipoCargaModel tipo) async {
      final creado = await _service.createTipoCarga(tipo);
      _tiposCarga.add(creado);
      notifyListeners();
      return creado;
  }

  void actualizarFechasCarga(String cargaId, DateTime start, DateTime end) {
    final idx = _cargas.indexWhere((c) => c.id == cargaId);
    if (idx != -1) {
      // No permitir mover cargas que ya están cedidas
      if (_cargas[idx].estado == EstadoCarga.cedido) return;

      _cargas[idx] = _cargas[idx].copyWith(
        fechaCarga: start,
        fechaDescarga: end,
      );
      _cargasModificadas.add(cargaId);
      notifyListeners();
    }
  }

  void planificarCarga(String cargaId, DateTime start, DateTime end) {
    final idx = _cargas.indexWhere((c) => c.id == cargaId);
    if (idx != -1) {
      // No permitir planificar/mover si la carga está cedida
      if (_cargas[idx].estado == EstadoCarga.cedido) return;

      _cargas[idx] = _cargas[idx].copyWith(
        estado: EstadoCarga.planificado,
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
          : EstadoCarga.planificado;

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
          : EstadoCarga.planificado;

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
          estado: EstadoCarga.planificado,
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
      _errorMessage = "Ha ocurrido un error al guardar los cambios: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarRecogido(String cargaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateEstado(cargaId, EstadoCarga.enTransito);
      final idx = _cargas.indexWhere((c) => c.id == cargaId);
      if (idx != -1) _cargas[idx] = updated;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marcarEntregado(String cargaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateEstado(cargaId, EstadoCarga.entregado);
      final idx = _cargas.indexWhere((c) => c.id == cargaId);
      if (idx != -1) _cargas[idx] = updated;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
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

  Future<void> generarCartaDePorte(String cargaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String urlStorage = await _service.generarCartaDePorte(cargaId);
      await PdfHandler.instance.open(
          urlStorage,
          'Carta_Porte_$cargaId.pdf'
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
