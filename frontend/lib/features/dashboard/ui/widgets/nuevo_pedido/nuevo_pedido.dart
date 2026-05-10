import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';

class NuevoPedidoForm extends StatefulWidget {
  final List<ExternalUserModel> clientes;
  const NuevoPedidoForm({super.key, required this.clientes});
  @override
  State<NuevoPedidoForm> createState() => NuevoPedidoFormState();
}

class NuevoPedidoFormState extends State<NuevoPedidoForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  ExternalUserModel? _selectedCliente;
  DateTime? _fechaCarga;
  DateTime? _fechaDescarga;

  ExternalUserModel? get selectedCliente => _selectedCliente;
  String get descripcion => _descripcionController.text;
  DateTime? get fechaCarga => _fechaCarga;
  DateTime? get fechaDescarga => _fechaDescarga;

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

  Future<void> _selectDate(BuildContext context, bool isCarga) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isCarga) {
          _fechaCarga = picked;
        } else {
          _fechaDescarga = picked;
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
          Text('Descripción', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.titleText)),
          const SizedBox(height: 3),
          TextFormField(
            controller: _descripcionController,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText),
            validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          Text('Cargador', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.titleText)),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExternalUserModel>(
            initialValue: _selectedCliente,
            decoration: _inputDecoration('Seleccionar cargador...'),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText),
            items: widget.clientes.map((cliente) {
              return DropdownMenuItem(value: cliente, child: Text(cliente.nombre, style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText)));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCliente = val),
            validator: (value) => value == null ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 400;
              return isSmall ? _buildDatesColumn(context) : _buildDatesRow(context);
            },
          ),
        ],
      ),
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
            _fechaCarga == null ? 'dd/mm/aaaa' : DateFormat('dd/MM/yyyy').format(_fechaCarga!),
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
            _fechaDescarga == null ? 'dd/mm/aaaa' : DateFormat('dd/MM/yyyy').format(_fechaDescarga!),
            style: AppTextStyles.bodyMd.copyWith(color: _fechaDescarga != null ? AppColors.bodyText : AppColors.mutedText),
          ),
        ),
      ],
    );
  }
}
