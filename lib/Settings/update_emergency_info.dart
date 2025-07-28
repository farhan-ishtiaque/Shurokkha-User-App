import 'package:flutter/material.dart';

class UpdateEmergencyInfoScreen extends StatefulWidget {
  const UpdateEmergencyInfoScreen({super.key});

  @override
  State<UpdateEmergencyInfoScreen> createState() =>
      _UpdateEmergencyInfoScreenState();
}

class _UpdateEmergencyInfoScreenState extends State<UpdateEmergencyInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> contactControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  @override
  void dispose() {
    for (var controller in contactControllers) {
      controller.dispose();
    }
    bloodGroupController.dispose();
    healthConditionsController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  void _saveEmergencyInfo() {
    if (_formKey.currentState!.validate()) {
      final emergencyInfo = {
        'contacts': contactControllers
            .map((c) => c.text)
            .where((c) => c.isNotEmpty)
            .toList(),
        'blood_group': bloodGroupController.text,
        'health_conditions': healthConditionsController.text,
        'allergies': allergiesController.text,
      };

      debugPrint('Saved Emergency Info: $emergencyInfo');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency information saved successfully!"),
        ),
      );
    }
  }

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Emergency Info'),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Emergency Contacts (up to 3)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: contactControllers[index],
                    keyboardType: TextInputType.phone,
                    decoration: _buildDecoration(
                      "Contact ${index + 1}",
                      Icons.phone,
                    ),
                    validator: (v) {
                      if (index == 0 && (v == null || v.isEmpty)) {
                        return 'At least one contact is required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Blood Group ───────────────────────
              TextFormField(
                controller: bloodGroupController,
                decoration: _buildDecoration("Blood Group", Icons.bloodtype),
              ),
              const SizedBox(height: 12),

              // ─── Health Conditions ─────────────────
              TextFormField(
                controller: healthConditionsController,
                decoration: _buildDecoration(
                  "Health Conditions",
                  Icons.health_and_safety,
                ),
              ),
              const SizedBox(height: 12),

              // ─── Allergies ─────────────────────────
              TextFormField(
                controller: allergiesController,
                decoration: _buildDecoration("Allergies", Icons.warning_amber),
              ),

              const SizedBox(height: 24),

              // ─── Submit Button ─────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Emergency Info'),
                  onPressed: _saveEmergencyInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
