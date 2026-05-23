import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gestion_transporte/core/services/connectivity_service.dart';
import 'package:gestion_transporte/core/providers/connectivity_provider.dart';

import 'connectivity_provider_test.mocks.dart';

@GenerateMocks([ConnectivityService])
void main() {
  late MockConnectivityService mockConnectivityService;

  setUp(() {
    mockConnectivityService = MockConnectivityService();
  });

  group('ConnectivityProvider', () {
    test('inicializa con conexión activa cuando hasConnection() retorna true', () async {
      when(mockConnectivityService.hasConnection()).thenAnswer((_) async => true);
      when(mockConnectivityService.connectionStatusStream).thenAnswer(
        (_) => const Stream.empty(),
      );

      final provider = ConnectivityProvider(connectivityService: mockConnectivityService);

      // Espera a que se inicialice
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isConnected, true);
    });

    test('inicializa sin conexión cuando hasConnection() retorna false', () async {
      when(mockConnectivityService.hasConnection()).thenAnswer((_) async => false);
      when(mockConnectivityService.connectionStatusStream).thenAnswer(
        (_) => const Stream.empty(),
      );

      final provider = ConnectivityProvider(connectivityService: mockConnectivityService);

      // Espera a que se inicialice
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isConnected, false);
    });

    test('reacciona a cambios en la conexión', () async {
      when(mockConnectivityService.hasConnection()).thenAnswer((_) async => true);
      when(mockConnectivityService.connectionStatusStream).thenAnswer(
        (_) => Stream.value(false), // Emite desconexión
      );

      final provider = ConnectivityProvider(connectivityService: mockConnectivityService);

      // Espera a que se procese el stream
      await Future.delayed(const Duration(milliseconds: 200));

      // Después de recibir el evento del stream, el estado debe ser false
      expect(provider.isConnected, false);
    });

    test('getter isConnected retorna el estado correcto', () async {
      when(mockConnectivityService.hasConnection()).thenAnswer((_) async => true);
      when(mockConnectivityService.connectionStatusStream).thenAnswer(
        (_) => const Stream.empty(),
      );

      final provider = ConnectivityProvider(connectivityService: mockConnectivityService);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isConnected, isA<bool>());
      expect(provider.isConnected, true);
    });

    test('notifica listeners cuando la conexión cambia', () async {
      when(mockConnectivityService.hasConnection()).thenAnswer((_) async => true);
      when(mockConnectivityService.connectionStatusStream).thenAnswer(
        (_) => Stream.value(false),
      );

      final provider = ConnectivityProvider(connectivityService: mockConnectivityService);
      var callCount = 0;

      provider.addListener(() {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      expect(callCount, greaterThan(0));
    });
  });
}



