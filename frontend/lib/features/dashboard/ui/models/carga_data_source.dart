import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/theme/app_colors.dart';

class CargaDataSource extends CalendarDataSource {
  CargaDataSource(List<CargaModel> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getCargaData(index).fechaCarga;
  }

  @override
  DateTime getEndTime(int index) {
    return _getCargaData(index).fechaDescarga;
  }

  @override
  String getSubject(int index) {
    final pedidoId = _getCargaData(index).pedidoId;
    return pedidoId != null ? '#$pedidoId' : 'Carga';
  }

  static Color getColorByEstado(String estado) {
    if (estado == EstadoCarga.entregado.value) return AppColors.calendarEntregado;
    if (estado == EstadoCarga.asignado.value) return AppColors.calendarAsignado;
    if (estado == EstadoCarga.enTransito.value) return AppColors.calendarEnRuta;
    return AppColors.calendarPendiente;
  }

  @override
  Color getColor(int index) {
    final carga = _getCargaData(index);
    return getColorByEstado(carga.estado.value);
  }

  CargaModel _getCargaData(int index) {
    final dynamic carga = appointments![index];
    late final CargaModel cargaData;
    if (carga is CargaModel) {
      cargaData = carga;
    }
    return cargaData;
  }
}