import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for handling legacy medical report documents
/// Provides migration support and graceful handling of missing fields
class MedicalReportMigrationHelper {
  static const String medicalReportsCollection = 'medical_reports';

  /// Check if a medical report document is in legacy format
  static bool isLegacyDocument(Map<String, dynamic> data) {
    // Check for missing new fields that should be present
    final missingFields = [
      'assigned_hospital_name',
      'assigned_driver_name',
      'assigned_driver_unit_id',
      'nearby_hospital_ids',
      'sent_to_operator',
      'escalation_scheduled',
      'updated_at',
    ];

    return missingFields.any((field) => !data.containsKey(field));
  }

  /// Migrate a single legacy document to new format
  static Future<bool> migrateLegacyDocument(String documentId) async {
    try {
      print('🔄 Migrating legacy document: $documentId');

      final docRef = FirebaseFirestore.instance
          .collection(medicalReportsCollection)
          .doc(documentId);

      final doc = await docRef.get();
      if (!doc.exists) {
        print('❌ Document not found: $documentId');
        return false;
      }

      final data = doc.data()!;

      if (!isLegacyDocument(data)) {
        print('✅ Document already migrated: $documentId');
        return true;
      }

      // Prepare migration data
      final migrationData = <String, dynamic>{};

      // Add missing fields with safe defaults
      if (!data.containsKey('assigned_hospital_name')) {
        migrationData['assigned_hospital_name'] = null;
      }

      if (!data.containsKey('assigned_driver_name')) {
        migrationData['assigned_driver_name'] = null;
      }

      if (!data.containsKey('assigned_driver_unit_id')) {
        migrationData['assigned_driver_unit_id'] = null;
      }

      if (!data.containsKey('nearby_hospital_ids')) {
        migrationData['nearby_hospital_ids'] = <String>[];
      }

      if (!data.containsKey('sent_to_operator')) {
        migrationData['sent_to_operator'] = false;
      }

      if (!data.containsKey('escalation_scheduled')) {
        migrationData['escalation_scheduled'] = false;
      }

      if (!data.containsKey('escalation_time')) {
        migrationData['escalation_time'] = null;
      }

      if (!data.containsKey('updated_at')) {
        migrationData['updated_at'] =
            data['timestamp'] ?? FieldValue.serverTimestamp();
      }

      // Ensure ai_advice field exists
      if (!data.containsKey('ai_advice')) {
        migrationData['ai_advice'] = null;
      }

      // Ensure operator_status field exists
      if (!data.containsKey('operator_status')) {
        migrationData['operator_status'] = null;
      }

      // Update document with migration data
      await docRef.update(migrationData);

      print('✅ Successfully migrated document: $documentId');
      return true;
    } catch (e) {
      print('❌ Error migrating document $documentId: $e');
      return false;
    }
  }

  /// Migrate all legacy documents in the collection
  static Future<MigrationResult> migrateAllLegacyDocuments() async {
    print('🚀 Starting migration of all legacy medical reports...');

    final result = MigrationResult();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(medicalReportsCollection)
          .get();

      print('📊 Found ${querySnapshot.docs.length} total documents');

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        if (isLegacyDocument(data)) {
          result.legacyDocumentsFound++;

          final migrated = await migrateLegacyDocument(doc.id);
          if (migrated) {
            result.successfulMigrations++;
          } else {
            result.failedMigrations++;
            result.failedDocumentIds.add(doc.id);
          }
        } else {
          result.alreadyMigrated++;
        }
      }

