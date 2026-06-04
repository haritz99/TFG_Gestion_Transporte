import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../auth/ui/shared_register.dart';

class DatosClienteForm extends StatefulWidget {
  final TextEditingController nombreController;
  final TextEditingController nifController;
  final SharedRegisterControllers direccionControllers;

  const DatosClienteForm({
    super.key,
    required this.nombreController,
    required this.nifController,
    required this.direccionControllers,
  });

  @override
  State<DatosClienteForm> createState() => DatosClienteFormState();
}

class DatosClienteFormState extends State<DatosClienteForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Introduce los datos de la empresa destinataria.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.bodyText),
          ),
          const SizedBox(height: 24),
          RegisterInputField(
            label: 'Razón Social / Nombre',
            hint: 'Ej. Empresa Destinataria S,L',
            controller: widget.nombreController,
          ),
          const SizedBox(height: 16),
          RegisterInputField(
            label: 'NIF / CIF',
            hint: 'Ej. B80000000',
            controller: widget.nifController,
          ),
          const SizedBox(height: 16),
          DireccionFormSection(shared: widget.direccionControllers),
        ],
      ),
    );
  }
}
