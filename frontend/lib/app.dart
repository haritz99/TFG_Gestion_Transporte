import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/connectivity_service.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/auth/providers/token_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/cargas/providers/pedido_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/providers/invite_provider.dart';
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
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (context) => ConnectivityProvider(
            connectivityService: context.read<ConnectivityService>(),
          ),
        ),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AuthTokenProvider>(
          create: (context) => AuthTokenProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider<CargaProvider>(
          create: (context) => CargaProvider(tokenProvider: context.read<AuthTokenProvider>()),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(
            tokenProvider: context.read<AuthTokenProvider>(),
            cargaProvider: context.read<CargaProvider>(),
          ),
        ),
        ChangeNotifierProvider<PedidoProvider>(
          create: (context) => PedidoProvider(tokenProvider: context.read<AuthTokenProvider>()),
        ),
        ChangeNotifierProvider<VehiculoProvider>(
          create: (context) => VehiculoProvider(tokenProvider: context.read<AuthTokenProvider>()),
        ),
        ChangeNotifierProvider<TransportistaProvider>(
          create: (context) => TransportistaProvider(tokenProvider: context.read<AuthTokenProvider>()),
        ),
        ChangeNotifierProvider<InviteProvider>(
          create: (context) => InviteProvider(tokenProvider: context.read<AuthTokenProvider>()),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: F.title,
            theme: AppTheme.light,
            routerConfig: AppRouter.router(authProvider),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', ''),
            ],
            locale: const Locale('es', ''),
            builder: (context, child) {
              if (child == null) {
                return const SizedBox.shrink();
              }
              return ConnectivityBanner(
                child: ResponsiveBreakpoints.builder(
                  child: child,
                  breakpoints: const [
                    Breakpoint(start: 0, end: 599, name: MOBILE),
                    Breakpoint(start: 600, end: 1023, name: TABLET),
                    Breakpoint(start: 1024, end: 1920, name: DESKTOP),
                    Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
