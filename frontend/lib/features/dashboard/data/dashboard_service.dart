import 'dart:convert';
import 'package:gestion_transporte/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class DashboardSummary {
  final int cargasAsignadas;
  final int cargasSinAsignar;
  final int incidenciasAbiertas;
  final int entregadasHoy;
  final int totalEntregasHoy;

  DashboardSummary({
    required this.cargasAsignadas,
    required this.cargasSinAsignar,
    required this.incidenciasAbiertas,
    required this.entregadasHoy,
    required this.totalEntregasHoy,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      cargasAsignadas: json['cargas_asignadas'] ?? 0,
      cargasSinAsignar: json['cargas_sin_asignar'] ?? 0,
      incidenciasAbiertas: json['incidencias_abiertas'] ?? 0,
      entregadasHoy: json['entregadas_hoy'] ?? 0,
      totalEntregasHoy: json['total_entregas_hoy'] ?? 0,
    );
  }
}

class DashboardService {

  Future<DashboardSummary> fetchDashboardSummary({required String token}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard/summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return DashboardSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load dashboard summary');
    }
  }
}

