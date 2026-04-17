/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_provider.dart';
import '../../transportistas/ui/insert_transportista_form.dart';
import '../../auth/ui/login_page.dart';

class EncargadoHomeScreen extends StatefulWidget {
  const EncargadoHomeScreen({super.key});

  @override
  State<EncargadoHomeScreen> createState() => _EncargadoHomeScreenState();
}

class _EncargadoHomeScreenState extends State<EncargadoHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final nombre = authProvider.user?.nombre ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $nombre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GestionarTransportistas(),
                  ),
                );
              },
              icon: const Icon(Icons.groups),
              label: const Text('Gestionar Equipo'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
