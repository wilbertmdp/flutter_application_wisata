import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_wisata/home_screen.dart';
import 'package:flutter_application_wisata/sign_up_screen.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_getAuthErrorMessage(error.code));
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isValidEmail(String email) {
    String emailRegex =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";

    return RegExp(emailRegex).hasMatch(email);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak ditemukan';

      case 'wrong-password':
        return 'Password salah';

      case 'invalid-credential':
        return 'Email atau password salah';

      default:
        return 'Terjadi kesalahan ($code)';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset(
              'assets/signin_image.jpg',
              fit: BoxFit.cover,
            ),
          ),

          /// Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          /// Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.white.withOpacity(0.95),
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.lightBlue,
                          child: Icon(
                            Icons.landscape,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),

                        const SizedBox(height: 15),

                        const Text(
                          "EAWisata",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          "Masuk untuk menjelajahi destinasi wisata",
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        /// Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !_isValidEmail(value)) {
                              return 'Masukkan email yang valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        /// Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible =
                                      !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan password';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 25),

                        /// Button Login
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ElevatedButton(
                                  onPressed: _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "SIGN IN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        /// Sign Up
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            text: "Belum punya akun? ",
                            children: [
                              TextSpan(
                                text: "Daftar Sekarang",
                                style: const TextStyle(
                                  color: Colors.lightBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}