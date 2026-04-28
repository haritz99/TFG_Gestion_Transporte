import 'package:cloud_firestore/cloud_firestore.dart';

class ModelUtils {
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);

    try {
      if (value.runtimeType.toString() == 'Timestamp' || value.runtimeType.toString() == '_JsonTimestamp') {
        return value.toDate();
      }
    } catch (_) {}

    return null;
  }
}

