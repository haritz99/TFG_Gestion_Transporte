import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
    const String baseUrl = 'http://127.0.0.1:8000/trans/';
    const String tUid = 'transp_001';

    final tUserModel = UserModel(
      uid: tUid,
      email: 'conductor@empresa.com',
      nombre: 'Juan',
      apellido: 'Pérez',
      rol: ['transportista'],
      telefono: '+34600123456',
      permisosCond: ['C', 'C+E'],
    );

    test('createTransportista retorna map con datos si status es 201', () async {
      when(mockHttpClient.post(
        Uri.parse(baseUrl),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'mensaje': 'Creado con éxito', 'uid': tUid}),
            201,
          ));

      final result = await transportistaService.createTransportista(
        token: tToken,
        userData: tUserModel,
      );

      expect(result['uid'], tUid);
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

    test('fetchTransportistas devuelve lista de UserModel cuando la respuesta es 200', () async {
      when(mockHttpClient.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $tToken'},
      )).thenAnswer((_) async => http.Response(
            jsonEncode([
              {
                "uid": tUid,
                "email": "conductor@empresa.com",
                "nombre": "Juan",
                "apellido": "Pérez",
                "rol": ["transportista"],
                "telefono": "+34600123456",
                "permisosCond": ["C", "C+E"]
              }
            ]),
            200,
          ));

      final result = await transportistaService.fetchTransportistas(token: tToken);

      expect(result, isA<List<UserModel>>());
      expect(result.length, 1);
      expect(result.first.uid, tUid);
      expect(result.first.permisosCond?.contains('C+E'), true);
    });

    test('updateTransportista retorna map si status es 200', () async {
      when(mockHttpClient.put(
        Uri.parse('$baseUrl$tUid'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"mensaje": "Actualizado"}', 200));

      final result = await transportistaService.updateTransportista(
        uid: tUid,
        userData: tUserModel,
        token: tToken,
      );

      expect(result['mensaje'], 'Actualizado');
    });

    test('deleteTransportista retorna map si status es 200', () async {
      when(mockHttpClient.delete(
        Uri.parse('$baseUrl$tUid'),
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
