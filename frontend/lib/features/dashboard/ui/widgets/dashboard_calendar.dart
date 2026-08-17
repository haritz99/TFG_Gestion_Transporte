import 'package:flutter/material.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/widgets/core_calendar.dart';

class DashboardCalendar extends StatelessWidget {
  final List<CargaModel> cargas;
  final Function(DateTime)? onDateSelected;
  final Function(CargaModel)? onCargaTap;

  const DashboardCalendar({
    super.key,
    required this.cargas,
    this.onDateSelected,
    this.onCargaTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 800,
      child: CoreCalendar(
        cargas: cargas,
        onDateSelected: onDateSelected,
        onCargaTap: onCargaTap,
      ),
    );
  }
}