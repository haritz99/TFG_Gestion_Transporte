import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/widgets/management_page_layout.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:gestion_transporte/core/models/carga_model.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table.dart';
import 'package:gestion_transporte/core/widgets/core_table/core_table_column.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/pdf/pdf_handler.dart';
import '../../cargas/providers/carga_provider.dart';

class SubListadoCargas extends StatefulWidget {
  const SubListadoCargas({super.key});

  @override
  State<SubListadoCargas> createState() => _SubListadoCargasState();
}

class _SubListadoCargasState extends State<SubListadoCargas> {
  String _selectedStatus = EstadoCarga.cedido.value;
  final _conductorCtrl = TextEditingController();
  final _transportistaCtrl = TextEditingController();
  final _vehiculoCtrl = TextEditingController();
  final _remolqueCtrl = TextEditingController();

  static final RegExp _nombreApellidosRegex =
      RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)+$");
  static final RegExp _matriculaRegex =
      RegExp(r"^\d{4}[ABCDFGHJKLMNPRSTVWXYZ]{3}$");

  @override
  void dispose() {
    _conductorCtrl.dispose();
    _transportistaCtrl.dispose();
    _vehiculoCtrl.dispose();
    _remolqueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CargaProvider>();

    final cargasFiltradas = provider.cargasCedidasFiltradas(_selectedStatus);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargas Cedidas', style: AppTextStyles.headingMd),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: AppColors.pageBackground,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ManagementPageLayout(
              header: const SizedBox.shrink(),
              table: CoreTable<CargaModel>(
                rows: cargasFiltradas,
                columns: _buildColumns(context),
                selectedStatus: _selectedStatus,
                statusOptions: [EstadoCarga.cedido.value],
                isMobile: ResponsiveBreakpoints.of(context).isMobile,
                mobileCardBuilder: (carga) => _buildMobileCard(context, carga),
                onStatusChanged: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                onDesktopPageChanged: (page) {},
              ),
              hasMore: false,
              isLoadingMore: false,
              isMobile: ResponsiveBreakpoints.of(context).isMobile
            ),
    );
  }

  List<CoreTableColumn<CargaModel>> _buildColumns(BuildContext context) {
    return [
      CoreTableColumn<CargaModel>(
        label: 'ID',
        cellBuilder: (carga) => Text(carga.id ?? '-', style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Origen',
        cellBuilder: (carga) => Tooltip(
          message: carga.origenTexto,
          child: SizedBox(
            width: 160,
            child: Text(carga.origen.direccion.ciudad, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1,),
          )
        ),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Destino',
        cellBuilder: (carga) => Tooltip(
          message: carga.destinoTexto,
          child: SizedBox(
            width: 160,
            child: Text(carga.destino.direccion.ciudad, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1,),
          )
        ),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Fecha Carga',
        cellBuilder: (carga) => Text(
          DateFormat('dd/MM/yyyy HH:mm').format(carga.fechaCarga),
          style: AppTextStyles.bodyMd,
        ),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Fecha Descarga',
        cellBuilder: (carga) => Text(
          DateFormat('dd/MM/yyyy HH:mm').format(carga.fechaDescarga),
          style: AppTextStyles.bodyMd,
        ),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Mercancía',
        cellBuilder: (carga) => Text(carga.mercancia, style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Bultos',
        cellBuilder: (carga) => Text(carga.numBultos.toString(), style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Peso (kg)',
        cellBuilder: (carga) => Text(carga.peso.toStringAsFixed(2), style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Precio (€)',
        cellBuilder: (carga) => Text(carga.precio.toStringAsFixed(2), style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Conductor',
        cellBuilder: (carga) => Text(carga.transportistaNombre ?? 'Sin asignar', style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Vehículo',
        cellBuilder: (carga) => Text(carga.cartaPorteSnapshot?.subVehiculoMatricula ?? 'Sin asignar', style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Remolque',
        cellBuilder: (carga) => Text(carga.cartaPorteSnapshot?.subRemolqueMatricula ?? 'Sin asignar', style: AppTextStyles.bodyMd),
      ),
      CoreTableColumn<CargaModel>(
        label: 'Estado',
        cellBuilder: (carga) {
          final estadosManuales = [
            EstadoCarga.enTransito,
            EstadoCarga.entregado,
          ];
          if (!estadosManuales.contains(carga.estado)) {
            return Text(carga.estado.name.toUpperCase(), style: AppTextStyles.bodyMd);
          }
          return DropdownButton<EstadoCarga>(
            value: carga.estado,
            items: estadosManuales.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.name.toUpperCase(), style: AppTextStyles.bodyMd),
            )).toList(),
            onChanged: (nuevoEstado) {
              if (nuevoEstado != null && nuevoEstado != carga.estado) {
                context.read<CargaProvider>().updateCargaSubcontratado(
                  cargaId: carga.id!,
                  estado: nuevoEstado,
                );
              }
            },
          );
        },
      ),
      CoreTableColumn<CargaModel>(
          label: 'Carta Porte',
          cellBuilder: (carga) {
            return pdfButton(carga);
          }
      ),
      CoreTableColumn<CargaModel>(
          label: 'Acciones',
          cellBuilder: (p) => IconButton(icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditDialog(context, p))
      ),
    ];
  }

  Widget _buildMobileCard(BuildContext context, CargaModel carga) {
    return ListTile(
      title: Text('${carga.origenTexto} → ${carga.destinoTexto}'),
      subtitle: Text('Mercancía: ${carga.mercancia}\nConductor: ${carga.transportistaNombre ?? "Sin asignar"}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pdfButton(carga),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditDialog(context, carga),
          ),
        ]


      ),
    );
  }

  Widget pdfButton(CargaModel carga) {
    final url = carga.cartaPorteUrl;
    final tieneCartaPorte = url != null && url.isNotEmpty;
    return IconButton(
      icon: Icon(
        Icons.picture_as_pdf,
        color: tieneCartaPorte ? AppColors.primary : AppColors.mutedText,
      ),
      onPressed: tieneCartaPorte ? () => PdfHandler.instance.open(carga.cartaPorteUrl!, 'carta_porte_${carga.id}.pdf') : null,
      tooltip: tieneCartaPorte ? 'Ver carta' : 'Aún no generada',
    );
  }

  void _showEditDialog(BuildContext context, CargaModel carga) {
    _conductorCtrl.text = carga.transportistaNombre ?? '';
    _transportistaCtrl.text = carga.transportistaId ?? '';
    _vehiculoCtrl.text = carga.cartaPorteSnapshot?.subVehiculoMatricula ?? '';
    _remolqueCtrl.text = carga.cartaPorteSnapshot?.subRemolqueMatricula ?? '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Asignar Conductor y Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  controller: _conductorCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre y apellidos del Conductor'),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _vehiculoCtrl,
                  decoration: const InputDecoration(labelText: 'Matrícula del Vehículo'),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _remolqueCtrl,
                  decoration: const InputDecoration(labelText: 'Matrícula del Remolque'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = _conductorCtrl.text.trim();
                final vehiculo = _normalizarMatricula(_vehiculoCtrl.text);
                final remolque = _normalizarMatricula(_remolqueCtrl.text);

                if (nombre.isNotEmpty && !_nombreApellidosRegex.hasMatch(nombre)) {
                  _mostrarError('El conductor debe tener nombre y apellidos válidos.');
                  return;
                }
                if (vehiculo.isNotEmpty && !_matriculaRegex.hasMatch(vehiculo)) {
                  _mostrarError('La matrícula del vehículo debe tener formato correcto: 1234ABC.');
                  return;
                }
                if (remolque.isNotEmpty && !_matriculaRegex.hasMatch(remolque)) {
                  _mostrarError('La matrícula del remolque debe tener formato correcto: 1234ABC.');
                  return;
                }

                context.read<CargaProvider>().updateCargaSubcontratado(
                  cargaId: carga.id!,
                  conductorNombre: nombre.isNotEmpty ? nombre : null,
                  subVehiculoMatricula: vehiculo.isNotEmpty ? vehiculo : null,
                  subRemolqueMatricula: remolque.isNotEmpty ? remolque : null,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  String _normalizarMatricula(String raw) {
    return raw.trim().toUpperCase().replaceAll('-', '').replaceAll(' ', '');
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}
