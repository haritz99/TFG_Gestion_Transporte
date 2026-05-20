import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/carga_model.dart';
import '../../providers/planificacion_provider.dart';
import '../../../cargas/providers/carga_provider.dart';
import '../../../cargas/providers/pedido_provider.dart';

class CalendarioCargas extends StatefulWidget {
  const CalendarioCargas({super.key});

  @override
  State<CalendarioCargas> createState() => _CalendarioCargasState();
}

class _CalendarioCargasState extends State<CalendarioCargas> {
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _calendarController.view = CalendarView.timelineWeek;
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanificacionProvider>();
    final pedidoProvider = context.watch<PedidoProvider>();
    final cargaProvider = context.watch<CargaProvider>();

    final List<CalendarResource> recursos = pedidoProvider.pedidos.map((p) {
      return CalendarResource(
        id: p.id!,
        displayName: '${p.id?.toUpperCase()} - ${p.descripcion}',
        color: AppColors.primary,
      );
    }).toList();

    final List<Appointment> appointments = cargaProvider.cargas
        .where((c) => c.estado != EstadoCarga.pendiente || planProvider.cargasPlanificadasIds.contains(c.id))
        .map((c) {
      return Appointment(
        id: c.id,
        startTime: c.fechaCarga,
        endTime: c.fechaDescarga,
        subject: c.mercancia,
        color: _getColorPorEstado(c),
        resourceIds: [c.pedidoId ?? 'unknown'],
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DragTarget<CargaModel>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final carga = details.data;
            // Marcar como planificada en el provider de UI
            planProvider.marcarComoPlanificada(carga.id!);
            // Actualizar fechas en el provider de datos (esto disparará el rebuild)
            cargaProvider.actualizarFechasCarga(
              carga.id!,
              DateTime.now(),
              DateTime.now().add(const Duration(hours: 4))
            );
          },
          builder: (context, candidateData, rejectedData) {
            return SfCalendar(
              view: CalendarView.timelineWeek,
              controller: _calendarController,
              firstDayOfWeek: 1, 
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 0,
                endHour: 24,
                nonWorkingDays: <int>[6, 7],
                timelineAppointmentHeight: 50,
              ),
              resourceViewSettings: ResourceViewSettings(
                visibleResourceCount: recursos.length > 5 ? 5 : (recursos.isEmpty ? 1 : recursos.length),
                showAvatar: false,
                displayNameTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.bodyText,
                ),
              ),
              dataSource: CargasDataSource(appointments, recursos),
              allowDragAndDrop: true,
              onDragStart: (AppointmentDragStartDetails details) {
                // Guarda seleccion
                if (details.appointment != null) {
                  final app = details.appointment as Appointment;
                  final carga = cargaProvider.cargas.firstWhere((c) => c.id == app.id);
                  planProvider.seleccionarCarga(carga);
                }
              },
              onDragEnd: (AppointmentDragEndDetails details) {
                if (details.appointment != null) {
                  final appointment = details.appointment as Appointment;
                  // Si no podemos validar el cambio de recurso fácilmente con esta versión de Syncfusion,
                  // nos centramos en actualizar las fechas. 
                  // El usuario ya expresó que el eje es principalmente visual y de ayuda.
                  cargaProvider.actualizarFechasCarga(
                    appointment.id as String,
                    details.droppingTime ?? appointment.startTime,
                    (details.droppingTime ?? appointment.startTime).add(appointment.endTime.difference(appointment.startTime)),
                  );
                }
              },
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.appointment) {
                  if (details.appointments != null && details.appointments!.isNotEmpty) {
                    final app = details.appointments!.first as Appointment;
                    final carga = cargaProvider.cargas.firstWhere((c) => c.id == app.id);
                    planProvider.seleccionarCarga(carga);
                  }
                } else if (details.targetElement == CalendarElement.calendarCell) {
                  planProvider.limpiarSeleccion();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Color _getColorPorEstado(CargaModel carga) {
    if (carga.estado == EstadoCarga.asignado) return Colors.blue;
    if (carga.estado == EstadoCarga.enTransito) return Colors.orange;
    if (carga.estado == EstadoCarga.entregado) return Colors.green;
    return AppColors.primary;
  }
}

class CargasDataSource extends CalendarDataSource {
  CargasDataSource(List<Appointment> source, List<CalendarResource> resourceCollection) {
    appointments = source;
    resources = resourceCollection;
  }
}
