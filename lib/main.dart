import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/presetup_login_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sites_screen.dart';
import 'screens/networks_screen.dart';
import 'screens/password_change_screen.dart';

void main() {
  runApp(const UnifiPasswordChangerApp());
}

class UnifiPasswordChangerApp extends StatelessWidget {
  const UnifiPasswordChangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unifi WPA',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Modern UI elements
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: const LoginScreen(), // Start with regular login screen
      routes: {
        '/app-login': (context) => const PresetupLoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/sites': (context) => const SitesScreen(),
        '/networks': (context) => const NetworksScreen(),
        '/change-password': (context) => const PasswordChangeScreen(),
      },
    );
  }
}