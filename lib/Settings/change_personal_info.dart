import 'package:flutter/material.dart';
import 'package:shurokkha_app/Api_Services/api_service.dart';

class ChangePersonalInfoScreen extends StatefulWidget {
  const ChangePersonalInfoScreen({super.key});

  @override
  State<ChangePersonalInfoScreen> createState() =>
      _ChangePersonalInfoScreenState();
}

class _ChangePersonalInfoScreenState extends State<ChangePersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = true;

  String? _originalPhone;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await getUserProfile();
    if (profile != null) {
      setState(() {
        _originalPhone = profile['phone_number'];
        _originalEmail = profile['email'];
        _phoneController.text = _originalPhone ?? '';
        _emailController.text = _originalEmail ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load user info')));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        await updatePersonalInfo(
          phone: phone,
          email: email,
          password: password.isNotEmpty ? password : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Information updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update info')));
        print('Error: $e');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Personal Info'),
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
                    // ─── Phone ───────────────────────────────
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !RegExp(r'^\d{10,11}$').hasMatch(value)) {
                          return 'Enter a valid 10 or 11-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Email ───────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Password ─────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Confirm Password ────────────────────
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Submit Button ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        onPressed: _submitForm,
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
