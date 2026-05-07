import 'package:flutter/material.dart';
import '../../auth/providers/token_provider.dart';
import '../data/dashboard_service.dart';
import '../../../core/models/carga_model.dart';
import '../../cargas/data/carga_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  final CargaService _cargaService;
  final AuthTokenProvider _tokenProvider;

  bool _isLoading = true;
  String? _errorMessage;

  // KPIs
  int _cargasAsignadas = 0;
  int _cargasSinAsignar = 0;
  int _incidenciasAbiertas = 0;
  int _entregadasHoy = 0;
  int _totalEntregasHoy = 0;

  List<CargaModel> _cargas = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get cargasAsignadas => _cargasAsignadas;
  int get cargasSinAsignar => _cargasSinAsignar;
  int get incidenciasAbiertas => _incidenciasAbiertas;
  int get entregadasHoy => _entregadasHoy;
  int get totalEntregasHoy => _totalEntregasHoy;

  List<CargaModel> get cargas => _cargas;

  DashboardProvider({
    required AuthTokenProvider tokenProvider,
    DashboardService? service,
    CargaService? cargaService,
  })  : _service = service ?? DashboardService(),
        _cargaService = cargaService ?? CargaService(tokenProvider),
        _tokenProvider = tokenProvider {
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _tokenProvider.getRequiredToken();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final results = await Future.wait([
        _service.fetchDashboardSummary(token: token),
        _cargaService.getCargasDelMes(start, end),
      ]);

      final summary = results[0] as DashboardSummary;
      final cargasDelMes = results[1] as List<CargaModel>;

      _cargasAsignadas = summary.cargasAsignadas;
      _cargasSinAsignar = summary.cargasSinAsignar;
      _incidenciasAbiertas = summary.incidenciasAbiertas;
      _entregadasHoy = summary.entregadasHoy;
      _totalEntregasHoy = summary.totalEntregasHoy;

      _cargas = cargasDelMes;

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
