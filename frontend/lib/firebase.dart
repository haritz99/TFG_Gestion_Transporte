// firebase.dart
import 'package:firebase_core/firebase_core.dart';
import 'flavors.dart';
import 'package:gestion_transporte/firebase_options_prod.dart' as prod;
import 'package:gestion_transporte/firebase_options_staging.dart' as stg;
import 'package:gestion_transporte/firebase_options_dev.dart' as dev;
import 'package:flutter/foundation.dart';

Future<FirebaseApp> initializeFirebaseApp() async {
  final firebaseOptions = switch (F.appFlavor) {
    Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
    Flavor.staging => stg.DefaultFirebaseOptions.currentPlatform,
    Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
  };

  final app = await Firebase.initializeApp(options: firebaseOptions);
  debugPrint('Firebase init OK -> app name: ${app.name}, projectId: ${app.options.projectId}');
  return app;

}