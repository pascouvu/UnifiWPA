import 'package:flutter/material.dart';
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
      title: 'Unifi Password Changer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/sites': (context) => const SitesScreen(),
        '/networks': (context) => const NetworksScreen(),
        '/change-password': (context) => const PasswordChangeScreen(),
      },
    );
  }
}