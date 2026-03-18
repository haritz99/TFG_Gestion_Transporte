import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_transporte/core/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    final profileData = {
      'uid': user.uid,  // Se le asigna el uid de firebase auth
      'nombre': userData.nombre,
      'apellido': userData.apellido,
      'email': user.email ?? email,
      'telefono': userData.telefono,
      'rol': userData.rol,
      'permisosCond': userData.permisosCond,
      'vehiculoId': userData.vehiculoId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('users').doc(user.uid).set(profileData);
      return credential;
    } catch (e) {
      // Evita dejar una cuenta de Auth sin perfil si falla Firestore.
      await user.delete();
      rethrow;
    }
  }


  

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
