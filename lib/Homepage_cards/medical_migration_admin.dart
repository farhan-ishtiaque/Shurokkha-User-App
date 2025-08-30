import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/medical_migration_helper.dart';

/// Admin screen for medical report migration and maintenance
/// One-time use screen for migrating legacy documents
class MedicalMigrationAdminScreen extends StatefulWidget {
  const MedicalMigrationAdminScreen({super.key});

  @override
  State<MedicalMigrationAdminScreen> createState() =>
      _MedicalMigrationAdminScreenState();
}

class _MedicalMigrationAdminScreenState
    extends State<MedicalMigrationAdminScreen> {
  bool _isAnalyzing = false;
  bool _isMigrating = false;
  MigrationResult? _lastMigrationResult;
  List<DocumentValidationResult> _documentAnalysis = [];
  final List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _addLog('Medical Migration Admin initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.insert(0, '${DateTime.now().toLocal()}: $message');
      if (_logMessages.length > 100) {
        _logMessages.removeLast();
      }
    });
    print(message);
  }

  /// Analyze all documents to identify legacy ones
  Future<void> _analyzeDocuments() async {
    setState(() {
      _isAnalyzing = true;
      _documentAnalysis.clear();
    });

    try {
      _addLog('🔍 Starting document analysis...');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('medical_reports')
          .get();

      _addLog('📊 Found ${querySnapshot.docs.length} total documents');

      int legacyCount = 0;
      int validCount = 0;
      int invalidCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final validation = MedicalReportMigrationHelper.validateDocument(data);

        _documentAnalysis.add(validation);

        if (validation.isLegacy) {
          legacyCount++;
          _addLog('📋 Legacy document found: ${doc.id}');
        }

        if (validation.isValid) {
          validCount++;
        } else {
          invalidCount++;
          _addLog(
            '⚠️ Invalid document: ${doc.id} - Missing: ${validation.missingRequiredFields.join(', ')}',
          );
        }
      }

      _addLog('✅ Analysis complete!');
      _addLog(
        '📊 Summary: $legacyCount legacy, $validCount valid, $invalidCount invalid',
      );
    } catch (e) {
      _addLog('❌ Error during analysis: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  /// Run full migration of all legacy documents
  Future<void> _runMigration() async {
    setState(() => _isMigrating = true);

    try {
      _addLog('🚀 Starting migration process...');

      final result =
          await MedicalReportMigrationHelper.migrateAllLegacyDocuments();

      setState(() => _lastMigrationResult = result);

      _addLog('✅ Migration completed!');
      _addLog(
        '📊 Results: ${result.successfulMigrations} successful, ${result.failedMigrations} failed',
      );

      if (result.hasErrors) {
        _addLog('⚠️ Some migrations failed. Check logs for details.');
      }

      // Re-analyze after migration
      await _analyzeDocuments();
    } catch (e) {
      _addLog('❌ Migration error: $e');
    } finally {
      setState(() => _isMigrating = false);
    }
  }

  /// Migrate a specific document by ID
  Future<void> _migrateSingleDocument(String documentId) async {
    try {
      _addLog('🔄 Migrating single document: $documentId');

      final success = await MedicalReportMigrationHelper.migrateLegacyDocument(
        documentId,
      );

      if (success) {
        _addLog('✅ Successfully migrated: $documentId');
      } else {
        _addLog('❌ Failed to migrate: $documentId');
      }
    } catch (e) {
      _addLog('❌ Error migrating $documentId: $e');
    }
  }

  /// Show confirmation dialog for destructive operations
  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Migration Admin'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Admin Tool - Use with Caution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool modifies Firestore documents. Always backup your data before running migrations.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Migration Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzeDocuments,
                          child: _isAnalyzing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Analyze Documents'),
                        ),
                        ElevatedButton(
                          onPressed: (_isMigrating || _documentAnalysis.isEmpty)
                              ? null
                              : () async {
                                  final confirmed = await _showConfirmationDialog(
                                    'Confirm Migration',
                                    'This will migrate all legacy documents. Continue?',
                                  );
                                  if (confirmed) {
                                    await _runMigration();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: _isMigrating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Run Migration'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results section
            if (_documentAnalysis.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnalysisSummary(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Migration results
            if (_lastMigrationResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Migration Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMigrationResults(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Single document migration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Single Document Migration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Enter document ID',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: _migrateSingleDocument,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Get text from the text field and migrate
                            // This is a simplified version - in a real app you'd use a controller
                          },
                          child: const Text('Migrate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Log section
            const Text(
              'Migration Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _logMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'No log messages yet.\nRun analysis or migration to see logs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text(
                                _logMessages[index],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSummary() {
    final total = _documentAnalysis.length;
    final legacy = _documentAnalysis.where((d) => d.isLegacy).length;
    final valid = _documentAnalysis.where((d) => d.isValid).length;
    final invalid = total - valid;

    return Column(
      children: [
        _buildStatRow('Total Documents', total, Colors.blue),
        _buildStatRow('Legacy Documents', legacy, Colors.orange),
        _buildStatRow('Valid Documents', valid, Colors.green),
        _buildStatRow('Invalid Documents', invalid, Colors.red),
      ],
    );
  }

  Widget _buildMigrationResults() {
    final result = _lastMigrationResult!;

    return Column(
      children: [
        _buildStatRow(
          'Legacy Found',
          result.legacyDocumentsFound,
          Colors.orange,
        ),
        _buildStatRow(
          'Successful Migrations',
          result.successfulMigrations,
          Colors.green,
        ),
        _buildStatRow('Failed Migrations', result.failedMigrations, Colors.red),
        _buildStatRow('Already Migrated', result.alreadyMigrated, Colors.blue),
        if (result.hasErrors) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Errors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (result.batchError != null)
                  Text(
                    'Batch Error: ${result.batchError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                if (result.failedDocumentIds.isNotEmpty)
                  Text(
                    'Failed IDs: ${result.failedDocumentIds.join(', ')}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
