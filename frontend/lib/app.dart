import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/token_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/cargas/providers/pedido_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/cargas/providers/carga_provider.dart';
import 'features/transportistas/providers/transportista_provider.dart';
import 'features/vehiculos/providers/vehiculo_provider.dart';
import 'flavors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ProxyProvider<AuthService, AuthTokenProvider>(
          update: (_, authService, __) => AuthTokenProvider(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(authService: context.read<AuthService>()),
          update: (_, authService, previous) => previous ?? AuthProvider(authService: authService),
        ),
        ChangeNotifierProxyProvider<AuthTokenProvider, DashboardProvider>(
          create: (context) => DashboardProvider(tokenProvider: context.read<AuthTokenProvider>()),
          update: (_, tokenProvider, previous) => previous ?? DashboardProvider(tokenProvider: tokenProvider),
        ),
        ChangeNotifierProxyProvider<AuthTokenProvider, PedidoProvider>(
          create: (context) => PedidoProvider(tokenProvider: context.read<AuthTokenProvider>()),
          update: (_, tokenProvider, previous) => previous ?? PedidoProvider(tokenProvider: tokenProvider),
        ),
        ChangeNotifierProxyProvider<AuthTokenProvider, CargaProvider>(
          create: (context) => CargaProvider(tokenProvider: context.read<AuthTokenProvider>()),
          update: (_, tokenProvider, previous) => previous ?? CargaProvider(tokenProvider: tokenProvider),
        ),
        ChangeNotifierProxyProvider<AuthTokenProvider, VehiculoProvider>(
          create: (context) => VehiculoProvider(tokenProvider: context.read<AuthTokenProvider>()),
          update: (_, tokenProvider, previous) => previous ?? VehiculoProvider(tokenProvider: tokenProvider),
        ),
        ChangeNotifierProxyProvider<AuthTokenProvider, TransportistaProvider>(
          create: (context) => TransportistaProvider(tokenProvider: context.read<AuthTokenProvider>()),
          update: (_, tokenProvider, previous) => previous ?? TransportistaProvider(tokenProvider: tokenProvider),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
              title: F.title,
              theme: AppTheme.light,
              routerConfig: AppRouter.router(authProvider),
              builder: (context, child) {
                if (child == null) {
                  return const SizedBox.shrink();
                }
                return ResponsiveBreakpoints.builder(
                  child: child,
                  breakpoints: const [
                    Breakpoint(start: 0, end: 599, name: MOBILE),
                    Breakpoint(start: 600, end: 1023, name: TABLET),
                    Breakpoint(start: 1024, end: 1920, name: DESKTOP),
                    Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                  ],
                );
              },
          );
        },
      ),
    );
  }
}
