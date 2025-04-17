import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _agreedToTnC = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTnC) {
      _showSnackbar("Please agree to the Terms and Conditions", Colors.red);
      return;
    }

    var fullname = fullnameController.text.trim();
    var email = emailController.text.trim();
    var phoneNumber = phoneController.text.trim();
    var income = incomeController.text.trim();
    var address = addressController.text.trim();
    var password = passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "fullname": fullname,
        "email": email,
        "phone": phoneNumber,
        "income": income,
        "address": address,
        "createdAt": Timestamp.now(),
      });

      _showSnackbar("User registered successfully!", Colors.green);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      _showSnackbar("Registration failed: ${e.toString()}", Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  void _showTermsDialog() {
    String fullname = fullnameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String income = incomeController.text.trim();
    String address = addressController.text.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Review Your Details & Terms"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Please confirm the following details:\n", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("👤 Full Name: $fullname"),
              Text("📧 Email:     $email"),
              Text("📱 Phone:     $phone"),
              Text("💰 Income:    ₹$income"),
              Text("🏠 Address:   $address"),
              SizedBox(height: 20),
              Text("By creating an account, you agree to the following:\n", style: TextStyle(fontWeight: FontWeight.bold)),
              Text('''
• You confirm that all information provided is accurate.
• You consent to the use of your data for the purpose of service delivery.
• You agree not to misuse or exploit the app or its content.
• You acknowledge that violating terms may result in account suspension.
''', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Edit Details"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _agreedToTnC = true;
              });
              Navigator.of(context).pop();
            },
            child: Text("I Confirm & Agree"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/login_bg.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 30),
                        FadeInDown(
                          duration: Duration(milliseconds: 700),
                          child: Text(
                            "Create Account",
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 20),

                        FadeInLeft(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: fullnameController,
                            hintText: "Full Name",
                            icon: Icons.person,
                            validator: (value) => value!.isEmpty ? "Enter your full name" : null,
                          ),
                        ),
                        SizedBox(height: 15),

                        FadeInRight(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: emailController,
                            hintText: "Email",
                            icon: Icons.email,
                            validator: (value) {
                              if (value!.isEmpty) return "Enter your email";
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "Enter a valid email";
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 15),

                        FadeInLeft(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: phoneController,
                            hintText: "Phone Number",
                            icon: Icons.phone,
                            validator: (value) {
                              if (value!.isEmpty) return "Enter your phone number";
                              if (!RegExp(r'^\d{10}$').hasMatch(value)) return "Enter a valid 10-digit number";
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 15),

                        FadeInRight(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: incomeController,
                            hintText: "Net Income",
                            icon: Icons.currency_rupee,
                            validator: (value) {
                              if (value!.isEmpty) return "Enter your income";
                              if (!RegExp(r'^\d+$').hasMatch(value)) return "Enter a valid income amount";
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 15),

                        FadeInLeft(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: addressController,
                            hintText: "Residential Address",
                            icon: Icons.home,
                            validator: (value) => value!.isEmpty ? "Enter your address" : null,
                          ),
                        ),
                        SizedBox(height: 15),

                        FadeInRight(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: passwordController,
                            hintText: "Password",
                            icon: Icons.lock,
                            obscureText: true,
                            validator: (value) {
                              if (value!.isEmpty) return "Enter a password";
                              if (value.length < 6) return "Password must be at least 6 characters";
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 15),

                        FadeInLeft(
                          duration: Duration(milliseconds: 700),
                          child: _buildTextField(
                            controller: confirmPasswordController,
                            hintText: "Confirm Password",
                            icon: Icons.lock,
                            obscureText: true,
                            validator: (value) {
                              if (value!.isEmpty) return "Confirm your password";
                              if (passwordController.text.isNotEmpty && value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 15),

                        Row(
                          children: [
                            Checkbox(
                              value: _agreedToTnC,
                              onChanged: null,
                              activeColor: Colors.tealAccent.shade700,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showTermsDialog,
                                child: Text(
                                  "I agree to the Terms and Conditions",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        BounceInUp(
                          duration: Duration(milliseconds: 900),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              backgroundColor: Colors.tealAccent.shade700,
                              elevation: 10,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    "Sign Up",
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        SizedBox(height: 20),

                        FadeIn(
                          duration: Duration(milliseconds: 800),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Already have an account? Login",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: hintText,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }
}
