import 'package:flutter/material.dart';

import '../../../../core/widgets/kpi_card.dart';

class TeamKpiGrid extends StatelessWidget {
  const TeamKpiGrid ({
    super.key,
    this.totalEquipo,
    this.enRuta,
    this.sinAsignar,
    this.asignacionParcial,
    this.inactivos,
    required this.isMobile,
  });

  final int? totalEquipo;
  final int? enRuta;
  final int? sinAsignar;
  final int? asignacionParcial;
  final int? inactivos;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      FleetKpiCard(value: totalEquipo?.toString(), label: 'Total Equipo'),
      FleetKpiCard(value: enRuta?.toString(), label: 'En Ruta'),
      FleetKpiCard(value: sinAsignar?.toString(), label: 'Sin Asignar'),
      FleetKpiCard(value: asignacionParcial?.toString(), label: 'Asignados Parcialmente'),
      FleetKpiCard(value: inactivos?.toString(), label: 'Inactivos'),
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

