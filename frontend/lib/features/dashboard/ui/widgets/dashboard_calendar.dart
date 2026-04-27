import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../core/models/carga_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/carga_data_source.dart';

class DashboardCalendar extends StatefulWidget {
  final List<CargaModel> cargas;
  final Function(DateTime)? onDateSelected;

  const DashboardCalendar({
    super.key,
    required this.cargas,
    this.onDateSelected,
  });

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.week;

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            height: 600,
            child: SfCalendar(
              controller: _calendarController,
              view: _currentView,
              firstDayOfWeek: 1,
              dataSource: CargaDataSource(widget.cargas),
              headerHeight: 40,
              cellBorderColor: Colors.grey.withValues(alpha: 0.15),
              todayHighlightColor: AppColors.primary,
              selectionDecoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              monthViewSettings: MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                showAgenda: false,
                dayFormat: 'EEE',
              ),
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 6, // 6AM
                endHour: 22,  // 22PM
                timeFormat: 'H:mm',
              ),
              appointmentBuilder: _appointmentBuilder,
              onSelectionChanged: (details) {
                if (widget.onDateSelected != null && details.date != null) {
                  widget.onDateSelected!(details.date!);
                }
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
        Column(
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
        Row(
          children: [
            _buildViewToggleButton('Mes', CalendarView.month),
            const SizedBox(width: 8),
            _buildViewToggleButton('Semana', CalendarView.week),
          ],
        )
      ],
    );
  }

  Widget _buildViewToggleButton(String label, CalendarView view) {
    final isSelected = _currentView == view;
    return InkWell(
      onTap: () {
        setState(() {
          _currentView = view;
          _calendarController.view = view;
        });
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

  Widget _appointmentBuilder(BuildContext context, CalendarAppointmentDetails details) {
    if (details.appointments.isEmpty) return const SizedBox();

    final CargaModel carga = details.appointments.first;
    final Color eventColor = CargaDataSource.getColorByEstado(carga.estado);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: eventColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: eventColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              carga.pedidoId != null ? 'Ped: #${carga.pedidoId} - ${carga.id}' : 'Sin Asignar',
              style: TextStyle(
                color: eventColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
          buildLegendItem('Asignado', AppColors.calendarAsignado),
          buildLegendItem('En Tránsito', AppColors.calendarEnRuta),
          buildLegendItem('Entregado', AppColors.calendarEntregado),
        ],
      ),
    );
  }
}