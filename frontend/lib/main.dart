import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gestion_transporte/secrets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'flavors.dart';
import 'firebase.dart';

Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();

  //String? syncfusionKey = Secrets.syncfusionKey;
  //SyncfusionLicenseRegister.registerLicense(syncfusionKey);

  const String flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  F.appFlavor = Flavor.values.firstWhere(
        (element) => element.name.toLowerCase() == flavorString.toLowerCase(),
    orElse: () => Flavor.dev, // Si no hay coincidencias, evita el error 'Bad state'
  );
  await initializeFirebaseApp();
  await initializeDateFormatting('es', null);
  runApp(const App());
}
