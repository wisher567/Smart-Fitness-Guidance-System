import 'dart:ui';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Background Image
          SizedBox.expand(
            child: Image.asset(
              "assets/background.jpg", // your background image
              fit: BoxFit.cover,
            ),
          ),

          /// Blur Effect
          SizedBox.expand(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                // ignore: deprecated_member_use
                color: Colors.black.withAlpha(77),
              ),
            ),
          ),

          /// Main White Card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Enter Password Text
                    const Text(
                      "Enter the new password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Password Field
                    _buildPasswordField(
                      controller: _passwordController,
                      obscureText: _obscure1,
                      onToggle: () {
                        setState(() {
                          _obscure1 = !_obscure1;
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    /// Verify Password Text
                    const Text(
                      "Verify the new password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Confirm Password Field
                    _buildPasswordField(
                      controller: _confirmController,
                      obscureText: _obscure2,
                      onToggle: () {
                        setState(() {
                          _obscure2 = !_obscure2;
                        });
                      },
                    ),

                    const SizedBox(height: 35),

                    /// Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          if (_passwordController.text ==
                              _confirmController.text) {
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Passwords do not match"),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Submit the new password",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Back Button (Top Left)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable Password Field Widget
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline),
          hintText: "****",
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}