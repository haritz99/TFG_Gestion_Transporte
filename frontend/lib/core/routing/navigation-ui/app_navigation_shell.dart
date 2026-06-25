import 'package:flutter/material.dart';
import 'package:gestion_transporte/core/routing/navigation-ui/sidebar_item.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../features/auth/providers/auth_provider.dart';
import 'app_sidebar.dart';

enum RolNavegacion { encargado, conductor }
class AppNavigationShell extends StatelessWidget {
  // Esta clase funciona como componente principal que construye la barra de navegación y el contenido de la página
  final Widget child;
  final RolNavegacion rol;

  const AppNavigationShell({super.key, required this.child, this.rol = RolNavegacion.encargado,});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isMobile = ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET);
    final nombreEmpresa = context.read<AuthProvider>().company!.nombre;

    final List<SidebarItem> navItems = rol == RolNavegacion.conductor ? getConductorNavItems(location) : getEncargadoNavItems(location);
    if (isMobile) {
      // En movil se usa un Drawer
      return Scaffold(
        appBar: AppBar(
          title: Text(nombreEmpresa, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        drawer: Drawer(child: AppSidebar(navItems: navItems)),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(navItems: navItems),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  static List<SidebarItem> getEncargadoNavItems(String location) {
    return [
      SidebarItem(title: 'Panel de Control', icon: Icons.grid_view_rounded, route: '/panel', isSelected: location == '/panel'),
      SidebarItem(title: 'Planificación', icon: Icons.calendar_today_rounded, route: '/planificacion', isSelected: location == '/planificacion'),
      SidebarItem(title: 'Gestión de Flota', icon: Icons.local_shipping_outlined, route: '/flota', isSelected: location == '/flota'),
      SidebarItem(title: 'Gestión de Equipo', icon: Icons.people_outline, route: '/equipo', isSelected: location == '/equipo'),
    ];
  }

  static List<SidebarItem> getConductorNavItems(String location) {
    return [
      SidebarItem(title: 'Hoja de ruta', icon: Icons.dashboard, route: '/hoja_ruta', isSelected: location == '/hoja_ruta'),
      SidebarItem(title: 'Cartas de porte', icon: Icons.list_alt_sharp, route: '/cartas_porte', isSelected: location == '/cartas_porte'),
    ];
  }


}
