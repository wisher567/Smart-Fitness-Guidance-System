import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:fitfusion/services/auth_service.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/splash_screen.dart';
import 'package:fitfusion/providers/theme_provider.dart';
import 'package:fitfusion/providers/workout_provider.dart';
import 'package:fitfusion/providers/nutrition_provider.dart';
import 'package:fitfusion/providers/location_provider.dart';
import 'package:fitfusion/providers/hydration_provider.dart';
import 'package:fitfusion/providers/calorie_provider.dart';
import 'package:fitfusion/providers/posture_provider.dart';
import 'package:fitfusion/providers/body_map_provider.dart';

/// Global RouteObserver — allows any screen to subscribe to
/// back-navigation events via the RouteAware mixin.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Added ThemeProvider
        Provider<ApiService>(
          create: (_) => ApiService.instance,
        ),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => HydrationProvider()),
        ChangeNotifierProvider(create: (_) => CalorieProvider()),
        ChangeNotifierProvider(create: (_) => PostureProvider()),
        ChangeNotifierProvider(create: (_) => BodyMapProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FitFusion',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode, // Listen to theme changes
            // ================= LIGHT THEME =================
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFE7235),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              textTheme: GoogleFonts.interTextTheme(),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFF8F9FA),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black87),
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: _elevatedButtonTheme(),
              inputDecorationTheme: _inputDecorationTheme(isDark: false),
            ),
            // ================= DARK THEME =================
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFE7235),
                brightness: Brightness.dark,
                surface: const Color(0xFF1A1A1A),
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF121212),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: _elevatedButtonTheme(),
              inputDecorationTheme: _inputDecorationTheme(isDark: true),
            ),
            home: const SplashScreen(),
            navigatorObservers: [routeObserver],
          );
        },
      ),
    );
  }

  ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFE7235),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    final fillColor = isDark ? const Color(0xFF2B2B2B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFE7235), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }
}
