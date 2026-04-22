import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'auth_service.dart';
import 'register_company.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final RegisterCompanyService _registerCompanyService = RegisterCompanyService();
  UserModel? _user;
  bool _isLoading = false;
  String? _idToken;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _idToken != null;
  String? get idToken => _idToken;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    try {
      if (firebaseUser != null) {
        final results = await Future.wait([
          _authService.getUserData(firebaseUser.uid),
          _authService.getIdToken(),
        ]);

        _user = results[0] as UserModel?;
        _idToken = results[1] as String?;
      } else {
        _user = null;
        _idToken = null;
      }
    } catch (_) {
      _user = null;
      _idToken = null;
    }
    notifyListeners();
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
      if (_idToken != null && _user != null) {
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
    required String estado,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final companyId = await _registerCompanyService.registerCompany(
        nombreEmpresa,
      );

      final userData = UserModel(
        uid: '', // Ahora es vacio porque aun no se ha creado en firebase auth
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        rol: rol,
        permisosCond: permisosCond,
        companyId: companyId,
        estado: estado,
        vehiculoId: null,
      );

      await _authService.register(
        email,
        password,
        userData,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _idToken = null;
    notifyListeners();
  }
}
