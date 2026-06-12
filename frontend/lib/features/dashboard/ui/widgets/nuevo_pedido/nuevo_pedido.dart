import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gestion_transporte/features/auth/providers/auth_provider.dart';
import '../../../../../core/models/carga_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../cargas/providers/pedido_provider.dart';
import '../../../../cargas/providers/carga_provider.dart';
import 'nuevo_tipo_carga.dart';

class NuevoPedidoForm extends StatefulWidget {
  final List<ExternalUserModel> clientes;
  const NuevoPedidoForm({super.key, required this.clientes});
  @override
  State<NuevoPedidoForm> createState() => NuevoPedidoFormState();
}

class NuevoPedidoFormState extends State<NuevoPedidoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descripcionController;
  ExternalUserModel? _selectedCliente;
  DateTime? _fechaCarga;
  DateTime? _fechaDescarga;

  TipoCargaModel? _selectedTipo;
  int _cantidad = 1;

  ExternalUserModel? get selectedCliente => _selectedCliente;
  String get descripcion => _descripcionController.text;
  DateTime? get fechaCarga => _fechaCarga;
  DateTime? get fechaDescarga => _fechaDescarga;

  @override
  void initState() {
    super.initState();
    final pedidoProvider = context.read<PedidoProvider>();

    _descripcionController = TextEditingController(text: pedidoProvider.datosTemporalPedido['descripcion'] ?? '');
    _fechaCarga = pedidoProvider.datosTemporalPedido['fechaCarga'] ?? DateTime.now();
    _fechaDescarga = pedidoProvider.datosTemporalPedido['fechaDescarga'] ?? DateTime.now().add(const Duration(days: 7));

    _selectedCliente = pedidoProvider.datosTemporalPedido['cliente'];

    if (_selectedCliente == null) {
      final user = context.read<AuthProvider>().user;
      if (user != null && user.rol.contains('cliente')) {
        _selectedCliente = ExternalUserModel(
          uid: user.uid,
          nombre: user.nombre,
          rol: user.rol,
          datosCompletos: true,
          email: user.email,
          companyId: user.companyId,
        );
        pedidoProvider.actualizarDatosTemporales(cliente: _selectedCliente);
      }
    }

    if (_selectedCliente != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CargaProvider>().fetchTiposCarga(_selectedCliente!.uid);
      });
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  bool validate() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_fechaCarga != null && _fechaDescarga != null) {
        return true;
      }
    }
    return false;
  }

  Future<DateTime?> _showCalendarDialog(BuildContext context, {DateTime? initialDate, DateTime? firstDate, DateTime? lastDate}) async {
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 500,
            width: 400,
            child: SfCalendar(
              view: CalendarView.day,
              initialDisplayDate: initialDate,
              minDate: firstDate,
              maxDate: lastDate,
              allowedViews: const [
                CalendarView.day,
                CalendarView.week,
                CalendarView.month,
              ],
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.calendarCell) {
                  DateTime? fechaHoraSeleccionada = details.date;
                  if (fechaHoraSeleccionada != null) {
                    Navigator.pop(context, fechaHoraSeleccionada);
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCarga) async {
    final initialDate = isCarga ? (_fechaCarga ?? DateTime.now()) : (_fechaDescarga ?? DateTime.now());
    final pickedDate = await _showCalendarDialog(
      context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isCarga) {
          _fechaCarga = pickedDate;
          context.read<PedidoProvider>().actualizarDatosTemporales(fechaCarga: pickedDate);
        } else {
          _fechaDescarga = pickedDate;
          context.read<PedidoProvider>().actualizarDatosTemporales(fechaDescarga: pickedDate);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cargador', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.titleText)),
          const SizedBox(height: 8),
          _buildCargadorDropDown(widget.clientes),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 400;
              return isSmall ? _buildDatesColumn(context) : _buildDatesRow(context);
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 24),
          _buildTipoYCantidad(),
          _buildDetalleTipoCarga(),
          const SizedBox(height: 16),
          _buildCargaConFechas(),
        ],
      ),
    );
  }

  Widget _buildDetalleTipoCarga() {
    if (_selectedTipo == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_selectedTipo!.descripcion ?? '', style: AppTextStyles.bodySm),
          const SizedBox(height: 8),
          Text('${_selectedTipo!.precio}€/ud', style: AppTextStyles.bodySm),
          const SizedBox(height: 8),
          Text('Origen: ${_selectedTipo!.origenTexto} - Destino: ${_selectedTipo!.destinoTexto}',
              style: AppTextStyles.bodySm),
        ],
      ),
    );
  }

  Widget _buildCargaConFechas() {
    final pedidoProvider = context.watch<PedidoProvider>();
    final seleccion = pedidoProvider.cargasDelPedido;

    if (seleccion == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(seleccion.cantidad, (index) {
        final asig = seleccion.asignaciones[index];
        final fCarga = asig.fechaCarga ?? _fechaCarga ?? DateTime.now();
        final fDescarga = asig.fechaLimite ?? _fechaDescarga ?? DateTime.now();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${seleccion.tipo.nombre} (Unidad ${index + 1})',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.bodyText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Carga', style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedText)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: () async {
                              final pickedDate = await _showCalendarDialog(
                                context,
                                initialDate: fCarga,
                                firstDate: DateTime.now(),
                                lastDate: fDescarga,
                              );
                              if (pickedDate != null) {
                                pedidoProvider.asignarFechaCarga(index, pickedDate);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text(DateFormat('dd/MM HH:mm').format(fCarga), style: AppTextStyles.bodySm)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descarga', style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedText)),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: () async {
                              final pickedDate = await _showCalendarDialog(
                                context,
                                initialDate: fDescarga,
                                firstDate: fCarga,
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                pedidoProvider.asignarFechaLimite(index, pickedDate);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text(DateFormat('dd/MM HH:mm').format(fDescarga), style: AppTextStyles.bodySm)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDatesRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCargaDate(context)),
        const SizedBox(width: 16),
        Expanded(child: _buildDescargaDate(context)),
      ],
    );
  }

  Widget _buildTipoYCantidad() {
    return Row(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: CupertinoColors.extraLightBackgroundGray,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _selectedCliente != null ? _openNuevoTipoCargaDialog : null,
          child: const Text('Añadir', style: AppTextStyles.buttonSmall),
        ),
        _buildTipo(),
        const SizedBox(width: 8),
        _buildCantidadYAccion(),
      ],
    );
  }

  Future<void> _openNuevoTipoCargaDialog() {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: NuevoTipoCarga(cliente: _selectedCliente!),
        );
      },
    );
  }

  Widget _buildTipo() {
    final cargaProvider = context.watch<CargaProvider>();
    return Expanded(
      flex: 2,
      child: DropdownButtonFormField<TipoCargaModel>(
        initialValue: _selectedTipo,
        hint: const Text('Tipo de carga'),
        decoration: _inputDecoration('Tipo de carga'),
        isExpanded: true,
        itemHeight: 56,
        items: cargaProvider.tiposCarga.map((c) => DropdownMenuItem(
          value: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.nombre, style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText), overflow: TextOverflow.ellipsis),
            ],
          ),
        )).toList(),
        onChanged: (v) {
          setState(() {
            _selectedTipo = v;
          });
          context.read<PedidoProvider>().eliminarCarga();
        },
      ),
    );
  }

  Widget _buildCantidadYAccion() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: TextFormField(
            key: ValueKey(_cantidad),
            initialValue: _cantidad.toString(),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Cant.'),
            onChanged: (v) => setState(() => _cantidad = int.tryParse(v) ?? 1),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _selectedTipo != null ? _addCarga : null,
          child: const Text('Añadir', style: AppTextStyles.buttonSmall),
        ),
      ],
    );
  }

  void _addCarga() {
    if (_selectedTipo == null) return;
    context.read<PedidoProvider>().anadirCarga(_selectedTipo!, _cantidad, _fechaCarga, _fechaDescarga);
    setState(() {
      _selectedTipo = null;
      _cantidad = 1;
    });
  }

  Widget _buildCargadorDropDown(List<ExternalUserModel> clientes) {
    final user = context.watch<AuthProvider>().externalUser;
    final isCargador = user?.rol.contains('cliente') ?? false;

    if (isCargador) {
      return TextFormField(
        initialValue: user?.nombre,
        enabled: false,
        decoration: _inputDecoration(''),
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText),
      );
    }

    ExternalUserModel? valueToShow;
    if (_selectedCliente != null) {
      try {
        valueToShow = widget.clientes.firstWhere((c) => c.uid == _selectedCliente!.uid);
      } catch (_) {
        valueToShow = null;
      }
    }

    return DropdownButtonFormField<ExternalUserModel>(
      initialValue: valueToShow,
      decoration: _inputDecoration('Seleccionar cargador...'),
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText),
      items: widget.clientes.map((cliente) {
        return DropdownMenuItem(
          value: cliente,
          child: Text(cliente.nombre, style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText)),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedCliente = val);
        if (val != null) {
          context.read<CargaProvider>().fetchTiposCarga(val.uid);
          context.read<PedidoProvider>().actualizarDatosTemporales(cliente: val);
        }
      },
      validator: (value) => value == null ? 'Requerido' : null,
    );
  }

  Widget _buildDatesColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCargaDate(context),
        const SizedBox(height: 16),
        _buildDescargaDate(context),
      ],
    );
  }

  Widget _buildCargaDate(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha de carga', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.titleText)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, true),
          child: Text(
            _fechaCarga == null ? 'dd/mm/aaaa --:--' : DateFormat('dd/MM/yyyy HH:mm').format(_fechaCarga!),
            style: AppTextStyles.bodyMd.copyWith(color: _fechaCarga != null ? AppColors.bodyText : AppColors.mutedText),
          ),
        ),
      ],
    );
  }
  Widget _buildDescargaDate(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha límite descarga', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.titleText)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, false),
          child: Text(
            _fechaDescarga == null ? 'dd/mm/aaaa --:--' : DateFormat('dd/MM/yyyy HH:mm').format(_fechaDescarga!),
            style: AppTextStyles.bodyMd.copyWith(color: _fechaDescarga != null ? AppColors.bodyText : AppColors.mutedText),
          ),
        ),
      ],
    );
  }
}
