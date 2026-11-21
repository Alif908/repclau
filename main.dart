import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:money_target/view/homepage.dart';
import 'package:money_target/view/login_page.dart';
import 'package:money_target/view/create_account_page.dart';
import 'package:money_target/view/target_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Target',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD32F2F),
          secondary: Color(0xFFEF5350),
          surface: Color(0xFF141414),
          background: Color(0xFF0A0A0A),
          error: Color(0xFFEF5350),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFEEEEEE),
          onBackground: Color(0xFFEEEEEE),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141414),
          foregroundColor: Color(0xFFEEEEEE),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1C1C1C),
          contentTextStyle: TextStyle(color: Color(0xFFEEEEEE)),
        ),
      ),

      // ─── Auth Gate ───────────────────────────────────────────────
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0A0A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
              ),
            );
          }

          // Not logged in → Login
          if (!snapshot.hasData) {
            return const LoginPage();
          }

          // Logged in → Check if target is set in Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0A0A0A),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                  ),
                );
              }

              // Firestore doc ഇല്ലെങ്കിൽ target setup page
              if (!userSnap.hasData || !userSnap.data!.exists) {
                return const TargetSetupPage();
              }

              final data = userSnap.data!.data() as Map<String, dynamic>;
              final target = (data['target'] as num?)?.toDouble() ?? 0;

              // target 0 ആണെങ്കിൽ — completedTargets ഉണ്ടോ check ചെയ്യൂ
              // ✅ FIX: target complete ആയതിന് ശേഷം target=0 ആകുമ്പോൾ
              // completedTargets ഉണ്ടെങ്കിൽ HomePage-ൽ നിർത്തുക,
              // അല്ലെങ്കിൽ മാത്രം TargetSetupPage-ലേക്ക് redirect ചെയ്യുക
              if (target <= 0) {
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(snapshot.data!.uid)
                      .collection('completedTargets')
                      .limit(1)
                      .get(),
                  builder: (context, completedSnap) {
                    if (completedSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        backgroundColor: Color(0xFF0A0A0A),
                        body: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      );
                    }
                    // completedTargets ഉണ്ടെങ്കിൽ → HomePage (dialog കാണിക്കും)
                    if (completedSnap.data != null &&
                        completedSnap.data!.docs.isNotEmpty) {
                      return const HomePage();
                    }
                    // completedTargets ഇല്ലെങ്കിൽ → TargetSetupPage
                    return const TargetSetupPage();
                  },
                );
              }

              // target set ആണെങ്കിൽ → Home
              return const HomePage();
            },
          );
        },
      ),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const CreateAccountPage(),
        '/home': (context) => const HomePage(),
        '/target': (context) => const TargetSetupPage(),
      },
    );
  }
}
