import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/widgets/kpi_card.dart';
import 'package:intl/intl.dart';
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
      crossAxisCount: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 2.5 : 1.5,
      children: [
        KpiCard(
          label: 'Viaje(s) hoy',
          value: provider.cargasHoy.length.toString(),
        ),
        if (provider.proximaEntrega != null)
        ViajeCard(
          fechaHora: DateFormat('dd/MM HH:mm').format(provider.proximaEntrega!.fechaCarga),
          origenDestino: '${provider.proximaEntrega?.origen.direccion.ciudad} → ${provider.proximaEntrega?.destino.direccion.ciudad}',
        )
      ],
    );
  }
}
