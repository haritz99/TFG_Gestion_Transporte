import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../features/dashboard/ui/models/carga_data_source.dart';
import '../models/carga_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CoreCalendar extends StatefulWidget {
  final List<CargaModel> cargas;
  final Function(DateTime)? onDateSelected;

  const CoreCalendar({
    super.key,
    required this.cargas,
    this.onDateSelected,
  });

  @override
  State<CoreCalendar> createState() => _CoreCalendarState();
}

class _CoreCalendarState extends State<CoreCalendar> {
  final CalendarController _calendarController = CalendarController();

  bool _esMismoDia(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final int appointmentDisplayCount = 6;
    final List<CargaCalendar> calendarEntries = [];
    for (final carga in widget.cargas) {
      calendarEntries.add(CargaCalendar(carga: carga, op: Operacion.carga));
      if (!_esMismoDia(carga.fechaCarga, carga.fechaDescarga)) {
        calendarEntries.add(CargaCalendar(carga: carga, op: Operacion.descarga));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SfCalendar(
                  key: ValueKey('${constraints.maxWidth}_${constraints.maxHeight}'),
                  controller: _calendarController,
                  view: _calendarController.view ?? CalendarView.schedule,
                  firstDayOfWeek: 1,
                  dataSource: CargaDataSource(calendarEntries),
                  headerHeight: 40,
                  cellBorderColor: Colors.grey.withValues(alpha: 0.15),
                  todayHighlightColor: AppColors.primary,
                  selectionDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  monthViewSettings: MonthViewSettings(
                    appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                    appointmentDisplayCount: appointmentDisplayCount, // Maximo 6 botones para mostrar cargas
                    showAgenda: true,
                    dayFormat: 'EEE',
                    agendaItemHeight: 130,
                    agendaStyle: const AgendaStyle(
                      appointmentTextStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  scheduleViewSettings: ScheduleViewSettings(
                    appointmentItemHeight: 130,
                    hideEmptyScheduleWeek: false,
                    dayHeaderSettings: const DayHeaderSettings(
                      dayTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.bodyText),
                      dateTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.bodyText),
                    ),
                    monthHeaderSettings: MonthHeaderSettings(
                      height: 50,
                      textAlign: TextAlign.center,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                      monthTextStyle: AppTextStyles.headingMd.copyWith(fontSize: 18, color: AppColors.bodyText),
                    ),
                  ),
                  appointmentBuilder: _appointmentBuilder,
                  onSelectionChanged: (details) {
                    if (widget.onDateSelected != null && details.date != null) {
                      widget.onDateSelected!(details.date!);
                    }
                  },
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calendario de Pedidos',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.cargas.length} cargas próximas',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText),
              ),
            ],
          ),
        ),
        _ViewToggleButtons(controller: _calendarController),
      ],
    );
  }

  Widget _appointmentBuilder(BuildContext context, CalendarAppointmentDetails details) {
    if (details.appointments.isEmpty) return const SizedBox();
    final CargaCalendar entry = details.appointments.first;
    CargaModel carga = entry.carga;
    final Color eventColor = CargaDataSource.getColorByEstado(carga.estado.value);

    final mismoDia = _esMismoDia(carga.fechaCarga, carga.fechaDescarga);

    final isCarga = entry.op == Operacion.carga;
    final operacion = isCarga ? 'Carga' : 'Descarga';
    final horaCarga = DateFormat('HH:mm').format(carga.fechaCarga);
    final horaDescarga = DateFormat('HH:mm').format(carga.fechaDescarga);
    final fechaDescargaCompleta = DateFormat('dd/MM/yyyy HH:mm').format(carga.fechaDescarga);
    final fechaCargaCompleta = DateFormat('dd/MM/yyyy HH:mm').format(carga.fechaCarga);

    String fechaText = '';
    if (mismoDia) {
      fechaText = 'Carga: $horaCarga - Descarga: $horaDescarga';
    } else {
      if (isCarga) {
        fechaText = 'Hora de carga: $horaCarga - Fecha descarga: $fechaDescargaCompleta';
      } else {
        fechaText = 'Hora de descarga: $horaDescarga - Fecha carga: $fechaCargaCompleta';
      }
    }

    if (_calendarController.view == CalendarView.month && details.bounds.width < 50) {
      // Aqui solo el botón para ver que hay cargas (sin info.)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: eventColor,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    // Vista Schedule
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${carga.pedidoId} - ${carga.id} - $operacion',
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.bodyText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Origen: ${carga.origenTexto}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Destino: ${carga.destinoTexto}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fechaText,
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vehículo: ${carga.vehiculoId ?? ""}',
                    style: AppTextStyles.bodySm,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Conductor: ${carga.transportistaNombre ?? ""}',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: eventColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                carga.estado.value.toUpperCase(),
                style: TextStyle(
                  color: eventColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    Widget buildLegendItem(String label, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText, fontSize: 12),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          buildLegendItem('Pendiente', AppColors.calendarPendiente),
          buildLegendItem('Planificado', AppColors.calendarPlanificado),
          buildLegendItem('Asignado', AppColors.calendarAsignado),
          buildLegendItem('En Tránsito', AppColors.calendarEnRuta),
          buildLegendItem('Entregado', AppColors.calendarEntregado),
        ],
      ),
    );
  }
}

class _ViewToggleButtons extends StatefulWidget {
  final CalendarController controller;

  const _ViewToggleButtons({required this.controller});

  @override
  State<_ViewToggleButtons> createState() => _ViewToggleButtonsState();
}

class _ViewToggleButtonsState extends State<_ViewToggleButtons> {
  late CalendarView _currentView;

  @override
  void initState() {
    super.initState();
    _currentView = widget.controller.view ?? CalendarView.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildViewToggleButton('Mes', CalendarView.month),
        const SizedBox(width: 8),
        _buildViewToggleButton('Semana', CalendarView.schedule),
      ],
    );
  }

  Widget _buildViewToggleButton(String label, CalendarView view) {
    final isSelected = _currentView == view;
    return InkWell(
      onTap: () {
        setState(() {
          _currentView = view;
        });
        widget.controller.view = view;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(
            color: isSelected ? AppColors.primary : AppColors.bodyText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
