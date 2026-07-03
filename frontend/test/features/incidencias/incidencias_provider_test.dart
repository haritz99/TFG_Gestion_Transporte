import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gestion_transporte/core/models/incidencia_model.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/features/auth/providers/auth_provider.dart';
import 'package:gestion_transporte/features/auth/providers/token_provider.dart';
import 'package:gestion_transporte/features/incidencias/incidencia_service.dart';
import 'package:gestion_transporte/features/incidencias/incidencias_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'incidencias_provider_test.mocks.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _user;

  @override
  UserModel? get user => _user;

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@GenerateMocks([IncidenciaService, AuthTokenProvider, AuthProvider])
void main() {
  late MockIncidenciaService mockService;
  late MockAuthTokenProvider mockTokenProvider;
  late FakeFirebaseFirestore fakeFirestore;


  setUp(() {
    mockService = MockIncidenciaService();
    mockTokenProvider = MockAuthTokenProvider();
    fakeFirestore = FakeFirebaseFirestore();
  });

  testWidgets('El IncidenciaProvider se recrea cuando el companyId cambia', (tester) async {
    // 1. Arrange: Mockeamos el AuthProvider
    final fakeAuth = FakeAuthProvider();
    fakeAuth.setUser(UserModel(
      uid: 'u1', nombre: 'Juan', apellido: 'P', email: 'j@j.com',
      telefono: '123', rol: ['admin'], permisosCond: [], companyId: 'comp_1',
    ));

    // Creamos un widget dummy para poder capturar el BuildContext
    late IncidenciaProvider provider1;
    late IncidenciaProvider provider2;

    // 2. Act: Montar el árbol de widgets
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProxyProvider<AuthProvider, IncidenciaProvider>(
            create: (context) => IncidenciaProvider(
              companyId: '',
              tokenProvider: mockTokenProvider,
              firestore: fakeFirestore,
            ),
            update: (context, authProvider, previous) {
              final companyId = authProvider.user?.companyId ?? '';
              if (previous?.companyId == companyId) return previous!;
              return IncidenciaProvider(
                companyId: companyId,
                tokenProvider: mockTokenProvider,
                firestore: fakeFirestore,
              );
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            // Guardamos la referencia de la primera instancia generada
            provider1 = Provider.of<IncidenciaProvider>(context, listen: false);
            return Container();
          },
        ),
      ),
    );

    // 3. Cambiamos el ID en el mock de AuthProvider
    expect(provider1.companyId, 'comp_1');
    fakeAuth.setUser(UserModel(
      uid: 'u1', nombre: 'Juan', apellido: 'P', email: 'j@j.com',
      telefono: '123', rol: ['admin'], permisosCond: [], companyId: 'comp_2',
    ));
    await tester.pump();

    // Volvemos a capturar la instancia actual del provider a través del BuildContext del árbol
    final Element element = tester.element(find.byType(Container));
    provider2 = Provider.of<IncidenciaProvider>(element, listen: false);

    // 4. Assert: Verificamos que ahora es un provider distinto con el nuevo ID
    expect(provider2.companyId, 'comp_2');
    expect(provider1, isNot(provider2)); // Confirmamos que son instancias de memoria distintas
  });

  test('Crear incidencia captura error del servicio', () async {
    final provider = IncidenciaProvider(companyId: 'c1', tokenProvider: mockTokenProvider, service: mockService, firestore: fakeFirestore);

    when(mockService.createIncidencia(cargaId: anyNamed('cargaId'), tipo: anyNamed('tipo'), descripcion: anyNamed('descripcion')))
        .thenThrow(Exception('Servicio caído'));

    final success = await provider.createIncidencia(cargaId: 'c1', tipo: TipoIncidencia.retraso, descripcion: 'test');

    expect(success, isFalse);
    expect(provider.errorMessage, 'Servicio caído');
  });
}