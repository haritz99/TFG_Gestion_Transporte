import 'package:flutter/foundation.dart';
import '../../../../core/models/carga_model.dart';
import '../../auth/providers/token_provider.dart';
import '../data/carga_service.dart';

class CargaProvider extends ChangeNotifier {
  final CargaService _service;

  List<CargaModel> _cargas = [];
  List<CargaModel> get cargas => _cargas;
  List<TipoCargaModel> _tiposCarga = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  List<TipoCargaModel> get tiposCarga => _tiposCarga;

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
}

