import 'dart:io';
import 'Api_Services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shurokkha_app/login_page.dart';
import 'widgets/enhanced_address_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  double? _selectedLat;
  double? _selectedLng;

  // Text controllers
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nidNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Other state
  DateTime? _selectedDob;
  XFile? _nidFront;
  XFile? _selfie;

  @override
  void dispose() {
    _emailController.dispose();
    _dobController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nidNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(XFile) assignImage) async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        // ← wrap in a block that returns void
        assignImage(file); //   just call the setter; don’t return it
      });
    }
  }

  Widget _imageTile({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.pink.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink, width: 2),
        ),
        child: file == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 36),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(file.path), fit: BoxFit.cover),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 6,
        backgroundColor: Colors.white,
        shadowColor: const Color.fromARGB(255, 255, 204, 204),
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 236, 236),
              Color.fromARGB(255, 255, 199, 199),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // ---------- BASIC INFO ----------
                _nameField(_firstnameController, 'First Name'),
                const SizedBox(height: 16),
                _nameField(_lastnameController, 'Last Name'),
                const SizedBox(height: 16),
                _usernameField(),
                const SizedBox(height: 16),
                _phoneField(),
                const SizedBox(height: 16),
                _emailField(),
                const SizedBox(height: 16),
                _dobField(),
                const SizedBox(height: 16),

                _plainField(
                  _nidNumberController,
                  'NID Number',
                  Icons.numbers_outlined,
                ),
                const SizedBox(height: 16),
                _plainField(
                  _addressController,
                  'Address',
                  Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                EnhancedAddressPicker(
                  addressController: _addressController,
                  onAddressChanged: (address, lat, lng) {
                    setState(() {
                      _selectedLat = lat;
                      _selectedLng = lng;
                    });
                  },
                ),
                const SizedBox(height: 16),

                /// ---------- IMAGES ----------
                _imageTile(
                  label: 'NID Front',
                  file: _nidFront,
                  onTap: () => _pickImage((f) => _nidFront = f),
                ),
                const SizedBox(height: 16),
                _imageTile(
                  label: 'Selfie',
                  file: _selfie,
                  onTap: () => _pickImage((f) => _selfie = f),
                ),
                const SizedBox(height: 16),

                /// ---------- PASSWORD ----------
                _passwordField(),
                const SizedBox(height: 16),
                _confirmPasswordField(),
                const SizedBox(height: 24),

                /// ---------- SUBMIT ----------
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.pink, width: 2),
                      ),
                    ),
                    onPressed: _handleRegister,
                    child: const Text(
                      'REGISTER',
                      style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------- Field builders ----------------
  Widget _nameField(TextEditingController c, String label, {String? error}) =>
      TextFormField(
        controller: c,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? (error ?? 'Please enter $label')
            : null,
      );

  Widget _usernameField() => TextFormField(
    controller: _usernameController,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Username',
      prefixIcon: Icon(Icons.person_outline),
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
        return 'Please enter a username';
      }
      if (v.trim().length < 6) {
        return 'Username must be at least 6 characters';
      }
      return null;
    },
  );

  Widget _phoneField() => TextFormField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Phone Number',
      prefixIcon: Icon(Icons.phone_outlined),
      hintText: '01XXXXXXXXX',
    ),
    validator: (v) {
      if (v == null || v.trim().isEmpty) {
        return 'Please enter your phone number';
      }
      // Bangladeshi phone number validation
      final phoneRegex = RegExp(r'^01[3-9]\d{8}$');
      if (!phoneRegex.hasMatch(v.trim())) {
        return 'Enter a valid Bangladeshi phone number (01XXXXXXXXX)';
      }
      return null;
    },
  );

  Widget _plainField(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) => TextFormField(
    controller: c,
    maxLines: maxLines,
    decoration: InputDecoration(
      border: const OutlineInputBorder(),
      labelText: label,
      prefixIcon: Icon(icon),
    ),
    validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
  );

  Widget _emailField() => TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Email',
      prefixIcon: Icon(Icons.email_outlined),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Please enter your email';
      // simplified RFC 5322-ish email check
      const pattern = r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$";
      return RegExp(pattern).hasMatch(v) ? null : 'Enter a valid email';
    },
  );

  Widget _dobField() => TextFormField(
    controller: _dobController,
    readOnly: true,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Date of Birth',
      prefixIcon: Icon(Icons.calendar_today_outlined),
    ),
    onTap: () async {
      FocusScope.of(context).unfocus();

      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDob ?? DateTime(now.year - 18),
        firstDate: DateTime(1900),
        lastDate: now,
      );

      if (picked != null) {
        setState(() {
          _selectedDob = picked;
          _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
        });
      }
    },
    validator: (v) =>
        (v == null || v.isEmpty) ? 'Please select your date of birth' : null,
  );

  Widget _passwordField() => TextFormField(
    controller: _passwordController,
    obscureText: true,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Password',
      prefixIcon: Icon(Icons.lock_outline),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Please enter a password';
      if (v.length < 6) return 'Password must be at least 6 characters';
      return null;
    },
  );

  Widget _confirmPasswordField() => TextFormField(
    controller: _confirmController,
    obscureText: true,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: 'Confirm Password',
      prefixIcon: Icon(Icons.lock_reset_outlined),
    ),
    validator: (v) =>
        (v != _passwordController.text) ? 'Passwords do not match' : null,
  );

  /// ---------------- Submit ----------------
  void _handleRegister() async {
    debugPrint('🔵 Register button tapped!');
    debugPrint('📝 Form validation starting...');

    // Check form validation first
    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint('❌ Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );
      return;
    }

    debugPrint('✅ Form validation passed');

    // Check required images
    if (_nidFront == null || _selfie == null) {
      debugPrint('❌ Missing required images');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all required images')),
      );
      return;
    }

    debugPrint('✅ Images validation passed');

    // Check location coordinates
    if (_selectedLat == null || _selectedLng == null) {
      debugPrint('❌ Missing location coordinates');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be detected'),
        ),
      );
      return;
    }

    debugPrint('✅ Location validation passed');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    debugPrint('🚀 Starting API call...');
    debugPrint('👤 Registration Data:');
    debugPrint('  First Name: ${_firstnameController.text.trim()}');
    debugPrint('  Last Name: ${_lastnameController.text.trim()}');
    debugPrint('  Username: ${_usernameController.text.trim()}');
    debugPrint('  Email: ${_emailController.text.trim()}');
    debugPrint('  Phone: ${_phoneController.text.trim()}');
    debugPrint('  DOB: ${DateFormat('yyyy-MM-dd').format(_selectedDob!)}');
    debugPrint('  NID: ${_nidNumberController.text.trim()}');
    debugPrint('  Address: ${_addressController.text.trim()}');
    debugPrint('  Lat: $_selectedLat, Lng: $_selectedLng');
    debugPrint('  NID Front: ${_nidFront?.path}');
    debugPrint('  Selfie: ${_selfie?.path}');

    try {
      await registerUser(
        firstName: _firstnameController.text.trim(),
        lastName: _lastnameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        dob: DateFormat('yyyy-MM-dd').format(_selectedDob!),
        nidNumber: _nidNumberController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLat!,
        longitude: _selectedLng!,
        nidFront: File(_nidFront!.path),
        selfie: File(_selfie!.path),
        password: _passwordController.text.trim(),
      );

      // Dismiss loading dialog
      Navigator.of(context).pop();

      debugPrint('✅ Registration successful!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      // Dismiss loading dialog
      Navigator.of(context).pop();

      debugPrint('❌ Registration failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
