import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/theme/app_colors.dart';

enum Operacion { carga, descarga }
class CargaCalendar {
  final CargaModel carga;
  final Operacion op;

  const CargaCalendar({
    required this.carga,
    required this.op,
  });

  DateTime get fecha => op == Operacion.carga ? carga.fechaCarga : carga.fechaDescarga;
}

class CargaDataSource extends CalendarDataSource {
  CargaDataSource(List<CargaCalendar> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getItem(index).fecha;
  }

  @override
  DateTime getEndTime(int index) {
    return _getItem(index).fecha.add(const Duration(minutes: 30));
  }

  @override
  String getSubject(int index) {
    final pedidoId = _getItem(index).carga.pedidoId;
    return pedidoId != null ? '#$pedidoId' : 'Carga';
  }

  static Color getColorByEstado(String estado) {
    if (estado == EstadoCarga.entregado.value) return AppColors.calendarEntregado;
    if (estado == EstadoCarga.planificado.value) return AppColors.calendarPlanificado;
    if (estado == EstadoCarga.asignado.value) return AppColors.calendarAsignado;
    if (estado == EstadoCarga.enTransito.value) return AppColors.calendarEnRuta;
    return AppColors.calendarPendiente;
  }

  @override
  Color getColor(int index) {
    final item = _getItem(index);
    return getColorByEstado(item.carga.estado.value);
  }

  CargaCalendar _getItem(int index) {
    final dynamic item = appointments![index];
    if (item is CargaCalendar) {
      return item;
    }
    throw ArgumentError('Entrada de calendario inesperada: $item');
  }
}