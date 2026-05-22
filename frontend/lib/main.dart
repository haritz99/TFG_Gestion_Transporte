import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'flavors.dart';
import 'firebase.dart';

Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();

  /*
  await dotenv.load(fileName: ".env");
  String? syncfusionKey = dotenv.env['SYNCFUSION_KEY'];
  if (syncfusionKey != null) {
    SyncfusionLicense.registerLicense(syncfusionKey);
  }
  */
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  await initializeFirebaseApp();
  await initializeDateFormatting('es', null);
  runApp(const App());
}
