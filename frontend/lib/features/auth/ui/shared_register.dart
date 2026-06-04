import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/theme/app_text_styles.dart';
import 'package:gestion_transporte/core/models/direccion_model.dart';

/// 1. CLASE PARA LOS CONTROLADORES COMPARTIDOS
class SharedRegisterControllers {
  final nombreComercial = TextEditingController();
  final nif = TextEditingController();
  final telefono = TextEditingController();
  final calle = TextEditingController();
  final ciudad = TextEditingController();
  final provincia = TextEditingController();
  final codigoPostal = TextEditingController();
  final pais = TextEditingController(text: 'España');

  void dispose() {
    nombreComercial.dispose();
    nif.dispose();
    telefono.dispose();
    calle.dispose();
    ciudad.dispose();
    provincia.dispose();
    codigoPostal.dispose();
    pais.dispose();
  }

  DireccionModel getDireccionModel() {
    return DireccionModel(
      calle: calle.text.trim(),
      ciudad: ciudad.text.trim(),
      provincia: provincia.text.trim(),
      codigoPostal: codigoPostal.text.trim(),
      pais: pais.text.trim().isEmpty ? 'España' : pais.text.trim(),
    );
  }
}

class RegisterInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;

  const RegisterInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: isRequired ? (v) => v!.trim().isEmpty ? 'Campo requerido' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            //prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}

class DireccionFormSection extends StatelessWidget {
  final SharedRegisterControllers shared;

  const DireccionFormSection({super.key, required this.shared});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dirección', style: AppTextStyles.headingMd),
        const SizedBox(height: 16),
        RegisterInputField(label: 'Calle y número', hint: 'Dirección completa', controller: shared.calle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: RegisterInputField(label: 'Ciudad', hint: 'Ciudad', controller: shared.ciudad)),
            const SizedBox(width: 16),
            Expanded(child: RegisterInputField(label: 'Código Postal', hint: '00000', controller: shared.codigoPostal)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: RegisterInputField(label: 'Provincia', hint: 'Provincia', controller: shared.provincia)),
            const SizedBox(width: 16),
            Expanded(child: RegisterInputField(label: 'País', hint: 'España', controller: shared.pais)),
          ],
        ),
      ],
    );
  }
}