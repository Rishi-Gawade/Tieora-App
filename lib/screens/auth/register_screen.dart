import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/google_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passController = TextEditingController();
  final companyController = TextEditingController();

  final GoogleAuthService _googleAuth = GoogleAuthService();

  bool isLoading = false;
  String selectedRole = "seeker";
  bool _obscurePass = true;

  bool _agreeTerms = false; // 🔥 NEW

  GeoPoint? _locationGeo;
  String? _locationText;

  String _passwordStrength(String password) {
    if (password.length < 6) return "Weak";
    if (password.length < 10) return "Medium";
    return "Strong";
  }

  Color _strengthColor(String strength) {
    switch (strength) {
      case "Weak":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Strong":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }

      Position pos = await Geolocator.getCurrentPosition();

      setState(() {
        _locationGeo = GeoPoint(pos.latitude, pos.longitude);
        _locationText =
            "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location captured ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Privacy")),
      );
      return;
    }

    if (_locationGeo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location is required")),
      );
      return;
    }

    if (isLoading) return;

    if (_passwordStrength(passController.text) == "Weak") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password is too weak")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential uc = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      Map<String, dynamic> userData = {
        "uid": uc.user!.uid,
        "fullName": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "userType": selectedRole,
        "locationGeo": _locationGeo,
        "locationText": _locationText,
        "skills": [],
        "experienceLevel": "",
        "availability": "",
        "rating": 0,
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (selectedRole == "employer") {
        userData["companyName"] = companyController.text.trim();
        userData["employerType"] = "individual";
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uc.user!.uid)
          .set(userData);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          selectedRole == "seeker" ? '/seeker' : '/employer',
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> handleGoogleRegister() async {
    try {
      final user =
          await _googleAuth.signInWithGoogle(selectedRole);

      if (user == null) return;

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        selectedRole == 'seeker' ? '/seeker' : '/employer',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeeker = selectedRole == "seeker";

    final Color activeColor = isSeeker
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF6366F1);

    final strength = _passwordStrength(passController.text);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [

                  const SizedBox(height: 10),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _roleButton("seeker", "Seeker", isSeeker, activeColor),
                                _roleButton("employer", "Employer", !isSeeker, activeColor),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          _input(nameController, "Full Name"),
                          _input(emailController, "Email", isEmail: true),
                          _input(phoneController, "Phone"),

                          if (!isSeeker)
                            _input(companyController, "Company Name", isRequired: false),

                          _passwordField(),

                          /// 🔥 PASSWORD STRENGTH
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Strength: $strength",
                              style: TextStyle(
                                color: _strengthColor(strength),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// 🔥 TERMS CHECKBOX
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeTerms,
                                onChanged: (val) {
                                  setState(() => _agreeTerms = val ?? false);
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  "I agree to Terms & Privacy",
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _getLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Get Location"),
                            ),
                          ),

                          if (_locationText != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_locationText!),
                            ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Register",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: handleGoogleRegister,
                              child: const Text("Continue with Google"),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            "Your data is safe & encrypted",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: activeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint,
      {bool isEmail = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        validator: (v) {
          if (isRequired && (v == null || v.trim().isEmpty)) {
            return "$hint is required";
          }

          if (isEmail && v != null && v.isNotEmpty && !v.contains("@")) {
            return "Enter valid email";
          }

          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: passController,
        obscureText: _obscurePass,
        onChanged: (_) => setState(() {}),
        validator: (v) => v == null || v.length < 6 ? "Min 6 chars" : null,
        decoration: InputDecoration(
          hintText: "Password",
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: IconButton(
            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String role, String title, bool active, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}