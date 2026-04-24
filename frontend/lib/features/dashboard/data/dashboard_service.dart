import 'dart:convert';
import 'package:gestion_transporte/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class DashboardSummary {
  final int cargasActivas;
  final int cargasSinAsignar;
  final int incidenciasAbiertas;
  final int entregadasHoy;
  final int totalEntregasHoy;

  DashboardSummary({
    required this.cargasActivas,
    required this.cargasSinAsignar,
    required this.incidenciasAbiertas,
    required this.entregadasHoy,
    required this.totalEntregasHoy,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      cargasActivas: json['cargasActivas'] ?? 0,
      cargasSinAsignar: json['cargasSinAsignar'] ?? 0,
      incidenciasAbiertas: json['incidenciasAbiertas'] ?? 0,
      entregadasHoy: json['entregadasHoy'] ?? 0,
      totalEntregasHoy: json['totalEntregasHoy'] ?? 0,
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

