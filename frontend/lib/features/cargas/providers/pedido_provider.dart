import 'package:flutter/material.dart';
import '../../../core/models/carga_model.dart';
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

  AsignacionCarga({this.conductor, this.vehiculo});
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

  PedidoProvider({
    required AuthTokenProvider tokenProvider,
    PedidoService? service,
  }) : _service = service ?? PedidoService(tokenProvider);

  void anadirCarga(TipoCargaModel tipo, int cantidad) {
    _cargasDelPedido = CargasSeleccionadas(tipo: tipo, cantidad: cantidad);
    notifyListeners();
  }

  void eliminarCarga() {
    _cargasDelPedido = null;
    notifyListeners();
  }

  void asignarConductor(int unidadIdx, UserModel? conductor) {
    _cargasDelPedido?.asignaciones[unidadIdx].conductor = conductor;
    notifyListeners();
  }

  void asignarVehiculo(int unidadIdx, VehiculoModel? vehiculo) {
    _cargasDelPedido?.asignaciones[unidadIdx].vehiculo = vehiculo;
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
        'vehiculoId': asig.vehiculo?.matricula,
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
  }
}