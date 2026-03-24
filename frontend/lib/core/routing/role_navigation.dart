import 'package:flutter/material.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/home/ui/encargado_home_screen.dart';
import '../../features/home/ui/trans_home_screen.dart';
import '../../pages/login_page.dart';

Widget resolveAppHome(AuthProvider auth) {
  if (!auth.isAuthenticated) {
    return const LoginScreen();
  }

  final user = auth.user;
  if (user == null) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  if (user.rol.contains('transportista')) {
    return const TransportistaHomeScreen();
  }

  return const EncargadoHomeScreen();
}

void navigateToHomeByRole(BuildContext context, AuthProvider auth) {
  if (!auth.isAuthenticated) return;
  final target = resolveAppHome(auth);
  if (target is LoginScreen) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => target),
    (route) => false,
  );
}


