import 'package:flutter/material.dart';
import '../../../core/token_provider.dart';
import '../data/dashboard_service.dart';

// TODO: Estos servicios deberían estar definidos en sus respectivos features.
// Actualmente usaremos el DashboardService temporal que luego llamará a un endpoint agregado
// o a iterar sobre los servicios de cada feature según la estrategia.

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  final AuthTokenProvider _tokenProvider;

  bool _isLoading = true;
  String? _errorMessage;

  // KPIs
  int _cargasActivas = 0;
  int _cargasSinAsignar = 0;
  int _incidenciasAbiertas = 0;
  int _entregadasHoy = 0;
  int _totalEntregasHoy = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get cargasActivas => _cargasActivas;
  int get cargasSinAsignar => _cargasSinAsignar;
  int get incidenciasAbiertas => _incidenciasAbiertas;
  int get entregadasHoy => _entregadasHoy;
  int get totalEntregasHoy => _totalEntregasHoy;

  DashboardProvider({
    required AuthTokenProvider tokenProvider,
    DashboardService? service,
  })  : _service = service ?? DashboardService(),
        _tokenProvider = tokenProvider {
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      final summary = await _service.fetchDashboardSummary(token: token);

      _cargasActivas = summary.cargasActivas;
      _cargasSinAsignar = summary.cargasSinAsignar;
      _incidenciasAbiertas = summary.incidenciasAbiertas;
      _entregadasHoy = summary.entregadasHoy;
      _totalEntregasHoy = summary.totalEntregasHoy;

    } catch (e) {
      _errorMessage = 'Error al cargar el dashboard: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadDashboardData();
  }
}
