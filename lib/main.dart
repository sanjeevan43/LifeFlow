import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  // Initialize Notifications
  await NotificationService.initialize();
  
  // Initialize Voice Service (only on mobile platforms)
  if (!kIsWeb) {
    await VoiceService.initialize((command) {
      // Handle background voice commands
    });
  }

  runApp(const LifeFlowApp());
}

class LifeFlowApp extends StatelessWidget {
  const LifeFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeFlow - Daily Reminder & Habit Helper',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        // Primary colors
        primaryColor: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: const Color(0xFF121212),
        // Color scheme with VISIBLE colors
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1E1E1E),      // Visible dark gray, NOT transparent
          background: Color(0xFF121212),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,         // White text on surfaces
          onBackground: Colors.white,      // White text on background
        ),
        // Card theme - VISIBLE cards
        cardTheme: CardTheme.of(context).copyWith(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // Text theme - ensure all text is visible
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Bottom navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF00E5FF),
          unselectedItemColor: Colors.white54,
        ),
        // List tile
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white70,
        ),
        // Icon theme
        iconTheme: const IconThemeData(color: Colors.white),
        // Checkbox theme
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(const Color(0xFF6C63FF)),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Deep Navy
            Color(0xFF1E1B4B), // Indigo
            Color(0xFF312E81), // Deep Purple
          ],
        ),
      ),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasData) {
            _ensureUserProfileAndNotifications(snapshot.data!);
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }

  Future<void> _ensureUserProfileAndNotifications(User user) async {
    // Ensure user profile exists
    final doc = await FirebaseService.getUserProfile(user.uid);
    if (!doc.exists) {
        await FirebaseService.createUserProfile(user.uid, {
          'email': user.email,
          'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        });
    }
    
    // Auto-register for push notifications (saves FCM token to Firestore)
    await NotificationService.registerUserForNotifications();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5), width: 2),
              ),
              child: const Icon(Icons.task_alt, size: 70, color: Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 32),
            const Text(
              'LifeFlow', 
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0)
            ),
            const SizedBox(height: 8),
            Text(
              'Stay organized, stay productive', 
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5), width: 2),
              ),
              child: const Icon(Icons.task_alt, size: 50, color: Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFF00E5FF)),
            const SizedBox(height: 24),
            const Text(
              'Aligning your flow...', 
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)
            ),
          ],
        ),
      ),
    );
  }
}
