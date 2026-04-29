import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../seeker/seeker_main_screen.dart';
import '../../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController =
      TextEditingController();
  final TextEditingController passController =
      TextEditingController();

  /// 🔥 ADDED
  final GoogleAuthService _googleAuth = GoogleAuthService();

  bool _obscurePassword = true;
  bool isLoading = false;
  String selectedRole = "seeker";

  final Color inputTextColor =
      const Color(0xFF0F172A);

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passController.text.trim();

      final uc = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = uc.user!.uid;

      final doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        throw Exception("User profile not found");
      }

      final data = doc.data()!;

      final userType =
          (data['role'] ?? data['userType'] ?? 'seeker')
              .toString();

      if (selectedRole != userType) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logged in as $userType"),
          ),
        );
      }

      if (!mounted) return;

      if (userType == 'seeker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SeekerMainScreen(),
          ),
        );
      } else if (userType == 'employer') {
        Navigator.pushReplacementNamed(
          context,
          '/employer',
        );
      } else {
        throw Exception("Invalid user role");
      }

    } on FirebaseAuthException catch (e) {
      String msg = "Login failed";

      if (e.code == 'user-not-found') {
        msg = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        msg = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email format.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// 🔥 GOOGLE LOGIN FUNCTION (ADDED)
  Future<void> handleGoogleLogin() async {
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
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeeker =
        selectedRole == "seeker";

    final Color activeColor =
        isSeeker
            ? Theme.of(context)
                .colorScheme
                .primary
            : const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 24),
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                      maxWidth: 420),
              child: Column(
                children: [

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 130,
                    child: Image.asset(
                      'assets/tieora_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Please enter your details to sign in",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blueGrey,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Container(
                          height: 50,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _roleButton("seeker","Seeker",isSeeker,activeColor),
                              _roleButton("employer","Employer",!isSeeker,activeColor),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              _label("Email Address"),
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: emailController,
                                decoration: _inputDecoration(
                                  "name@company.com",
                                  Icons.mail_outline_rounded,
                                ),
                              ),

                              const SizedBox(height: 20),

                              _label("Password"),
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: passController,
                                obscureText: _obscurePassword,
                                decoration: _inputDecoration(
                                  "••••••••",
                                  Icons.lock_outline_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ? null : loginUser,
                            child: const Text("Sign In"),
                          ),
                        ),

                        /// 🔥 GOOGLE BUTTON (ONLY ADDITION)
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: handleGoogleLogin,
                            child: const Text("Continue with Google"),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text("New to Tieora? "),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushReplacementNamed(context, '/register'),
                                child: Text(
                                  "Create Account",
                                  style: TextStyle(
                                    color: activeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _roleButton(String role,String title,bool isActive,Color activeColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() =>
                selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive
                  ? activeColor
                  : Colors.blueGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
        fontSize: 14,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}