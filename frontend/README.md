# gestion_transporte

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## API backend in local development

The app resolves the backend URL automatically:

- Web: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- Real device: use `--dart-define=API_BASE_URL=http://<TU_IP_LAN>:8000`

Examples:

```bash
flutter run -d chrome
flutter run -d emulator-5554
flutter run -d <deviceId> --dart-define=API_BASE_URL=http://192.168.1.34:8000
```

For real devices, your FastAPI server must listen on all interfaces (for example `--host 0.0.0.0`) and the phone must be on the same Wi-Fi network as your computer.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
