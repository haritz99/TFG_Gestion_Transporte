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

    final cargasVisibles = cargaProvider.cargas.where((c) {
      return c.estado != EstadoCarga.pendiente && c.estado != EstadoCarga.cedido;
    }).toList();

    final Set<String> pedidoIdsMostrados = cargasVisibles
        .map((c) => c.pedidoId ?? 'sin-pedido')
        .toSet();

    final List<CalendarResource> recursos = pedidoIdsMostrados.map((pId) {
      final pInfo = pedidoProvider.pedidos.where((p) => p.id == pId).firstOrNull;

      final displayName = pInfo != null
          ? '${pInfo.id?.toUpperCase() ?? ''} - ${pInfo.descripcion}'
          : '${pId != 'sin-pedido' && pId.length > 8 ? pId.substring(0,8).toUpperCase() : pId.toUpperCase()}';

      return CalendarResource(
        id: pId,
        displayName: displayName,
        color: Colors.transparent,
      );
    }).toList();

    if (recursos.isEmpty) {
      recursos.add(CalendarResource(id: 'dummy', displayName: 'Sin cargas en progreso', color: Colors.transparent));
    }

    final List<Appointment> appointments = cargasVisibles.map((c) {
      final subject = '${c.mercancia} - ${c.origen.direccion.ciudad} → ${c.destino.direccion.ciudad}';
      return Appointment(
        id: c.id,
        startTime: c.fechaCarga,
        endTime: c.fechaDescarga,
        subject: subject,
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
            planProvider.marcarComoPlanificada(carga.id!);
            cargaProvider.planificarCarga(
              carga.id!,
              DateTime.now(),
              DateTime.now().add(const Duration(hours: 4)),
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
              allowAppointmentResize: true,
              onDragStart: (AppointmentDragStartDetails details) {
                if (details.appointment != null) {
                  final app = details.appointment as Appointment;
                  final carga = cargaProvider.cargas.firstWhere((c) => c.id == app.id);
                  planProvider.seleccionarCarga(carga);
                }
              },
              onDragEnd: (AppointmentDragEndDetails details) {
                if (details.appointment != null) {
                  final appointment = details.appointment as Appointment;
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
              onAppointmentResizeStart: (AppointmentResizeStartDetails details) {
                final appointment = details.appointment as Appointment?;
                if (appointment != null) {
                  final carga = cargaProvider.cargas.firstWhere((c) => c.id == appointment.id);
                  planProvider.seleccionarCarga(carga);
                }
              },
              onAppointmentResizeEnd: (AppointmentResizeEndDetails details) {
                final appointment = details.appointment as Appointment?;
                if (appointment == null) return;
                final start = details.startTime ?? appointment.startTime;
                final end = details.endTime ?? appointment.endTime;
                if (!end.isAfter(start)) return;
                cargaProvider.actualizarFechasCarga(
                  appointment.id as String,
                  start,
                  end,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getColorPorEstado(CargaModel carga) {
    if (carga.estado == EstadoCarga.asignado) return Colors.blue.shade300;
    if (carga.estado == EstadoCarga.enTransito) return Colors.orange.shade300;
    if (carga.estado == EstadoCarga.entregado) return Colors.green.shade300;
    return AppColors.primary.withValues(alpha: 0.6);
  }
}

class CargasDataSource extends CalendarDataSource {
  CargasDataSource(List<Appointment> source, List<CalendarResource> resourceCollection) {
    appointments = source;
    resources = resourceCollection;
  }
}
