import 'package:flutter/material.dart';
import '../flavors.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  
  Future<void> _showSnackBar(BuildContext context, String message) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkFirebaseApps(BuildContext context) async {
    try {
      final apps = Firebase.apps;
      final projectIds = apps.map((a) => a.options.projectId).join(', ');
      await _showSnackBar(context, 'Firebase apps: $projectIds');
    } catch (e) {
      await _showSnackBar(context, 'Error leyendo Firebase.apps: $e');
    }
  }

  Future<void> _testFirestoreWrite(BuildContext context) async {
    try {
      final ref = await FirebaseFirestore.instance
          .collection('health_check')
          .add({'flavor': F.name, 'ts': FieldValue.serverTimestamp()});
      await _showSnackBar(context, 'Firestore OK: ${ref.id}');
    } catch (e) {
      await _showSnackBar(context, 'Firestore ERROR: $e');
    }
  }

  Future<void> _testAuth(BuildContext context) async {
    try {
      final usercred = await FirebaseAuth.instance.signInAnonymously();
      await _showSnackBar(context, 'Auth OK: ${usercred.user?.uid}');
    } catch (e) {
      await _showSnackBar(context, 'Auth ERROR: $e');
    }
  }

  Future<void> _testMessaging(BuildContext context) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _showSnackBar(context, 'FCM token: ${token ?? 'null'}');
    } catch (e) {
      await _showSnackBar(context, 'FCM ERROR: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(F.title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hello ${F.title}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _checkFirebaseApps(context),
                child: const Text('Comprobar Firebase (apps)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _testFirestoreWrite(context),
                child: const Text('Probar Firestore (write)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _testAuth(context),
                child: const Text('Probar Auth (anónimo)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _testMessaging(context),
                child: const Text('Probar FCM (getToken)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
