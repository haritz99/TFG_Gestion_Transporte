import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
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
    if (firebaseUser != null) {
      _user = await _authService.getUserData(firebaseUser.uid);
      _idToken = await _authService.getIdToken();
    } else {
      _user = null;
      _idToken = null;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signIn(email, password);
      _user = await _authService.getUserData(credential.user!.uid);
      _idToken = await credential.user?.getIdToken();
    } finally {
      _isLoading = false;
      notifyListeners();
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
  }) async {
    _isLoading = true;
    notifyListeners();
    try {

      final userData = UserModel(
        uid: '', // Ahora es vacio porque aun no se ha creado en firebase auth
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        rol: rol,
        permisosCond: permisosCond,
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

  Future<String?> getValidIdToken({bool forceRefresh = false}) async {
    _idToken = await _authService.getIdToken(forceRefresh: forceRefresh);
    notifyListeners();
    return _idToken;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _idToken = null;
    notifyListeners();
  }
}
