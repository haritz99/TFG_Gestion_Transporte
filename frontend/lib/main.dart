import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'flavors.dart';
import 'firebase.dart';

Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();


  await dotenv.load(fileName: ".env");
  /*
  String? syncfusionKey = dotenv.env['SYNCFUSION_KEY'];
  if (syncfusionKey != null) {
    SyncfusionLicense.registerLicense(syncfusionKey);
  }
  */
  const String flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  F.appFlavor = Flavor.values.firstWhere(
        (element) => element.name.toLowerCase() == flavorString.toLowerCase(),
    orElse: () => Flavor.dev, // Si no hay coincidencias, evita el error 'Bad state'
  );
  await initializeFirebaseApp();
  await initializeDateFormatting('es', null);
  runApp(const App());
}
