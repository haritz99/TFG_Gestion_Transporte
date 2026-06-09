import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gestion_transporte/core/config/api_config.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/features/transportistas/data/transportista_service.dart';

import 'transportista_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late TransportistaService transportistaService;
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
    transportistaService = TransportistaService(client: mockHttpClient);
  });

  group('TransportistaService', () {
    const String tToken = 'test_token';
    final String baseUrl = '${ApiConfig.baseUrl}/trans/';
    const String tUid = 'transp_001';

    final tUserModel = UserModel(
      uid: tUid,
      email: 'conductor@empresa.com',
      nombre: 'Juan',
      apellido: 'Pérez',
      rol: ['transportista'],
      telefono: '+34600123456',
      permisosCond: ['C', 'C+E'],
      companyId: 'empresa_123',
    );

    test('createTransportista retorna map con datos si status es 201', () async {
      when(mockHttpClient.post(
        Uri.parse(baseUrl),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'user': {'uid': tUid}
            }),
            201,
          ));

      final result = await transportistaService.createTransportista(
        token: tToken,
        userData: tUserModel,
      );

      expect(result['user']['uid'], tUid);
    });

    test('createTransportista lanza excepcion si falla', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"detail": "Email ya existe"}', 400));

      expect(
        () => transportistaService.createTransportista(token: tToken, userData: tUserModel),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Email ya existe'))),
      );
    });

    test('fetchTransportistas devuelve lista vacia cuando backend responde items vacio', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'items': [], 'has_more': false}),
            200,
          ));

      final result = await transportistaService.fetchTransportistas(token: tToken);

      expect(result.items, isEmpty);
    });

    test('fetchTransportistas lanza excepcion con detail cuando falla', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('{"detail": "Token invalido"}', 401));

      expect(
        () => transportistaService.fetchTransportistas(token: tToken),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Token invalido'))),
      );
    });

    test('createTransportista usa mensaje por defecto si no llega detail', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"error": "bad"}', 400));

      expect(
        () => transportistaService.createTransportista(token: tToken, userData: tUserModel),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Error al crear transportista'),
          ),
        ),
      );
    });

    test('updateTransportista retorna UserModel si status es 200', () async {
      when(mockHttpClient.put(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'uid': tUid,
              'nombre': 'Juan',
              'apellido': 'Pérez',
              'email': 'conductor@empresa.com',
              'telefono': '+34600123456',
              'rol': ['transportista'],
              'permisosCond': ['C'],
              'companyId': 'empresa_123',
              'estado': 'sin_asignar',
            }),
            200,
          ));

      final result = await transportistaService.updateTransportista(
        uid: tUid,
        userData: tUserModel,
        token: tToken,
      );

      expect(result.uid, tUid);
    });

    test('deleteTransportista retorna map si status es 200', () async {
      when(mockHttpClient.delete(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('{"mensaje": "Eliminado"}', 200));

      final result = await transportistaService.deleteTransportista(
        uid: tUid,
        token: tToken,
      );

      expect(result['mensaje'], 'Eliminado');
    });
  });
}
