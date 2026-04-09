import 'package:flutter/material.dart';

import 'fleet_kpi_card.dart';

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
      FleetKpiCard(value: totalVehiculos?.toString(), label: 'Total Vehiculos'),
      FleetKpiCard(value: asignados?.toString(), label: 'Asignados'),
      FleetKpiCard(value: enMantenimiento?.toString(), label: 'En Mantenimiento'),
      FleetKpiCard(value: disponibles?.toString(), label: 'Disponibles'),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth < 560 ? 1 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: crossAxisCount == 1 ? 3.6 : 1.8,
            ),
            itemBuilder: (_, index) => cards[index],
          );
        },
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


