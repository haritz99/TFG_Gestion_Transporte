import 'package:flutter_dotenv/flutter_dotenv.dart';

class Secrets {
  static String get fcmVapidKey => dotenv.env['VAPID_PUBLIC_KEY'] ?? '';
}