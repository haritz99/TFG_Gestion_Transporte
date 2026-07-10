import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import '../../../core/models/company_model.dart';
import '../../../core/models/direccion_model.dart';
import '../auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  final Duration _timeout;
  Completer<void>? _hydrationCompleter;
  ExternalUserModel? _externalUser;
  bool _isLoading = false;
  String? _idToken;
  CompanyModel? _company;

  UserModel? get user => _user;
  ExternalUserModel? get externalUser => _externalUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null || _externalUser != null;
  String? get idToken => _idToken;
  CompanyModel? get company => _company;

  AuthProvider({
    required AuthService authService,
    Duration? timeout,
  }) : _authService = authService, _timeout = timeout ?? const Duration(seconds: 8) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
    debugPrint('Constructor AuthProvider');
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint(
        'AuthState user=${firebaseUser?.uid} '
            'completer=${_hydrationCompleter?.hashCode}'
    );
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('Auth A');
      if (firebaseUser != null) {
        final results = await Future.wait([
          _authService.getUserData(firebaseUser.uid),
          _authService.getIdToken(),
        ]);

        _user = results[0] as UserModel?;
        _idToken = results[1] as String?;
        if (_user == null) {
          _externalUser = await _authService.getExternalUserData(firebaseUser.uid).catchError((e) {
            return null;
          });
        } else {
          debugPrint('Auth B');
          await cargarConfiguracionEmpresa(_user!.companyId);
        }
        debugPrint('Auth C');
        await _authService.guardarFcmToken();
        debugPrint('Auth D');
      } else {
        _user = null;
        _externalUser = null;
        _idToken = null;
      }
      _tryCompleteHydration();
      debugPrint('Auth E');
    } catch (e) {
      debugPrint('Auth error');
      debugPrint(e.toString());
      _user = null;
      _externalUser = null;
      _idToken = null;
    } finally {
      debugPrint('Auth finally');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _tryCompleteHydration() {
    if (_isHydrated()) {
      _hydrationCompleter?.complete();
    }
  }
  bool _isHydrated() {
    debugPrint(
        '_isHydrated user:${_user != null} ext:${_externalUser != null}');
    return (_user != null || _externalUser != null);
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _hydrationCompleter = Completer<void>();
    notifyListeners();
    try {
      debugPrint('1');
      await _authService.signIn(email, password);
      debugPrint('2');
      await _waitForSessionHydration();
      debugPrint('3');
    } catch (e) {
      rethrow;
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _waitForSessionHydration() async {
    if (_isHydrated()) {
      _hydrationCompleter = null;
      return;
    }
    try {
      debugPrint('A');
      await _hydrationCompleter!.future.timeout(_timeout);
      debugPrint('B');
    } on TimeoutException {
      throw TimeoutException(
        'No se pudo hidratar la sesión en el tiempo esperado.',
      );
    } finally {
      _hydrationCompleter = null;
    }
  }

  Future<void> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required List<String> rol,
    required List<String> permisosCond,
    required String password,
    required String nombreEmpresa,
    String? estado,
    String? razonSocial,
    String? nif,
    String? telefonoEmpresa,
    String? numAutorizacion,
    DireccionModel? direccion,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {

      final token = await _authService.register(email, password);

      final body = {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'rol': rol,
        'permisosCond': permisosCond,
        'estado': estado,
        'empresa': {
          'nombre': nombreEmpresa,
          'razonSocial': razonSocial,
          'nif': nif,
          'telefono': telefonoEmpresa,
          'numAutorizacion': numAutorizacion,
          'direccion': direccion?.toMap(),
        }
      };

      await _authService.createUserWithCompany(token: token, body: body);

      await _authService.currentUser!.getIdToken(true);
      _user = await _authService.getUserData(_authService.currentUser!.uid);

    } catch (e) {
      await FirebaseAuth.instance.currentUser?.delete();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fulfillExternalUserProfile(ExternalUserProfileUpdateModel data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _externalUser = await _authService.updateExternalProfile(_externalUser!.uid, data);
      await _onAuthStateChanged(FirebaseAuth.instance.currentUser);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarConfiguracionEmpresa(String empresaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _authService.getCompanyData(empresaId);
      _company = data;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cambiarBufferGlobal(int nuevasHoras) async {
    final estadoAnterior = _company!;
    _company = _company!.copyWith(bufferHours: nuevasHoras);
    notifyListeners();
    try {
      await _authService.updateCompanyBuffer(_company!.id, nuevasHoras);
    } catch (e) {
      _company = estadoAnterior;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _externalUser = null;
    _idToken = null;
    _company = null;
    notifyListeners();
  }
}
