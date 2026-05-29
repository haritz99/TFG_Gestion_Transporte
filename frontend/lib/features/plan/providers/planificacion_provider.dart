import 'package:flutter/material.dart';
import '../../../../core/models/carga_model.dart';

class PlanificacionProvider extends ChangeNotifier {
  final Set<String> _cargasPlanificadasIds = {};
  Set<String> get cargasPlanificadasIds => _cargasPlanificadasIds;

  CargaModel? _cargaSeleccionada;
  CargaModel? get cargaSeleccionada => _cargaSeleccionada;

  String? _subcontratadoSeleccionadoId;
  String? get subcontratadoSeleccionadoId => _subcontratadoSeleccionadoId;

  double _comisionSeleccionada = 3;
  double get comisionSeleccionada => _comisionSeleccionada;

  void seleccionarComision(double comision) {
    _comisionSeleccionada = comision;
    notifyListeners();
  }

  void seleccionarCarga(CargaModel? carga) {
    _cargaSeleccionada = carga;
    _subcontratadoSeleccionadoId = null;
    _comisionSeleccionada = 3.0;
    notifyListeners();
  }

  void seleccionarSubcontratado(String? uid) {
    _subcontratadoSeleccionadoId = uid;
    notifyListeners();
  }

  void marcarComoPlanificada(String cargaId) {
    _cargasPlanificadasIds.add(cargaId);
    notifyListeners();
  }

  void limpiarSeleccion() {
    _cargaSeleccionada = null;
    _subcontratadoSeleccionadoId = null;
    notifyListeners();
  }
}
