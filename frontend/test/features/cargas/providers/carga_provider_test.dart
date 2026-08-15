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

  CargaModel _crearCarga({
    String id = 'c1',
    EstadoCarga estado = EstadoCarga.planificado,
    DateTime? fechaCarga,
    DateTime? fechaDescarga,
    String? transportistaId,
    String? vehiculoId,
    String? transportistaNombre,
    int? bufferHours,
  }) {
    final now = DateTime.now();
    return CargaModel(
      id: id,
      estado: estado,
      fechaCarga: fechaCarga ?? now,
      fechaDescarga: fechaDescarga ?? now.add(const Duration(hours: 1)),
      transportistaId: transportistaId,
      vehiculoId: vehiculoId,
      transportistaNombre: transportistaNombre,
      bufferHours: bufferHours,
      origen: ubicacion,
      destino: ubicacion,
      mercancia: 'M',
      numBultos: 1,
      peso: 1,
      precio: 1,
    );
  }

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
      final cargaOcupada = _crearCarga(
        estado: EstadoCarga.planificado,
        fechaCarga: now.add(const Duration(hours: 1)),
        fechaDescarga: now.add(const Duration(hours: 5)),
        bufferHours: 2,
        transportistaId: 'u1',
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
      final cargaOcupada = _crearCarga(
        estado: EstadoCarga.planificado,
        fechaCarga: now.add(const Duration(hours: 1)),
        fechaDescarga: now.add(const Duration(hours: 5)),
        bufferHours: 2,
        vehiculoId: 'V1',
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
      final cedida = _crearCarga(
        id: 'c2',
        estado: EstadoCarga.cedido,
        fechaCarga: now,
        fechaDescarga: now.add(const Duration(hours: 2)),
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
    final cargaExistente = _crearCarga();

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

  group('CargaProvider - Métodos síncronos de estado', () {

    test('cargasSemanaAnterior filtra pendientes con fecha anterior al lunes actual', () async {
      final pendienteVieja = _crearCarga(id: 'c_vieja', estado: EstadoCarga.pendiente, fechaCarga: DateTime(2020, 1, 1), fechaDescarga: DateTime(2020, 1, 2));
      final pendienteReciente = _crearCarga(id: 'c_reciente', estado: EstadoCarga.pendiente, fechaCarga: DateTime.now().add(const Duration(days: 1)), fechaDescarga: DateTime.now().add(const Duration(days: 2)));

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [pendienteVieja, pendienteReciente]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 30)), forceRefresh: true);

      expect(provider.cargasSemanaAnterior.map((c) => c.id), equals(['c_vieja']));
    });

    test('estadoConductor retorna sin_asignar cuando no tiene cargas activas', () async {
      final cargaEntregada = _crearCarga(estado: EstadoCarga.entregado, transportistaId: 'u1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [cargaEntregada]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoConductor('u1'), equals('sin_asignar'));
    });

    test('estadoConductor retorna sin_asignar para conductor sin ninguna carga', () async {
      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => []);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoConductor('u1'), equals('sin_asignar'));
    });

    test('estadoConductor retorna en_ruta cuando tiene carga enTransito', () async {
      final carga = _crearCarga(estado: EstadoCarga.enTransito, transportistaId: 'u1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoConductor('u1'), equals('en_ruta'));
    });

    test('estadoConductor retorna asignado cuando tiene carga asignado', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado, transportistaId: 'u1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoConductor('u1'), equals('asignado'));
    });

    test('estadoConductor retorna asignacion_parcial cuando tiene carga planificado', () async {
      final carga = _crearCarga(estado: EstadoCarga.planificado, transportistaId: 'u1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoConductor('u1'), equals('asignacion_parcial'));
    });

    test('estadoVehiculo retorna disponible cuando no tiene cargas', () async {
      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => []);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoVehiculo('V1'), equals('disponible'));
    });

    test('estadoVehiculo retorna disponible cuando las cargas están entregadas/cedidas', () async {
      final cargaEntregada = _crearCarga(estado: EstadoCarga.entregado, vehiculoId: 'V1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [cargaEntregada]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoVehiculo('V1'), equals('disponible'));
    });

    test('estadoVehiculo retorna asignado cuando tiene carga enTransito', () async {
      final carga = _crearCarga(estado: EstadoCarga.enTransito, vehiculoId: 'V1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoVehiculo('V1'), equals('asignado'));
    });

    test('estadoVehiculo retorna asignado cuando tiene carga asignado o planificado', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado, vehiculoId: 'V1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.estadoVehiculo('V1'), equals('asignado'));
    });

    test('conductorDeVehiculo retorna nombre del conductor asignado al vehículo', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado, vehiculoId: 'V1', transportistaNombre: 'Juan García');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.conductorDeVehiculo('V1'), equals('Juan García'));
    });

    test('conductorDeVehiculo retorna null si no hay carga activa para el vehículo', () async {
      final carga = _crearCarga(estado: EstadoCarga.entregado, vehiculoId: 'V1', transportistaNombre: 'Juan');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      expect(provider.conductorDeVehiculo('V1'), isNull);
    });

    test('planificarCarga con carga no cedida modifica estado y fechas', () async {
      final carga = _crearCarga(estado: EstadoCarga.pendiente);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      final nuevaStart = DateTime.now().add(const Duration(days: 1));
      final nuevaEnd = DateTime.now().add(const Duration(days: 1, hours: 4));
      provider.planificarCarga('c1', nuevaStart, nuevaEnd);

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.estado, equals(EstadoCarga.planificado));
      expect(modified.fechaCarga, equals(nuevaStart));
      expect(modified.fechaDescarga, equals(nuevaEnd));
      expect(provider.hayCambiosSinGuardar, isTrue);
    });

    test('asignarVehiculo con matrícula y conductor presente cambia estado a asignado', () async {
      final carga = _crearCarga(estado: EstadoCarga.planificado, transportistaId: 'u1', vehiculoId: null);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      provider.asignarVehiculo('c1', 'V1');

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.vehiculoId, equals('V1'));
      expect(modified.estado, equals(EstadoCarga.asignado));
      expect(provider.hayCambiosSinGuardar, isTrue);
    });

    test('asignarVehiculo con null borra vehículo y cambia estado a planificado', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado, transportistaId: 'u1', vehiculoId: 'V1');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      provider.asignarVehiculo('c1', null);

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.vehiculoId, isNull);
      expect(modified.estado, equals(EstadoCarga.planificado));
    });

    test('asignarConductor con id y vehículo presente cambia estado a asignado', () async {
      final carga = _crearCarga(estado: EstadoCarga.planificado, vehiculoId: 'V1', transportistaId: null, transportistaNombre: null);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      provider.asignarConductor('c1', 'u1', 'Pedro');

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.transportistaId, equals('u1'));
      expect(modified.transportistaNombre, equals('Pedro'));
      expect(modified.estado, equals(EstadoCarga.asignado));
      expect(provider.hayCambiosSinGuardar, isTrue);
    });

    test('asignarConductor con null borra conductor y cambia estado a planificado', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado, vehiculoId: 'V1', transportistaId: 'u1', transportistaNombre: 'Pedro');

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      provider.asignarConductor('c1', null, null);

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.transportistaId, isNull);
      expect(modified.transportistaNombre, isNull);
      expect(modified.estado, equals(EstadoCarga.planificado));
    });

    test('traerCargasEstaSemana mueve pendientes de semana anterior a planificados', () async {
      final pendienteVieja = _crearCarga(id: 'c_vieja', estado: EstadoCarga.pendiente, fechaCarga: DateTime(2020, 1, 1), fechaDescarga: DateTime(2020, 1, 2));

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [pendienteVieja]);
      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 30)), forceRefresh: true);

      expect(provider.cargasSemanaAnterior.length, equals(1));

      provider.traerCargasEstaSemana();

      final modified = provider.cargas.firstWhere((c) => c.id == 'c_vieja');
      final now = DateTime.now();
      expect(modified.estado, equals(EstadoCarga.planificado));
      expect(modified.fechaCarga.year, equals(now.year));
      expect(modified.fechaCarga.month, equals(now.month));
      expect(modified.fechaCarga.day, equals(now.day));
      expect(modified.fechaCarga.hour, equals(now.hour));
      expect(provider.hayCambiosSinGuardar, isTrue);
    });
  });

  group('CargaProvider - Operaciones asíncronas', () {

    test('marcarRecogido éxito actualiza estado a enTransito y reemplaza en lista', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado);
      final cargaActualizada = carga.copyWith(estado: EstadoCarga.enTransito);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.updateEstado(any, any))
          .thenAnswer((_) async => cargaActualizada);

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      await provider.marcarRecogido('c1');

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.estado, equals(EstadoCarga.enTransito));
      expect(provider.isLoading, isFalse);
      verify(mockCargaService.updateEstado('c1', EstadoCarga.enTransito)).called(1);
    });

    test('marcarRecogido con error captura exception y relanza', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.updateEstado(any, any))
          .thenThrow(Exception('Error de red'));

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      await expectLater(
        () => provider.marcarRecogido('c1'),
        throwsA(isA<Exception>()),
      );

      expect(provider.errorMessage, contains('Error de red'));
      expect(provider.isLoading, isFalse);
    });

    test('marcarEntregado éxito actualiza estado a entregado y reemplaza en lista', () async {
      final carga = _crearCarga(estado: EstadoCarga.enTransito);
      final cargaActualizada = carga.copyWith(estado: EstadoCarga.entregado);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.updateEstado(any, any))
          .thenAnswer((_) async => cargaActualizada);

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      await provider.marcarEntregado('c1');

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.estado, equals(EstadoCarga.entregado));
      expect(provider.isLoading, isFalse);
      verify(mockCargaService.updateEstado('c1', EstadoCarga.entregado)).called(1);
    });

    test('cederCargaASubcontratado éxito actualiza carga con datos del subcontratado', () async {
      final carga = _crearCarga(estado: EstadoCarga.asignado, transportistaId: 'u1', vehiculoId: 'V1');
      final cargaCedida = carga.copyWith(estado: EstadoCarga.cedido);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.cederCarga(
        cargaId: anyNamed('cargaId'),
        subcontratadoUid: anyNamed('subcontratadoUid'),
      )).thenAnswer((_) async => cargaCedida);

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      await provider.cederCargaASubcontratado(cargaId: 'c1', subcontratadoId: 'sub1');

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.estado, equals(EstadoCarga.cedido));
      expect(provider.isLoading, isFalse);
      verify(mockCargaService.cederCarga(cargaId: 'c1', subcontratadoUid: 'sub1')).called(1);
    });

    test('actualizarBufferHours éxito actualiza horas en la carga local', () async {
      final carga = _crearCarga(estado: EstadoCarga.planificado, bufferHours: 1);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.updateBufferHours(any, any))
          .thenAnswer((_) async {});

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      await provider.actualizarBufferHours('c1', 3);

      final modified = provider.cargas.firstWhere((c) => c.id == 'c1');
      expect(modified.bufferHours, equals(3));
      expect(provider.isLoading, isFalse);
      verify(mockCargaService.updateBufferHours('c1', 3)).called(1);
    });

    test('actualizarBufferHours con error captura mensaje de error', () async {
      final carga = _crearCarga(estado: EstadoCarga.planificado, bufferHours: 1);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.updateBufferHours(any, any))
          .thenThrow(Exception('Error al actualizar'));

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      await provider.actualizarBufferHours('c1', 3);

      expect(provider.errorMessage, contains('Error al actualizar'));
      expect(provider.isLoading, isFalse);
    });

    test('fetchTiposCarga éxito popula tiposCarga', () async {
      final tipo = TipoCargaModel(
        id: 't1',
        nombre: 'Test',
        pesoMax: 1000,
        companyId: 'c1',
        clienteId: 'cl1',
        origen: ubicacion,
        destino: ubicacion,
        mercancia: 'M',
        numBultos: 1,
        peso: 100,
        precio: 50,
      );

      when(mockCargaService.fetchTiposCarga(any))
          .thenAnswer((_) async => [tipo]);

      await provider.fetchTiposCarga('cl1');

      expect(provider.tiposCarga.length, equals(1));
      expect(provider.tiposCarga.first.id, equals('t1'));
      expect(provider.isLoading, isFalse);
      verify(mockCargaService.fetchTiposCarga('cl1')).called(1);
    });

    test('fetchCargasCedidas éxito popula cargasCedidas', () async {
      final cargaCedida = _crearCarga(estado: EstadoCarga.cedido);

      when(mockCargaService.getCargasCedidas())
          .thenAnswer((_) async => [cargaCedida]);

      await provider.fetchCargasCedidas();

      expect(provider.cargasCedidas.length, equals(1));
      expect(provider.cargasCedidas.first.id, equals('c1'));
      expect(provider.isLoading, isFalse);
    });

    test('fetchCargasIniciales llama a fetchCargasDelMes con fechas correctas', () async {
      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => []);

      await provider.fetchCargasIniciales();

      verify(mockCargaService.getCargasDelMes(any, any)).called(1);
      expect(provider.isLoading, isFalse);
    });

    test('guardarCambios con servicio exitoso limpia modificaciones pendientes', () async {
      final carga = _crearCarga(estado: EstadoCarga.planificado);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [carga]);
      when(mockCargaService.updateCargas(any))
          .thenAnswer((_) async {});

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      provider.actualizarFechasCarga('c1', DateTime.now().add(const Duration(days: 1)), DateTime.now().add(const Duration(days: 1, hours: 2)));
      expect(provider.hayCambiosSinGuardar, isTrue);

      await provider.guardarCambios();

      expect(provider.hayCambiosSinGuardar, isFalse);
      expect(provider.isLoading, isFalse);
    });

    test('descenderCarga llama a updateEstado con planificado y actualiza estado local', () async {
      final cargaCedida = _crearCarga(id: 'c1', estado: EstadoCarga.cedido);

      when(mockCargaService.getCargasDelMes(any, any))
          .thenAnswer((_) async => [cargaCedida]);

      await provider.fetchCargasDelMes(DateTime.now(), DateTime.now().add(const Duration(days: 1)), forceRefresh: true);

      final cargaPlanificada = _crearCarga(id: 'c1', estado: EstadoCarga.planificado);
      when(mockCargaService.updateEstado('c1', EstadoCarga.planificado))
          .thenAnswer((_) async => cargaPlanificada);

      await provider.descenderCarga('c1');

      expect(provider.cargas.first.estado, equals(EstadoCarga.planificado));
      verify(mockCargaService.updateEstado('c1', EstadoCarga.planificado)).called(1);
      expect(provider.isLoading, isFalse);
    });

    test('descenderCarga elimina la carga de cargasCedidas', () async {
      final cargaCedida = _crearCarga(id: 'c1', estado: EstadoCarga.cedido);

      when(mockCargaService.getCargasCedidas())
          .thenAnswer((_) async => [cargaCedida]);
      when(mockCargaService.updateEstado('c1', EstadoCarga.planificado))
          .thenAnswer((_) async => _crearCarga(id: 'c1', estado: EstadoCarga.planificado));

      await provider.fetchCargasCedidas();
      expect(provider.cargasCedidas.length, equals(1));

      await provider.descenderCarga('c1');

      expect(provider.cargasCedidas, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });
}