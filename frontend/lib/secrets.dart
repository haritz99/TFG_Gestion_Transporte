class Secrets {
  static const String fcmVapidKey = String.fromEnvironment('VAPID_PUBLIC_KEY', defaultValue: '');
  static const String syncfusionKey = String.fromEnvironment('SYNCFUSION_LICENSE_KEY', defaultValue: '');
}