import 'package:flutter/material.dart';
import '../../../../core/models/carga_model.dart';

class PlanificacionProvider extends ChangeNotifier {
  final Set<String> _cargasPlanificadasIds = {};
  Set<String> get cargasPlanificadasIds => _cargasPlanificadasIds;

  CargaModel? _cargaSeleccionada;
  CargaModel? get cargaSeleccionada => _cargaSeleccionada;

  void seleccionarCarga(CargaModel? carga) {
    _cargaSeleccionada = carga;
    notifyListeners();
  }

  void marcarComoPlanificada(String cargaId) {
    _cargasPlanificadasIds.add(cargaId);
    notifyListeners();
  }

  void limpiarSeleccion() {
    _cargaSeleccionada = null;
    notifyListeners();
  }
}
