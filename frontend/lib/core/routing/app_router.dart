import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/transportistas/ui/gestionar_equipo_screen.dart';
import 'package:go_router/go_router.dart';
import '../../features/vehiculos/ui/gestion_flota_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/ui/login_page.dart';
import 'navigation-ui/app_navigation_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/panel',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final bool isAuthenticated = authProvider.isAuthenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/panel';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/panel',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text("Panel de control (No implementado)")),
            ),
          ),
          GoRoute(
            path: '/flota',
            builder: (context, state) => const GestionFlotaScreen(),
          ),
          GoRoute(
            path: '/equipo',
            builder: (context, state) => const GestionEquipoScreen(),
          ),
          GoRoute(
            path: '/incidencias',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text("Gestión de Incidencias (No implementado)")),
            ),
          ),
        ],
      ),
    ],
  );
}