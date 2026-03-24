import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'user_role.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMSCE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5F7A)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<UserRole?> _getUserRole(String email) async {
    // Check students collection
    final studentQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (studentQuery.docs.isNotEmpty) {
      return UserRole.student;
    }

    // Check teachers collection
    final teacherQuery = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (teacherQuery.docs.isNotEmpty) {
      return UserRole.teacher;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, determine role by searching collections
          return FutureBuilder<UserRole?>(
            future: _getUserRole(snapshot.data!.email!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              
              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                if (roleSnapshot.data == UserRole.student) {
                  return const StudentDashboard();
                } else if (roleSnapshot.data == UserRole.teacher) {
                  return const TeacherDashboard();
                }
              }
              
              // If role not found in either collection, sign out and go to login
              FirebaseAuth.instance.signOut();
              return const LoginScreen();
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Image.asset(
                  'assets/logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Attendance Management\nSystem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.8,
                  height: 1.2,
                ),
              ),
              const Spacer(flex: 3),
              const Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF1A5F7A),
                  ),
                  SizedBox(height: 20),
                  const Text(
                    'Loading....',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }
}
