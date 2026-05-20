import 'package:flutter/material.dart';
import 'package:gestion_transporte/features/auth/ui/subcontratado_register_page.dart';
import 'package:gestion_transporte/features/home/ui/cargador_home_screen.dart';
import 'package:gestion_transporte/features/transportistas/ui/gestionar_equipo_screen.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/ui/cliente_register_page.dart';
import '../../features/dashboard/ui/dashboard_page.dart';
import '../../features/plan/ui/plan_page.dart';
import '../../features/vehiculos/ui/gestion_flota_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/plan/providers/planificacion_provider.dart';
import 'package:provider/provider.dart';
import 'navigation-ui/app_navigation_shell.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static Page<void> fadeTransitionPage(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  static GoRouter router(AuthProvider authProvider) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      if (authProvider.isLoading) return null;
      final bool isAuthenticated = authProvider.isAuthenticated;
      final bool isLoggingIn = state.matchedLocation == '/login';
      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      final user = authProvider.user;
      final externalUser = authProvider.externalUser;


      if (user == null && externalUser == null) {
        return isLoggingIn ? null : '/login';
      }

      // Lógica para usuario interno
      if (user != null) {
        if (isLoggingIn) {
          if (user.rol.contains('encargado')) {
            return '/panel';
          }
          else if (user.rol.contains('transportista')) {
            return '/panel';  // TODO: Cambiar cuando haya panel propio
          }
        }
      }

      // Lógica para usuario externo
      if (externalUser != null) {
        if (!externalUser.datosCompletos) {
          if (externalUser.rol.contains('cliente') && state.matchedLocation != '/cargador_register') {
            return '/cargador_register';
          } else if (externalUser.rol.contains('subcontratado') && state.matchedLocation != '/subcontratado_register') {
            return '/subcontratado_register';
          }
          return null;
        } else {
          // Si tiene datos completos y está en el login o en el propio registro
          if (isLoggingIn || state.matchedLocation.contains('_register')) {
            if (externalUser.rol.contains('cliente')) {
              return '/cargador_home';
            }
            else if (externalUser.rol.contains('subcontratado')) {
              return '/panel';    // TODO: Cambiar por panel sub
            }
          }
          return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/subcontratado_register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubcontratadoRegisterPage(),
      ),
      GoRoute(
        path: '/cargador_register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClienteRegisterPage(),
      ),
      GoRoute(
        path: '/cargador_home',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CargadorHomeScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/panel',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/planificacion',
            pageBuilder: (context, state) => fadeTransitionPage(
              state,
              ChangeNotifierProvider(
                create: (_) => PlanificacionProvider(),
                child: const PlanificacionScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/flota',
            //builder: (context, state) => const GestionFlotaScreen(),
            pageBuilder: (context, state) => fadeTransitionPage(state, const GestionFlotaScreen()),
          ),
          GoRoute(
            path: '/equipo',
            //builder: (context, state) => const GestionEquipoScreen(),
            pageBuilder: (context, state) => fadeTransitionPage(state, const GestionEquipoScreen()),
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