import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gestion_transporte/core/models/company_model.dart';
import 'package:gestion_transporte/core/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import '../../../core/models/external_user_model.dart';
import '../../../secrets.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final http.Client _client;
  final String _baseUrl = '${ApiConfig.baseUrl}/auth';
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

  Future<String> register(
    String email,
    String password,
    //UserModel userData,
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

    final token = await user.getIdToken() ?? "";
    return token;

  }

  Future<void> createUserWithCompany({required String token, required Map<String, dynamic> body,}) async {
    final uri = Uri.parse('$_baseUrl/register');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      final detail = jsonDecode(response.body)['detail'] ?? 'Error desconocido';
      throw Exception('Error al registrar empresa: $detail');
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

  Future<void> guardarFcmToken() async {
    try {
      final token = await getIdToken();
      final messageToken = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? Secrets.fcmVapidKey : null,
      );
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token');
      if (messageToken != null) {
        await _client.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ' Authorization': 'Bearer $token',
          },
          body: {'token': messageToken});
      }
    } catch (e) {
      debugPrint('Error guardando FCM token: $e');
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

  Future<CompanyModel> getCompanyData(String companyId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/company');
    final token = await getIdToken();
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener los datos de la empresa');
    }
    return CompanyModel.fromMap(jsonDecode(response.body), companyId);
  }

  Future<void> updateCompanyBuffer(String companyId, int buffer) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/company/$companyId/buffer-hours');
    final token = await getIdToken();
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'bufferHours': buffer}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el buffer de la empresa');
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }
}
