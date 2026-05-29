import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import '../../../core/models/external_user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<ExternalUserModel?> getExternalUserData(String uid) async {
    final cliDoc = await _firestore.collection('clientes').doc(uid).get();
    if (cliDoc.exists) {
      final data = cliDoc.data()!;
      return ExternalUserModel.fromMap(data, cliDoc.id);
    }
    final subDoc = await _firestore.collection('subcontratados').doc(uid).get();
    if (subDoc.exists) {
      final data = subDoc.data()!;
      return ExternalUserModel.fromMap(data, subDoc.id);
    }
    throw Exception('No se ha encontrado el usuario');
  }

  Future<UserCredential> register(
    String email,
    String password,
    UserModel userData,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'No se pudo crear el usuario en Firebase Auth.',
      );
    }

    final token = await user.getIdToken();

    final profileData = {
      'uid': user.uid,  // Se le asigna el uid de firebase auth
      'nombre': userData.nombre,
      'apellido': userData.apellido,
      'email': user.email ?? email,
      'telefono': userData.telefono,
      'rol': userData.rol,
      'permisosCond': userData.permisosCond,
      'companyId': userData.companyId,
      'vehiculoId': userData.vehiculoId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {

      await _firestore.collection('users').doc(user.uid).set(profileData);

      await inicializarCustomClaims(token, userData.companyId, userData.rol);

      // Refresca y valida que el nuevo token ya contiene los claims esperados.
      final refreshed = await user.getIdTokenResult(true);
      final claimCompanyId = refreshed.claims?['companyId'];
      final claimRol = refreshed.claims?['rol'];

      final currentRoles = (claimRol as List?)?.cast<String>() ?? [];
      final hasAllExpectedRoles = userData.rol.every((r) => currentRoles.contains(r));

      if (claimCompanyId != userData.companyId || !hasAllExpectedRoles) {
        throw Exception('El token refrescado no contiene los custom claims esperados');
      }
      return credential;
    } catch (e) {
      // Evita dejar una cuenta de Auth sin perfil o claims si algo falla durante el alta.
      await user.delete();
      rethrow;
    }
  }


  Future<void> inicializarCustomClaims(String? token, String companyId, List<String> rol) async {
    if (token == null || token.isEmpty) {
      throw Exception('No se pudo obtener el token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/customClaims/init');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'companyId': companyId, 'rol': rol}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al inicializar los claims: ${response.body}');
    }
  }


  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<ExternalUserModel> updateExternalProfile(String uid, ExternalUserProfileUpdateModel data) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ext/profile/$uid');
    final token = await getIdToken();
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data.toMap()),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el perfil de usuario');
    }
    return ExternalUserModel.fromMap(jsonDecode(response.body), uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
