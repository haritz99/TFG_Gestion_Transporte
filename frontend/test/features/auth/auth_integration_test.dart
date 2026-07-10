import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_transporte/features/auth/providers/auth_provider.dart'
as my_auth;
import 'package:gestion_transporte/features/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_integration_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Integración: flujo de auth real', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late AuthService authService;
    late my_auth.AuthProvider authProvider;
    late FakeFirebaseFirestore fakeFirestore;
    late MockClient mockHttpClient;

    setUp(() async {
      final mockUser = MockUser(
        uid: 'u1',
        email: 'test@test.com',
        displayName: 'Juan',
      );

      mockFirebaseAuth = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: false,
      );

      fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('users').doc('u1').set({
        'uid': 'u1',
        'nombre': 'Juan',
        'apellido': 'P',
        'email': 'test@test.com',
        'telefono': '123',
        'rol': ['admin'],
        'permisosCond': [],
        'companyId': 'c1',
      });

      mockHttpClient = MockClient();

      when(
        mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        ),
      ).thenAnswer(
            (_) async => http.Response(
          jsonEncode({
            'id': 'c1',
            'nombre': 'Empresa Test',
          }),
          200,
        ),
      );

      authService = AuthService(
        firebaseAuth: mockFirebaseAuth,
        firestore: fakeFirestore,
        client: mockHttpClient,
      );

      authProvider = my_auth.AuthProvider(
        authService: authService,
      );
    });

    test('authStateChanges actualiza AuthProvider al hacer login',
            () async {
          expect(authProvider.isAuthenticated, false);
          expect(authProvider.user, isNull);

          await mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@test.com',
            password: '123456',
          );

          await Future.delayed(
            const Duration(milliseconds: 100),
          );

          expect(authProvider.isAuthenticated, true);
          expect(authProvider.user, isNotNull);
          expect(authProvider.user!.uid, 'u1');
        });

    test('authStateChanges actualiza AuthProvider al hacer logout',
            () async {
          await mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@test.com',
            password: '123456',
          );

          await Future.delayed(
            const Duration(milliseconds: 100),
          );

          expect(authProvider.isAuthenticated, true);

          await mockFirebaseAuth.signOut();

          await Future.delayed(
            const Duration(milliseconds: 100),
          );

          expect(authProvider.isAuthenticated, false);
          expect(authProvider.user, isNull);
        });
  });
}