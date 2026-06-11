import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_transporte/core/models/external_user_model.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import '../../../core/models/company_model.dart';
import '../../../core/models/direccion_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  ExternalUserModel? _externalUser;
  bool _isLoading = false;
  String? _idToken;
  CompanyModel? _company;

  UserModel? get user => _user;
  ExternalUserModel? get externalUser => _externalUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _idToken != null;
  String? get idToken => _idToken;
  CompanyModel? get company => _company;

  AuthProvider({required AuthService authService}) : _authService = authService {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _isLoading = true;
    notifyListeners();

    try {
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
          await cargarConfiguracionEmpresa(_user!.companyId);
        }
        await _authService.guardarFcmToken();
      } else {
        _user = null;
        _externalUser = null;
        _idToken = null;
      }
    } catch (_) {
      _user = null;
      _externalUser = null;
      _idToken = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
      await _waitForSessionHydration();
    } catch (e) {
      rethrow;
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _waitForSessionHydration() async {
    const timeout = Duration(seconds: 8);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (_idToken != null && (_user != null || _externalUser != null)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    throw TimeoutException(
      'No se pudo hidratar la sesion tras iniciar sesion en el tiempo esperado.',
    );
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
    notifyListeners();
  }
}
