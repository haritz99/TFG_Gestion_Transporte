import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio global para detectar cambios de conectividad de red.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream que emite cambios en la conectividad.
  /// Emite `true` cuando hay conexión, `false` cuando no.
  Stream<bool> get connectionStatusStream {
    return _connectivity.onConnectivityChanged.map(
      (List<ConnectivityResult> results) {
        return results.isNotEmpty &&
               !results.contains(ConnectivityResult.none);
      },
    ).distinct();
  }

  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

