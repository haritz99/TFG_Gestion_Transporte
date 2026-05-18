import 'package:flutter/material.dart';
import '../../../core/models/carga_model.dart';
import '../../../core/models/external_user_model.dart';
import '../../../core/models/pedido_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/vehiculo_model.dart';
import '../../auth/providers/token_provider.dart';
import '../data/pedido_service.dart';

class CargasSeleccionadas {
  // tipo de carga, cantidad de cargas y asignaciones opcionales
  final TipoCargaModel tipo;
  final int cantidad;
  final List<AsignacionCarga> asignaciones;

  CargasSeleccionadas({
    required this.tipo,
    required this.cantidad,
  }) : asignaciones = List.generate(cantidad, (_) => AsignacionCarga());

  double get subtotal => tipo.precio * cantidad;
}

class AsignacionCarga {
  UserModel? conductor;
  VehiculoModel? vehiculo;
  DateTime? fechaLimite;

  AsignacionCarga({this.conductor, this.vehiculo, this.fechaLimite});
}


class PedidoProvider extends ChangeNotifier {
  final PedidoService _service;

  List<PedidoModel> _pedidos = [];
  List<PedidoModel> get pedidos => _pedidos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CargasSeleccionadas? _cargasDelPedido;
  CargasSeleccionadas? get cargasDelPedido => _cargasDelPedido;

  double get precioTotal => _cargasDelPedido?.subtotal ?? 0.0;

  Map<String, dynamic> _datosTemporalPedido = {};
  Map<String, dynamic> get datosTemporalPedido => _datosTemporalPedido;

  PedidoProvider({
    required AuthTokenProvider tokenProvider,
    PedidoService? service,
  }) : _service = service ?? PedidoService(tokenProvider);

  void actualizarDatosTemporales({
    String? descripcion,
    ExternalUserModel? cliente,
    DateTime? fechaCarga,
    DateTime? fechaDescarga,
  }) {
    if (descripcion != null) _datosTemporalPedido['descripcion'] = descripcion;
    if (cliente != null) _datosTemporalPedido['cliente'] = cliente;
    if (fechaCarga != null) _datosTemporalPedido['fechaCarga'] = fechaCarga;
    if (fechaDescarga != null) _datosTemporalPedido['fechaDescarga'] = fechaDescarga;
    notifyListeners();
  }

  void anadirCarga(TipoCargaModel tipo, int cantidad) {
    _cargasDelPedido = CargasSeleccionadas(tipo: tipo, cantidad: cantidad);
    notifyListeners();
  }

  void eliminarCarga() {
    _cargasDelPedido = null;
    notifyListeners();
  }

  void asignarConductor(int unidadIdx, UserModel? conductor) {
    // No permite que el mismo conductor este asignado a dos cargas
    if (_cargasDelPedido == null) return;
    for (int i = 0; i < _cargasDelPedido!.asignaciones.length; i++) {
      if (i != unidadIdx && _cargasDelPedido!.asignaciones[i].conductor?.uid == conductor?.uid) {
        _cargasDelPedido!.asignaciones[i].conductor = null;
      }
    }
    _cargasDelPedido!.asignaciones[unidadIdx].conductor = conductor;
    notifyListeners();
  }

  void asignarVehiculo(int unidadIdx, VehiculoModel? vehiculo) {
    // No permite que el mismo vehiculo este asignado a dos cargas
    if (_cargasDelPedido == null) return;
    for (int i = 0; i < _cargasDelPedido!.asignaciones.length; i++) {
      if (i != unidadIdx && _cargasDelPedido!.asignaciones[i].vehiculo?.matricula == vehiculo?.matricula) {
        _cargasDelPedido!.asignaciones[i].vehiculo = null;
      }
    }
    _cargasDelPedido!.asignaciones[unidadIdx].vehiculo = vehiculo;
    notifyListeners();
  }

  void asignarFechaLimite(int unidadIdx, DateTime fecha) {
    if (_cargasDelPedido == null) return;
    _cargasDelPedido!.asignaciones[unidadIdx].fechaLimite = fecha;
    notifyListeners();
  }

  Future<bool> crearPedido({
    required String descripcion,
    required String clienteId,
    required DateTime fechaCarga,
    required DateTime fechaDescarga,
    String? notas,
  }) async {
    if (_cargasDelPedido == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cargasPayload = _cargasDelPedido!.asignaciones.map((asig) => {
        'tipoCargaId': _cargasDelPedido!.tipo.id,
        'transportistaId': asig.conductor?.uid,
        'conductorNombre': asig.conductor != null ? '${asig.conductor!.nombre} ${asig.conductor!.apellido}'.trim() : null,
        'vehiculoId': asig.vehiculo?.matricula,
        if (asig.fechaLimite != null) 'fechaDescarga': asig.fechaLimite!.toIso8601String(),
      }).toList();

      await _service.crearPedido(
        descripcion: descripcion,
        clienteId: clienteId,
        fechaCarga: fechaCarga,
        fechaDescarga: fechaDescarga,
        cargas: cargasPayload,
      );

      _resetForm();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    _cargasDelPedido = null;
    _datosTemporalPedido = {};
  }
}