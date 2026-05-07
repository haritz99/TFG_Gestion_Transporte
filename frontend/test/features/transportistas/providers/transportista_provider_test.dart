import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/features/auth/providers/token_provider.dart';
import 'package:gestion_transporte/core/models/paginated_response.dart';
import 'package:gestion_transporte/features/auth/services/auth_service.dart';
import 'package:gestion_transporte/features/transportistas/data/transportista_service.dart';
import 'package:gestion_transporte/features/transportistas/providers/transportista_provider.dart';

import 'transportista_provider_test.mocks.dart';

@GenerateMocks([AuthService, TransportistaService])
void main() {
  late MockAuthService mockAuthService;
  late MockTransportistaService mockService;
  late TransportistaProvider provider;
  late AuthTokenProvider tokenProvider;

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
    estado: 'Sin Asignar',
  );

  setUp(() {
    mockAuthService = MockAuthService();
    mockService = MockTransportistaService();
    tokenProvider = AuthTokenProvider(mockAuthService);
    provider = TransportistaProvider(tokenProvider: tokenProvider, service: mockService);
  });

  group('TransportistaProvider.loadNextPage', () {
    test('devuelve lista y actualiza cache local', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.fetchTransportistas(
        token: token,
        limit: anyNamed('limit'),
        lastDocId: anyNamed('lastDocId'),
      )).thenAnswer((_) async => PaginatedResponse(items: [tUser], hasMore: false, lastDocId: 'u1'));

      await provider.loadNextPage(reset: true);

      expect(provider.transportistas.length, 1);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoadingPage, false);
    });

    test('captura error si no hay token', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => null);
      when(mockAuthService.getIdToken(forceRefresh: true)).thenAnswer((_) async => null);

      await provider.loadNextPage(reset: true);

      expect(provider.transportistas, isEmpty);
      expect(provider.errorMessage, contains('No se pudo obtener un token valido'));
      expect(provider.isLoadingPage, false);
    });
  });

  group('TransportistaProvider.createTransportista', () {
    test('crea transportista correctamente', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.createTransportista(
        token: token,
        userData: anyNamed('userData'),
      )).thenAnswer((_) async => {
            'user': {
              'uid': 'u1',
              'nombre': 'Juan',
              'apellido': 'Perez',
              'email': 'juan@empresa.com',
              'telefono': '+34600111222',
              'rol': ['transportista'],
              'permisosCond': ['C'],
              'companyId': 'empresa_123',
              'estado': 'Sin Asignar',
            },
            'temp_password': 'Temp123!',
            'password_reset_link': 'https://reset.example/link',
          });

      final created = await provider.createTransportista(
        nombre: 'Juan',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        permisosCond: ['C'],
      );

      expect(created, isNotNull);
      expect(provider.createResponse, isNotNull);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('devuelve null y captura error si falla create', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);
      when(mockService.createTransportista(
        token: token,
        userData: anyNamed('userData'),
      )).thenThrow(Exception('Email ya existe'));

      final created = await provider.createTransportista(
        nombre: 'Juan',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        permisosCond: ['C'],
      );

      expect(created, isNull);
      expect(provider.errorMessage, contains('Email ya existe'));
      expect(provider.isLoading, false);
    });
  });

  group('TransportistaProvider.update/delete', () {
    test('update lanza error y captura mensaje si falla el servicio', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);

      // Mock inicial para tener transportista en la lista
      when(mockService.fetchTransportistas(
        token: token,
        limit: anyNamed('limit'),
        lastDocId: anyNamed('lastDocId'),
      )).thenAnswer((_) async => PaginatedResponse(items: [tUser], hasMore: false, lastDocId: 'u1'));
      await provider.loadNextPage(reset: true);

      when(mockService.updateTransportista(
        uid: 'u1',
        token: token,
        userData: anyNamed('userData'),
      )).thenThrow(Exception('No autorizado'));

      final updated = await provider.updateTransportista(
        uid: 'u1',
        nombre: 'Juan Carlos',
        apellido: 'Perez',
        email: 'juan@empresa.com',
        telefono: '+34600111222',
        rol: ['transportista'],
        permisosCond: ['C', 'C+E'],
        estado: 'Sin Asignar',
      );

      expect(updated, isNull);
      expect(provider.errorMessage, contains('No autorizado'));
      expect(provider.transportistas.first.nombre, 'Juan');
      expect(provider.isLoading, false);
    });

    test('delete devuelve false y mantiene lista si falla el servicio', () async {
      when(mockAuthService.getIdToken(forceRefresh: false)).thenAnswer((_) async => token);

      when(mockService.fetchTransportistas(
        token: token,
        limit: anyNamed('limit'),
        lastDocId: anyNamed('lastDocId'),
      )).thenAnswer((_) async => PaginatedResponse(items: [tUser], hasMore: false, lastDocId: 'u1'));
      await provider.loadNextPage(reset: true);

      when(mockService.deleteTransportista(uid: 'u1', token: token)).thenThrow(Exception('Error backend'));

      final ok = await provider.deleteTransportista('u1');

      expect(ok, false);
      expect(provider.errorMessage, contains('Error backend'));
      expect(provider.transportistas.length, 1);
      expect(provider.isLoading, false);
    });

    test('sendCredentialsEmail devuelve false si no hay respuesta previa', () async {
      final ok = await provider.sendCredentialsEmail();

      expect(ok, false);
      expect(provider.errorMessage, 'No hay credenciales para enviar.');
    });
  });
}
