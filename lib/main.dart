import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
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
      home: const BiometricGuard(child: AuthWrapper()),
    );
  }
}

class BiometricGuard extends StatefulWidget {
  final Widget child;
  const BiometricGuard({super.key, required this.child});

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard> with WidgetsBindingObserver {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _shouldAutoAuthenticate = true; // Added flag to prevent loops

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only auto-prompt if we haven't tried yet for this "resume" session
      if (!_isAuthenticated && !_isAuthenticating && _shouldAutoAuthenticate) {
        _authenticate();
      }
    } else if (state == AppLifecycleState.paused) {
      setState(() {
        _isAuthenticated = false;
        _shouldAutoAuthenticate = true; // Reset so it prompts on next return
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _shouldAutoAuthenticate = false; // Prevent auto-loops immediately
    });
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If device doesn't support biometrics, allow access (or you could require a PIN)
        setState(() {
          _isAuthenticated = true; 
          _isAuthenticating = false;
        });
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access AMS BMSCE',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern fallback if biometrics fail or aren't set
        ),
      );
      
      setState(() {
        _isAuthenticated = didAuthenticate;
        _isAuthenticating = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

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
              Image.asset('assets/logo.png', width: 150),
              const SizedBox(height: 40),
              const Icon(Icons.lock_outline, size: 80, color: Color(0xFF1A5F7A)),
              const SizedBox(height: 20),
              const Text(
                'AMS Locked',
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF2C3E50)
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Authentication required to continue',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('UNLOCK APP', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5F7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        ],
      ),
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
                  Text(
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
