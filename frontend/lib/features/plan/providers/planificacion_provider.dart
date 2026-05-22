import 'package:flutter/material.dart';
import '../../../../core/models/carga_model.dart';

class PlanificacionProvider extends ChangeNotifier {
  final Set<String> _cargasPlanificadasIds = {};
  Set<String> get cargasPlanificadasIds => _cargasPlanificadasIds;

  CargaModel? _cargaSeleccionada;
  CargaModel? get cargaSeleccionada => _cargaSeleccionada;

  String? _subcontratadoSeleccionadoId;
  String? get subcontratadoSeleccionadoId => _subcontratadoSeleccionadoId;

  void seleccionarCarga(CargaModel? carga) {
    _cargaSeleccionada = carga;
    _subcontratadoSeleccionadoId = null;
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
