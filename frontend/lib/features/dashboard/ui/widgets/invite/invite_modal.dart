import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../providers/invite_provider.dart';
import './guest_list.dart';

class InviteModal extends StatefulWidget {
  const InviteModal({super.key});

  @override
  State<InviteModal> createState() => _InviteModalState();
}

class _InviteModalState extends State<InviteModal> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _rol = 'cliente';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InviteProvider>().getGuests();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final provider = context.read<InviteProvider>();

      try {
        await provider.createUser(_email, _rol);
        if (provider.isCreated && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Usuario invitado con éxito')
              )
          );
        }
        } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InviteProvider>();
    final isLoading = provider.isLoading;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestionar colaboradores',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.titleText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Invita a nuevos miembros y gestiona los invitados actuales',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    //alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      SizedBox(
                        width: isMobile ? double.infinity : 300,
                        child: TextFormField(
                          initialValue: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'email@empresa.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Introduce el email';
                            final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
                            if (!regex.hasMatch(v)) return 'Email no válido';
                            return null;
                          },
                          onSaved: (value) => _email = value!.trim(),
                          enabled: !isLoading,
                        ),
                      ),
                      DropdownMenu<String>(
                        width: isMobile ? double.infinity : 200,
                        initialSelection: _rol,
                        leadingIcon: const Icon(Icons.person_outline),
                        menuHeight: 300,
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: 'cliente', label: 'Cargador'),
                          DropdownMenuEntry(value: 'subcontratado', label: 'Subcontratado'),
                        ],
                        onSelected: isLoading
                            ? null
                            : (value) {
                          if (value != null) setState(() => _rol = value);
                        },
                      ),
                      SizedBox(
                        width: isMobile ? double.infinity : null,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _submit,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text(
                            'Enviar invitación',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                  const GuestList()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
