import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/services/auth_service.dart';
import 'package:fitfusion/welcome_screen.dart';
import 'package:fitfusion/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    final auth = Provider.of<AuthService>(context, listen: false);

    if (auth.isLoggedIn) {
      // If we don't have the user model yet, wait for it
      if (auth.userModel == null && auth.isLoading) {
        while (auth.isLoading && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (!mounted) return;

      if (auth.isAdmin || auth.isTrainer) {
        await auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.isAdmin
              ? 'Admins please use the web portal'
              : 'Trainers please use the web portal'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFE7235),
      body: Center(child: Image.asset("assets/Logo.png", width: 250)),
    );
  }
}
