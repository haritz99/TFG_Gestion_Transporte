import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gestion_transporte/core/config/api_config.dart';
import 'package:gestion_transporte/core/models/vehiculo_model.dart';
import 'package:gestion_transporte/features/vehiculos/data/vehiculo_service.dart';

import 'vehiculo_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late VehiculoService vehiculoService;
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
    vehiculoService = VehiculoService(client: mockHttpClient);
  });

  group('VehiculoService', () {
    const String tToken = 'test_token';
    final baseUrl = '${ApiConfig.baseUrl}/vehi/';

    final tVehiculoModel = VehiculoModel(
        id: '1234ABC',
        matricula: '1234ABC',
        marca: 'Scania',
        modelo: 'R450',
        capacidad: 24000,
        largo: 13.6,
        ancho: 2.5,
        alto: 4.0,
        disponible: true,
        interno: true,
      );

    test('fetchVehiculos devuelve lista de VehiculoModel cuando la respuesta es 200', () async {
      when(mockHttpClient.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $tToken'},
      )).thenAnswer((_) async => http.Response(
            jsonEncode([
              {
                "matricula": "1234ABC",
                "marca": "Scania",
                "modelo": "R450",
                "capacidad": 24000,
                "largo": 13.6,
                "ancho": 2.5,
                "alto": 4.0,
                "disponible": true,
                "interno": true
              }
            ]),
            200,
          ));

      final result = await vehiculoService.fetchVehiculos(token: tToken);

      expect(result, isA<List<VehiculoModel>>());
      expect(result.length, 1);
      expect(result.first.matricula, '1234ABC');
      expect(result.first.marca, 'Scania');
      expect(result.first.capacidad, 24000);
    });

    test('fetchVehiculos lanza excepción cuando falla con 400', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('{"detail": "Error de token"}', 400));

      expect(() => vehiculoService.fetchVehiculos(token: tToken),
          throwsException);
    });

    test('asignaVehiculo completa correctamente si status es 200', () async {
      when(mockHttpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/vehi/assign'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"mensaje": "Asignado"}', 200));

      expect(
        vehiculoService.asignaVehiculo(
          token: tToken,
          matricula: '1234ABC',
          transportistaId: 'transp123',
        ),
        completes,
      );
    });

    test('asignaVehiculo lanza excepcion si status es 404', () async {
      when(mockHttpClient.patch(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"detail": "Vehículo no encontrado"}', 404));

      expect(
        () => vehiculoService.asignaVehiculo(
          token: tToken,
          matricula: '1234ABC',
          transportistaId: 'transp123',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Vehículo no encontrado'))),
      );
    });

    test('insertaVehiculo retorna VehiculoModel si status es 201', () async {
      when(mockHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/vehi/'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode(tVehiculoModel.toMap()..addAll({'matricula': '1234ABC'})),
            201,
          ));

      final result = await vehiculoService.insertaVehiculo(token: tToken, vehiculoData: tVehiculoModel);

      expect(result.matricula, '1234ABC');
      expect(result.marca, 'Scania');
      expect(result.capacidad, 24000);
    });

    test('insertaVehiculo lanza excepcion si status es 500', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"detail": "Error interno"}', 500));

      expect(
        () => vehiculoService.insertaVehiculo(token: tToken, vehiculoData: tVehiculoModel),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Error interno'))),
      );
    });
  });
}
