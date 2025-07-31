import 'package:flutter/material.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyInfo();
  }

  Future<void> _loadEmergencyInfo() async {
    final info = await getEmergencyInfo();
    if (info != null) {
      contactControllers[0].text = info['emergency_contact1'] ?? '';
      contactControllers[1].text = info['emergency_contact2'] ?? '';
      contactControllers[2].text = info['emergency_contact3'] ?? '';
      bloodGroupController.text = info['blood_group'] ?? '';
      healthConditionsController.text = info['health_conditions'] ?? '';
      allergiesController.text = info['allergies'] ?? '';
    }
    setState(() => _isLoading = false);
  }

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

  void _saveEmergencyInfo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await updateEmergencyInfo(
          contact1: contactControllers[0].text,
          contact2: contactControllers[1].text,
          contact3: contactControllers[2].text,
          bloodGroup: bloodGroupController.text,
          healthConditions: healthConditionsController.text,
          allergies: allergiesController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency information saved successfully!"),
          ),
        );
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save emergency info")),
        );
      }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      decoration: _buildDecoration(
                        "Blood Group",
                        Icons.bloodtype,
                      ),
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
                      decoration: _buildDecoration(
                        "Allergies",
                        Icons.warning_amber,
                      ),
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
