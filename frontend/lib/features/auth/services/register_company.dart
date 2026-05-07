import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_transporte/core/models/company_model.dart';

class RegisterCompanyService {
  final FirebaseFirestore _firestore;

  RegisterCompanyService({FirebaseFirestore? firestore})
	  : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> registerCompany(String nombreEmpresa) async {
	final normalizedName = nombreEmpresa.trim();
	if (normalizedName.isEmpty) {
	  throw ArgumentError('El nombre de la empresa es obligatorio.');
	}

	final docRef = _firestore.collection('empresas').doc();
	final company = CompanyModel(id: docRef.id, nombre: normalizedName);

	await docRef.set({
	  ...company.toMap(),
	  'createdAt': FieldValue.serverTimestamp(),
	  'updatedAt': FieldValue.serverTimestamp(),
	});

	return docRef.id;
  }
}

