import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_core/core.dart';

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
  runApp(const App());
}
