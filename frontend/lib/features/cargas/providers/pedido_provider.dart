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
  DateTime? fechaCarga;
  DateTime? fechaLimite;

  AsignacionCarga({this.conductor, this.vehiculo, this.fechaCarga, this.fechaLimite});
}


class PedidoProvider extends ChangeNotifier {
  final PedidoService _service;

  final List<PedidoModel> _pedidos = [];
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
    ExternalUserModel? cliente, // en realidad es el cargador
    DateTime? fechaCarga,
    DateTime? fechaDescarga,
    String? clienteNombre,
    String? clienteNif,
    String? clienteCalle,
    String? clienteCp,
    String? clienteCiudad,
    String? clienteProvincia,
  }) {
    if (descripcion != null) _datosTemporalPedido['descripcion'] = descripcion;
    if (cliente != null) _datosTemporalPedido['cliente'] = cliente;
    if (fechaCarga != null) _datosTemporalPedido['fechaCarga'] = fechaCarga;
    if (fechaDescarga != null) _datosTemporalPedido['fechaDescarga'] = fechaDescarga;
    if (clienteNombre != null) _datosTemporalPedido['clienteNombre'] = clienteNombre;
    if (clienteNif != null) _datosTemporalPedido['clienteNif'] = clienteNif;
    if (clienteCalle != null) _datosTemporalPedido['clienteCalle'] = clienteCalle;
    if (clienteCp != null) _datosTemporalPedido['clienteCp'] = clienteCp;
    if (clienteCiudad != null) _datosTemporalPedido['clienteCiudad'] = clienteCiudad;
    if (clienteProvincia != null) _datosTemporalPedido['clienteProvincia'] = clienteProvincia;
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

  void asignarFechaCarga(int unidadIdx, DateTime fecha) {
    if (_cargasDelPedido == null) return;
    _cargasDelPedido!.asignaciones[unidadIdx].fechaCarga = fecha;
    notifyListeners();
  }

  Future<bool> crearPedido() async {
    if (_cargasDelPedido == null) return false;

    final descripcion = _datosTemporalPedido['descripcion'] as String?;
    final cliente = _datosTemporalPedido['cliente'] as ExternalUserModel;
    final fechaCarga = _datosTemporalPedido['fechaCarga'] as DateTime? ?? DateTime.now();
    final fechaDescarga = _datosTemporalPedido['fechaDescarga'] as DateTime? ?? DateTime.now().add(const Duration(days: 7));


    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cargasPayload = _cargasDelPedido!.asignaciones.map((asig) => {
        'tipoCargaId': _cargasDelPedido!.tipo.id,
        'transportistaId': asig.conductor?.uid,
        'conductorNombre': asig.conductor != null ? '${asig.conductor!.nombre} ${asig.conductor!.apellido}'.trim() : null,
        'vehiculoId': asig.vehiculo?.matricula,
        'fechaCarga': (asig.fechaCarga ?? fechaCarga).toIso8601String(),
        'fechaDescarga': (asig.fechaLimite ?? fechaDescarga).toIso8601String(),
      }).toList();

      final calle = _datosTemporalPedido['clienteCalle'] ?? '';
      final cp = _datosTemporalPedido['clienteCp'] ?? '';
      final ciudad = _datosTemporalPedido['clienteCiudad'] ?? '';
      final provincia = _datosTemporalPedido['clienteProvincia'] ?? '';
      final direccionCompleta = "$calle, CP: $cp, $ciudad, $provincia".trim();

      await _service.crearPedido(
        destinatarioNombre: _datosTemporalPedido['clienteNombre'] ?? '',
        destinatarioNif: _datosTemporalPedido['clienteNif'] ?? '',
        destinatarioDireccion: direccionCompleta,
        descripcion: descripcion,
        clienteId: cliente.uid, // en realidad es el cargadorId
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
  
  Future<List<PedidoModel>> getPedidosDelCargador() async {
    try {
      _isLoading = true;
      notifyListeners();
      final fetchedPedidos = await _service.getPedidosDelCargador();
      _pedidos.clear();
      _pedidos.addAll(fetchedPedidos);
      return fetchedPedidos;
    } catch (e) {
      throw Exception('Error al obtener pedidos del cargador: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PedidoModel> pedidosFiltrados(String estado) {
    if (estado == 'Todos') return _pedidos;
    return _pedidos.where((p) => p.estado.name == estado.toLowerCase()).toList();
  }

  void _resetForm() {
    _cargasDelPedido = null;
    _datosTemporalPedido = {};
  }
}