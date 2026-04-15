import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'app_sidebar.dart';

class AppNavigationShell extends StatelessWidget {
  // Esta clase funciona como componente principal que construye la barra de navegación y el contenido de la página
  final Widget child;

  const AppNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);

    if (isMobile) {
      // En movil se usa un Drawer
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nombre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        drawer: const Drawer(
          child: AppSidebar(),
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
