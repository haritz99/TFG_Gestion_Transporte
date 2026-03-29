import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/features/auth/auth_service.dart';
import 'package:gestion_transporte/features/transportistas/data/transportista_service.dart';
import 'package:gestion_transporte/features/transportistas/providers/transportista_provider.dart';

import 'transportista_provider_test.mocks.dart';

@GenerateMocks([AuthService, TransportistaService])
void main() {
  late MockAuthService mockAuthService;
  late MockTransportistaService mockService;
  late TransportistaProvider provider;

  const token = 'test_token';

  final tUser = UserModel(
    uid: 'u1',
    nombre: 'Juan',
    apellido: 'Perez',
    email: 'juan@empresa.com',
    telefono: '+34600111222',
    rol: ['transportista'],
    permisosCond: ['C', 'C+E'],
    companyId: 'empresa_123',
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockService = MockTransportistaService();
    provider = TransportistaProvider(authService: mockAuthService, service: mockService);
  });

  group('TransportistaProvider.fetchTransportistas', () {
    test('devuelve lista y actualiza cache local', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(token: token)).thenAnswer((_) async => [tUser]);

      final result = await provider.fetchTransportistas();

      expect(result.length, 1);
      expect(provider.transportistas.length, 1);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('devuelve vacio con error si no hay token', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => null);
      when(mockAuthService.getIdToken(forceRefresh: true)).thenAnswer((_) async => null);

      final result = await provider.fetchTransportistas();

      expect(result, isEmpty);
      expect(provider.transportistas, isEmpty);
      expect(provider.errorMessage, contains('No se pudo obtener un token valido'));
      expect(provider.isLoading, false);
    });
  });

  group('TransportistaProvider.createTransportista', () {
    test('crea transportista correctamente', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.createTransportista(
        token: token,
        userData: anyNamed('userData'),
      )).thenAnswer((_) async => {
            'uid': 'u1',
            'temp_password': 'Temp123!',
            'password_reset_link': 'https://reset.example/link',
          });

      final ok = await provider.createTransportista(
        nombre: 'Juan',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        permisosCond: ['C'],
      );

      expect(ok, true);
      expect(provider.createResponse, isNotNull);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('devuelve false y error si falla create', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.createTransportista(
        token: token,
        userData: anyNamed('userData'),
      )).thenThrow(Exception('Email ya existe'));

      final ok = await provider.createTransportista(
        nombre: 'Juan',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        permisosCond: ['C'],
      );

      expect(ok, false);
      expect(provider.errorMessage, contains('Email ya existe'));
      expect(provider.createResponse, isNull);
      expect(provider.isLoading, false);
    });

    test('devuelve false si no hay token y no llama al servicio', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => null);
      when(mockAuthService.getIdToken(forceRefresh: true)).thenAnswer((_) async => null);

      final ok = await provider.createTransportista(
        nombre: 'Juan',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        permisosCond: ['C'],
      );

      expect(ok, false);
      expect(provider.errorMessage, contains('No se pudo obtener un token valido'));
      verifyNever(mockService.createTransportista(
        token: anyNamed('token'),
        userData: anyNamed('userData'),
      ));
    });
  });

  group('TransportistaProvider.update/delete/sendCredentialsEmail', () {
    test('update modifica transportista en lista local', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(token: token)).thenAnswer((_) async => [tUser]);
      await provider.fetchTransportistas();

      when(mockService.updateTransportista(
        uid: 'u1',
        token: token,
        userData: anyNamed('userData'),
      )).thenAnswer((_) async => {'message': 'ok'});

      final ok = await provider.updateTransportista(
        uid: 'u1',
        nombre: 'Juan Carlos',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        rol: ['transportista'],
        permisosCond: ['C', 'C+E'],
        vehiculoId: 'VEH-001',
      );

      expect(ok, true);
      expect(provider.transportistas.first.nombre, 'Juan Carlos');
      expect(provider.transportistas.first.vehiculoId, 'VEH-001');
    });

    test('update devuelve false y mantiene lista si falla el servicio', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(token: token)).thenAnswer((_) async => [tUser]);
      await provider.fetchTransportistas();

      when(mockService.updateTransportista(
        uid: 'u1',
        token: token,
        userData: anyNamed('userData'),
      )).thenThrow(Exception('No autorizado'));

      final ok = await provider.updateTransportista(
        uid: 'u1',
        nombre: 'Juan Carlos',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        rol: ['transportista'],
        permisosCond: ['C', 'C+E'],
      );

      expect(ok, false);
      expect(provider.errorMessage, contains('No autorizado'));
      expect(provider.transportistas.first.nombre, 'Juan');
      expect(provider.isLoading, false);
    });

    test('update devuelve true aunque uid no exista en cache local', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(token: token)).thenAnswer((_) async => [tUser]);
      await provider.fetchTransportistas();

      when(mockService.updateTransportista(
        uid: 'u2',
        token: token,
        userData: anyNamed('userData'),
      )).thenAnswer((_) async => {'message': 'ok'});

      final ok = await provider.updateTransportista(
        uid: 'u2',
        nombre: 'Nuevo',
        apellido: 'Apellido',
        email: 'nuevo@empresa.com',
        telefono: '+34600111999',
        rol: ['transportista'],
        permisosCond: ['C'],
      );

      expect(ok, true);
      expect(provider.transportistas.length, 1);
      expect(provider.transportistas.first.uid, 'u1');
    });

    test('delete elimina elemento de lista local', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(token: token)).thenAnswer((_) async => [tUser]);
      await provider.fetchTransportistas();

      when(mockService.deleteTransportista(uid: 'u1', token: token)).thenAnswer((_) async => {'message': 'ok'});

      final ok = await provider.deleteTransportista('u1');

      expect(ok, true);
      expect(provider.transportistas, isEmpty);
    });

    test('delete devuelve false y mantiene lista si falla el servicio', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(token: token)).thenAnswer((_) async => [tUser]);
      await provider.fetchTransportistas();

      when(mockService.deleteTransportista(uid: 'u1', token: token)).thenThrow(Exception('Error backend'));

      final ok = await provider.deleteTransportista('u1');

      expect(ok, false);
      expect(provider.errorMessage, contains('Error backend'));
      expect(provider.transportistas.length, 1);
      expect(provider.isLoading, false);
    });

    test('delete devuelve false si no hay token y no llama al servicio', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => null);
      when(mockAuthService.getIdToken(forceRefresh: true)).thenAnswer((_) async => null);

      final ok = await provider.deleteTransportista('u1');

      expect(ok, false);
      expect(provider.errorMessage, contains('No se pudo obtener un token valido'));
      verifyNever(mockService.deleteTransportista(uid: anyNamed('uid'), token: anyNamed('token')));
    });

    test('sendCredentialsEmail devuelve false si no hay respuesta previa', () async {
      final ok = await provider.sendCredentialsEmail();

      expect(ok, false);
      expect(provider.errorMessage, 'No hay credenciales para enviar.');
    });
  });
}

