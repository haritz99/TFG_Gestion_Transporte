import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/widgets/kpi_card.dart';
import 'conductorProvider.dart';

class ConductoresKpiGrid extends StatelessWidget {
  final bool isMobile;
  final ConductorProvider provider;

  const ConductoresKpiGrid({
    super.key,
    required this.isMobile,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.5 : 1.75,
      children: [
        KpiCard(
          label: 'Cargas asignadas hoy',
          value: provider.cargasHoy.length.toString(),
        ),
        KpiCard(
          label: provider.proximaEntrega != null ? 'Próxima entrega' : 'Sin entregas pendientes',
          value: provider.proximaEntrega != null
              ? '${provider.proximaEntrega!.fechaDescarga.hour}/${provider.proximaEntrega!.fechaDescarga.day}/'
              '${provider.proximaEntrega!.fechaDescarga.month} · '
              '${provider.proximaEntrega!.origen}/${provider.proximaEntrega!.destino}'
              : '',
        ),
      ],
    );
  }
}
