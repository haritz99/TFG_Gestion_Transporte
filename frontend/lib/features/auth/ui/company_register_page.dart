import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/auth/ui/shared_register.dart';

class CompanyRegisterPage extends StatelessWidget{
  final SharedRegisterControllers shared;
  final TextEditingController razonSocialCtr;
  final TextEditingController numAutorizacionCtr;
  const CompanyRegisterPage({
    super.key,
    required this.shared,
    required this.razonSocialCtr,
    required this.numAutorizacionCtr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RegisterInputField(label: 'Nombre Comercial', hint: 'Nombre Comercial', icon: Icons.local_shipping_outlined, controller: shared.nombreComercial),
        const SizedBox(height: 16),

        RegisterInputField(label: 'Razón Social', hint: 'Ej. Trans S.L. (si aplica)', icon: Icons.business, controller: razonSocialCtr, isRequired: false),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: RegisterInputField(label: 'NIF', hint: '12345678Z', icon: Icons.badge_outlined, controller: shared.nif)),
            const SizedBox(width: 16),
            Expanded(child: RegisterInputField(label: 'Teléfono', hint: '+34 600...', icon: Icons.phone_outlined, controller: shared.telefono)),
          ],
        ),
        const SizedBox(height: 16),

        RegisterInputField(label: 'Nº Autorización (LOTT)', hint: 'Obligatorio', icon: Icons.verified_user_outlined, controller: numAutorizacionCtr),
        const SizedBox(height: 32),

        DireccionFormSection(shared: shared),
      ]
    );
  }
}