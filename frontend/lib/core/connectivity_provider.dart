import 'package:flutter/foundation.dart';
import 'services/connectivity_service.dart';

/// Provider que notifica a toda la app sobre cambios en la conectividad.
///
/// Mantiene el estado de conexión y emite notificaciones cuando cambia.
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  bool _isConnected = true; // Valor por defecto (asumimos que hay conexión)

  ConnectivityProvider({required ConnectivityService connectivityService})
      : _connectivityService = connectivityService {
    _initializeConnection();
    _listenToConnectionChanges();
  }

  /// Retorna si hay conexión activa.
  bool get isConnected => _isConnected;

  /// Inicializa el estado de conexión.
  Future<void> _initializeConnection() async {
    final hasConnection = await _connectivityService.hasConnection();
    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      notifyListeners();
    }
  }

  /// Escucha cambios en la conectividad y notifica.
  void _listenToConnectionChanges() {
    _connectivityService.connectionStatusStream.listen(
      (bool connected) {
        if (_isConnected != connected) {
          _isConnected = connected;
          notifyListeners();
        }
      },
    );
  }
}


