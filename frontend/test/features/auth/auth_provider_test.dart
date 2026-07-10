import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_transporte/core/models/company_model.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para mockear el User de Firebase
import 'package:gestion_transporte/features/auth/providers/auth_provider.dart' as my_auth;
import 'package:gestion_transporte/features/auth/auth_service.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'auth_provider_test.mocks.dart';


@GenerateMocks([AuthService, User, UserCredential])
void main() {
  late MockAuthService mockAuthService;
  late MockUser mockFirebaseUser;
  late MockUserCredential mockUserCredential;
  late my_auth.AuthProvider authProvider;
  late StreamController<User?> authStateController;
  setUp(() {
    mockAuthService = MockAuthService();
    mockFirebaseUser = MockUser();
    mockUserCredential = MockUserCredential();
    authStateController = StreamController<User?>();

    // Configuramos el stream para que el provider lo escuche
    when(mockAuthService.authStateChanges).thenAnswer((_) => authStateController.stream);

    authProvider = my_auth.AuthProvider(authService: mockAuthService, timeout: const Duration(milliseconds: 1000));
  });

  tearDown(() {
    authStateController.close();
  });

  test('24) signIn lanza TimeoutException si no se hidrata la sesión', () async {
    // Simulamos que el login es exitoso
    when(mockAuthService.signIn(any, any)).thenAnswer((_) async => mockUserCredential);

    // NO emitimos ningún usuario en el stream, por lo que nunca se hidratará

    // falla por timeout
    expect(() => authProvider.signIn('test@test.com', '123456'),
        throwsA(isA<TimeoutException>()));
  });

  test('25) signIn completa correctamente cuando hay token y usuario', () async {
    // Arrange
    when(mockAuthService.signIn(any, any)).thenAnswer((_) async => mockUserCredential);
    when(mockAuthService.getUserData(any)).thenAnswer((_) async => UserModel(
        uid: 'u1', nombre: 'Juan', apellido: 'P', email: 'j@j.com',
        telefono: '123', rol: ['admin'], permisosCond: [], companyId: 'c1'
    ));
    when(mockAuthService.getIdToken()).thenAnswer((_) async => 'fake_token');
    when(mockFirebaseUser.uid).thenReturn('u1');
    when(mockAuthService.guardarFcmToken()).thenAnswer((_) async {});
    when(mockAuthService.getCompanyData(any)).thenAnswer((_) async => CompanyModel(id: '', nombre: ''));

    // Act
    // Lanzamos el login y simulamos que Firebase detecta el usuario
    final future = authProvider.signIn('test@test.com', '123456');
    await Future.delayed(Duration.zero);
    authStateController.add(mockFirebaseUser);

    await future;

    // Assert
    expect(authProvider.isAuthenticated, isTrue);
    expect(authProvider.user?.uid, 'u1');
  });
}