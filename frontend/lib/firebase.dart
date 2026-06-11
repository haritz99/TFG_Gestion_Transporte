// firebase.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

const _vapidKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

Future<void> _initFcm() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    debugPrint('FCM: permiso denegado');
    return;
  }

  final token = await messaging.getToken(
    vapidKey: kIsWeb ? _vapidKey : null,
  );
  debugPrint('FCM token: $token');
}