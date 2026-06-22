import 'package:flutter/material.dart';

import '../../../../core/widgets/kpi_card.dart';

class FleetKpiGrid extends StatelessWidget {
  const FleetKpiGrid({
    super.key,
    this.totalVehiculos,
    this.asignados,
    this.enMantenimiento,
    this.disponibles,
    required this.isMobile,
  });

  final int? totalVehiculos;
  final int? asignados;
  final int? enMantenimiento;
  final int? disponibles;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(value: totalVehiculos?.toString(), label: 'Total Vehiculos'),
      KpiCard(value: asignados?.toString(), label: 'Asignados'),
      KpiCard(value: enMantenimiento?.toString(), label: 'Mantenimiento'),
      KpiCard(value: disponibles?.toString(), label: 'Disponibles'),
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 2.8,
        ),
        itemBuilder: (_, index) => cards[index],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 14),
        ]
      ],
    );
  }
}

