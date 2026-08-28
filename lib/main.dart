import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDTF6W7UYR3uANmEEd3MZx6QgBNTYgT9ho",
        authDomain: "appsaude-d6c3b.firebaseapp.com",
        projectId: "appsaude-d6c3b",
        storageBucket: "appsaude-d6c3b.firebasestorage.app",
        messagingSenderId: "423283625845",
        appId: "1:423283625845:web:328ee931edc4a290dccd3c",
      ),
    );
  } catch (error) {
    debugPrint('Firebase não foi inicializado: $error');
  }
  runApp(const SistemaSaudeApp());
}

class SistemaSaudeApp extends StatelessWidget {
  const SistemaSaudeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Único de Saúde - System Of Down',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
