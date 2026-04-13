import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gestion_transporte/core/models/vehiculo_model.dart';
import 'package:gestion_transporte/features/auth/auth_service.dart';
import 'package:gestion_transporte/features/vehiculos/data/vehiculo_service.dart';
import 'package:gestion_transporte/features/vehiculos/providers/vehiculo_provider.dart';

import 'vehiculo_provider_test.mocks.dart';

@GenerateMocks([AuthService, VehiculoService])
void main() {
  late MockAuthService mockAuthService;
  late MockVehiculoService mockService;
  late VehiculoProvider provider;

  const token = 'test_token';

  final tVehiculo = VehiculoModel(
    matricula: '1234ABC',
    marca: 'Scania',
    modelo: 'R450',
    capacidad: 24000,
    largo: 13.6,
    ancho: 2.5,
    alto: 4.0,
    estado: "disponible",
    interno: true,
    transportistaId: null,
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockService = MockVehiculoService();
    provider = VehiculoProvider(authService: mockAuthService, service: mockService);
  });

  group('VehiculoProvider.fetchVehiculos', () {
    test('devuelve vehiculos cuando token y servicio son correctos', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchVehiculos(token: token)).thenAnswer((_) async => [tVehiculo]);

      final result = await provider.fetchVehiculos();

      expect(result.length, 1);
      expect(result.first.marca, 'Scania');
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('devuelve lista vacia y error cuando no hay token', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => null);
      when(mockAuthService.getIdToken(forceRefresh: true)).thenAnswer((_) async => null);

      final result = await provider.fetchVehiculos();

      expect(result, isEmpty);
      expect(provider.errorMessage, contains('No se pudo obtener un token valido'));
      expect(provider.isLoading, false);
    });
  });

  group('VehiculoProvider.asignaVehiculo', () {
    test('llama al service con los parametros correctos', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.asignaVehiculo(
        token: token,
        matricula: '1234ABC',
        transportistaId: 'u1',
      )).thenAnswer((_) async {});

      await provider.asignaVehiculo('1234ABC', 'u1');

      verify(mockService.asignaVehiculo(
        token: token,
        matricula: '1234ABC',
        transportistaId: 'u1',
      )).called(1);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('guarda mensaje de error si falla el service', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.asignaVehiculo(
        token: token,
        matricula: '1234ABC',
        transportistaId: 'u1',
      )).thenThrow(Exception('Vehiculo no encontrado'));

      await provider.asignaVehiculo('1234ABC', 'u1');

      expect(provider.errorMessage, contains('Vehiculo no encontrado'));
      expect(provider.isLoading, false);
    });
  });

  group('VehiculoProvider.insertaVehiculo', () {
    test('inserta vehiculo correctamente', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.insertaVehiculo(token: token, vehiculoData: tVehiculo)).thenAnswer((_) async => tVehiculo);

      await provider.insertaVehiculo(tVehiculo);

      verify(mockService.insertaVehiculo(token: token, vehiculoData: tVehiculo)).called(1);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('usa mensaje generico cuando falla la insercion', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.insertaVehiculo(token: token, vehiculoData: tVehiculo)).thenThrow(Exception('Error backend'));

      await provider.insertaVehiculo(tVehiculo);

      expect(provider.errorMessage, 'Error al insertar vehiculo');
      expect(provider.isLoading, false);
    });
  });
}

