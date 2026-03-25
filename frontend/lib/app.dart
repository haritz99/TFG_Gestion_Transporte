import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/role_navigation.dart';
import 'features/auth/auth_provider.dart';
import 'flavors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: F.title,
        theme: ThemeData(primarySwatch: Colors.orange),
        home: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            final screen = resolveAppHome(auth);
            return _flavorBanner(child: screen, show: kDebugMode);
          },
        ),
      ),
    );
  }


  Widget _flavorBanner({required Widget child, bool show = true}) => show
      ? Banner(
          location: BannerLocation.topStart,
          message: F.name,
          color: Colors.green.withAlpha(150),
          textStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.0,
            letterSpacing: 1.0,
          ),
          textDirection: TextDirection.ltr,
          child: child,
        )
      : Container(child: child);
}