      print('✅ Migration completed!');
      print('📊 Results: ${result.toString()}');
    } catch (e) {
      print('❌ Error during batch migration: $e');
      result.batchError = e.toString();
    }

    return result;
  }

  /// Get safe field value with fallback for legacy documents
  static T getSafeValue<T>(
    Map<String, dynamic> data,
    String fieldName,
    T defaultValue,
  ) {
    if (data.containsKey(fieldName) && data[fieldName] != null) {
      try {
        return data[fieldName] as T;
      } catch (e) {
        print('⚠️ Type conversion error for field $fieldName: $e');
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Get safe string value with placeholder for display
  static String getSafeDisplayValue(
    Map<String, dynamic> data,
    String fieldName, {
    String placeholder = 'Not available',
  }) {
    final value = getSafeValue<String?>(data, fieldName, null);
    return value?.isNotEmpty == true ? value! : placeholder;
  }

  /// Get safe list value
  static List<T> getSafeListValue<T>(
    Map<String, dynamic> data,
    String fieldName,
  ) {
    final value = data[fieldName];
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (e) {
        print('⚠️ List conversion error for field $fieldName: $e');
        return <T>[];
      }
    }
    return <T>[];
  }

  /// Check if document needs UI compatibility warning
  static bool needsCompatibilityWarning(Map<String, dynamic> data) {
    // Check for critical missing fields that affect UI
    final criticalFields = ['status', 'category', 'description', 'timestamp'];

    return criticalFields.any(
      (field) => !data.containsKey(field) || data[field] == null,
    );
  }

  /// Get compatibility warning message for UI
  static String getCompatibilityWarningMessage(Map<String, dynamic> data) {
    if (isLegacyDocument(data)) {
      return 'This report uses an older format. Some details may not be available.';
    }

    if (needsCompatibilityWarning(data)) {
      return 'This report has incomplete data. Please contact support if you need assistance.';
    }

    return '';
  }

  /// Validate document structure
  static DocumentValidationResult validateDocument(Map<String, dynamic> data) {
    final result = DocumentValidationResult();

    // Required fields
    final requiredFields = [
      'status',
      'category',
      'description',
      'timestamp',
      'user_id',
    ];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        result.missingRequiredFields.add(field);
      }
    }

    // Optional fields that should have defaults
    final optionalFields = [
      'ai_advice',
      'assigned_hospital_name',
      'assigned_driver_name',
      'nearby_hospital_ids',
      'sent_to_operator',
      'escalation_scheduled',
    ];

    for (final field in optionalFields) {
      if (!data.containsKey(field)) {
        result.missingOptionalFields.add(field);
      }
    }

    result.isValid = result.missingRequiredFields.isEmpty;
    result.isLegacy = isLegacyDocument(data);

    return result;
  }
}

/// Result of migration operation
class MigrationResult {
  int legacyDocumentsFound = 0;
  int successfulMigrations = 0;
  int failedMigrations = 0;
  int alreadyMigrated = 0;
  List<String> failedDocumentIds = [];
  String? batchError;

  bool get hasErrors => failedMigrations > 0 || batchError != null;

  @override
  String toString() {
    return '''
Migration Results:
- Legacy documents found: $legacyDocumentsFound
- Successfully migrated: $successfulMigrations
- Already migrated: $alreadyMigrated
- Failed migrations: $failedMigrations
- Batch error: ${batchError ?? 'None'}
${failedDocumentIds.isNotEmpty ? '- Failed IDs: ${failedDocumentIds.join(', ')}' : ''}
''';
  }
}

/// Result of document validation
class DocumentValidationResult {
  bool isValid = false;
  bool isLegacy = false;
  List<String> missingRequiredFields = [];
  List<String> missingOptionalFields = [];

  bool get needsMigration => isLegacy || missingOptionalFields.isNotEmpty;

  @override
  String toString() {
    return '''
Document Validation:
- Valid: $isValid
- Legacy: $isLegacy
- Missing required: ${missingRequiredFields.join(', ')}
- Missing optional: ${missingOptionalFields.join(', ')}
''';
  }
}

/// Extension methods for safe document access
extension SafeDocumentAccess on DocumentSnapshot {
  /// Get data with null safety
  Map<String, dynamic> safeData() {
    return data() as Map<String, dynamic>? ?? {};
  }

  /// Get field with default value
  T safeGet<T>(String field, T defaultValue) {
    final data = safeData();
    return MedicalReportMigrationHelper.getSafeValue(data, field, defaultValue);
  }

  /// Check if document is legacy
  bool get isLegacy {
    return MedicalReportMigrationHelper.isLegacyDocument(safeData());
  }

  /// Get compatibility warning
  String get compatibilityWarning {
    return MedicalReportMigrationHelper.getCompatibilityWarningMessage(
      safeData(),
    );
  }
}
