import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Ajusta estos imports a las rutas reales de tu proyecto
import 'package:gestion_transporte/features/cargas/providers/carga_provider.dart';
import 'package:gestion_transporte/features/cargas/data/carga_service.dart';
import 'package:gestion_transporte/features/auth/providers/token_provider.dart';
import 'package:gestion_transporte/core/models/carga_model.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:gestion_transporte/core/models/vehiculo_model.dart';
import 'package:gestion_transporte/core/models/direccion_model.dart';

// Importamos el archivo que generará build_runner (dará error hasta que ejecutes el comando)
import 'carga_provider_test.mocks.dart';

// 1. Le decimos a Mockito qué clases debe generar
@GenerateMocks([CargaService, AuthTokenProvider])
void main() {
  late MockCargaService mockCargaService;
  late MockAuthTokenProvider mockAuthTokenProvider;
  late CargaProvider provider;

  final ubicacion = UbicacionModel(
    direccion: DireccionModel(calle: 'C', ciudad: 'X', provincia: 'P', codigoPostal: '0000'),
    lat: 0,
    lng: 0,
  );

  setUp(() {
    // Instanciamos las clases generadas automáticamente por Mockito
    mockCargaService = MockCargaService();
    mockAuthTokenProvider = MockAuthTokenProvider();

    // Inyección limpia de dependencias
    provider = CargaProvider(
      tokenProvider: mockAuthTokenProvider,
      service: mockCargaService,
    );
  });

  group('CargaProvider - Disponibilidad y Reglas de Negocio', () {

    test('19) conductores disponibles excluye ocupados por rango y buffer', () async {
      // Arrange
      final now = DateTime.now();
      final cargaOcupada = CargaModel(
        id: 'c1',
        estado: EstadoCarga.planificado,
        fechaCarga: now.add(const Duration(hours: 1)),
        fechaDescarga: now.add(const Duration(hours: 5)),
        bufferHours: 2,
        transportistaId: 'u1',
        origen: ubicacion,
        destino: ubicacion,
        mercancia: 'M',
        numBultos: 1,
        peso: 1,
        precio: 1,
      );

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [cargaOcupada]);

      // Act
      await provider.fetchCargasDelMes(now, now.add(const Duration(days: 1)), forceRefresh: true);

      final todosLosConductores = [
        UserModel(uid: 'u1', nombre: 'Juan', apellido: '', email: '', telefono: '', rol: ['transportista'], permisosCond: [], companyId: ''),
        UserModel(uid: 'u2', nombre: 'Pedro', apellido: '', email: '', telefono: '', rol: ['transportista'], permisosCond: [], companyId: ''),
      ];

      final disponibles = provider.conductoresDisponibles(
        todosLosConductores: todosLosConductores,
        fechaInicioTarget: now.add(const Duration(hours: 2)),
        fechaFinTarget: now.add(const Duration(hours: 3)),
        companyDefaultBuffer: 1,
      );

      // Assert
      expect(disponibles.map((d) => d.uid), isNot(contains('u1')));
      expect(disponibles.map((d) => d.uid), contains('u2'));
    });

    test('20) vehiculos disponibles excluye ocupados por rango y buffer', () async {
      // Arrange
      final now = DateTime.now();
      final cargaOcupada = CargaModel(
        id: 'c1',
        estado: EstadoCarga.planificado,
        fechaCarga: now.add(const Duration(hours: 1)),
        fechaDescarga: now.add(const Duration(hours: 5)),
        bufferHours: 2,
        vehiculoId: 'V1',
        origen: ubicacion,
        destino: ubicacion,
        mercancia: 'M',
        numBultos: 1,
        peso: 1,
        precio: 1,
      );

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [cargaOcupada]);

      // Act
      await provider.fetchCargasDelMes(now, now.add(const Duration(days: 1)), forceRefresh: true);

      final todosLosVehiculos = [
        VehiculoModel(matricula: 'V1', marca: 'X', modelo: 'Y', capacidad: 1, largo: 1, ancho: 1, alto: 1),
        VehiculoModel(matricula: 'V2', marca: 'X', modelo: 'Y', capacidad: 1, largo: 1, ancho: 1, alto: 1),
      ];

      final disponibles = provider.vehiculosDisponibles(
        todosLosVehiculos: todosLosVehiculos,
        fechaInicioTarget: now.add(const Duration(hours: 2)),
        fechaFinTarget: now.add(const Duration(hours: 3)),
        companyDefaultBuffer: 1,
      );

      // Assert
      expect(disponibles.map((v) => v.matricula), isNot(contains('V1')));
      expect(disponibles.map((v) => v.matricula), contains('V2'));
    });

    test('21) onDragEnd no mueve carga cedida (provider) — no modifica estado original', () async {
      // Arrange
      final now = DateTime.now();
      final cedida = CargaModel(
        id: 'c2',
        estado: EstadoCarga.cedido,
        fechaCarga: now,
        fechaDescarga: now.add(const Duration(hours: 2)),
        origen: ubicacion,
        destino: ubicacion,
        mercancia: 'M',
        numBultos: 1,
        peso: 1,
        precio: 1,
      );

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [cedida]);

      await provider.fetchCargasDelMes(now, now.add(const Duration(days: 1)), forceRefresh: true);

      // Act: intentamos mover la carga mediante los métodos expuestos en el provider
      provider.actualizarFechasCarga('c2', now.add(const Duration(days: 1)), now.add(const Duration(days: 1, hours: 2)));
      provider.planificarCarga('c2', now.add(const Duration(days: 1)), now.add(const Duration(days: 1, hours: 2)));

      // Assert: Validamos que la regla de negocio if (estado == EstadoCarga.cedido) return; funcionó
      final cargaModificada = provider.cargas.firstWhere((c) => c.id == 'c2');
      expect(cargaModificada.fechaCarga.day, equals(now.day));

      // Verificamos que no se ha añadido a la lista de cambios sin guardar
      expect(provider.hayCambiosSinGuardar, isFalse);
    });
  });

  test('26) guardarCambios captura error de servicio y mantiene la lista de cargas', () async {
    // Arrange
    final cargaExistente = CargaModel(
      id: 'c1',
      estado: EstadoCarga.planificado,
      fechaCarga: DateTime.now(),
      fechaDescarga: DateTime.now().add(const Duration(hours: 1)),
      origen: ubicacion,
      destino: ubicacion,
      mercancia: 'M',
      numBultos: 1,
      peso: 1,
      precio: 1,
    );

    when(mockCargaService.getCargasDelMes(any, any))
        .thenAnswer((_) async => [cargaExistente]);
    await provider.fetchCargasDelMes(DateTime.now(), DateTime.now(), forceRefresh: true);

    provider.actualizarFechasCarga('c1', DateTime.now().add(const Duration(days: 1)), DateTime.now().add(const Duration(days: 1, hours: 1)));

    // Simulamos el fallo del servicio (Ej: SocketException o error 500)
    when(mockCargaService.updateCargas(any))
        .thenThrow(Exception('Error de conexión 500'));

    // Act
    await provider.guardarCambios();

    // Assert
    // 1. Verificamos que el error se capturó en el provider
    expect(provider.errorMessage, contains('Error de conexión 500'));

    // 2. Verificamos que la carga sigue en el provider (no se borró por el error)
    expect(provider.cargas.length, equals(1));
    expect(provider.cargas.first.id, equals('c1'));

    // 3. Verificamos que el flag de carga ha vuelto a false
    expect(provider.isLoading, isFalse);
  });
}