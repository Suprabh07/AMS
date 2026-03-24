import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StudentHome(),
    const Center(child: Text('Courses Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Attendance Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Marks Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    const StudentProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 
        ? null 
        : AppBar(
            title: Text(_getAppBarTitle()),
            backgroundColor: const Color(0xFF1A5F7A),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in_outlined),
              activeIcon: Icon(Icons.assignment_turned_in),
              label: 'Marks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1A5F7A),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'BMSCE Dashboard';
      case 1: return 'My Courses';
      case 2: return 'Attendance';
      case 3: return 'Marks Cards';
      case 4: return 'Student Profile';
      default: return 'BMSCE';
    }
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Error loading dashboard"));
        }

        var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header with Lighter Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4A90A4), // Lightened version of 1A5F7A
                        Color(0xFFA5E7EF), // Lightened version of 80DEEA
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  child: Row(
                    children: [
                      Image.asset('assets/logo.png', height: 40),
                      const SizedBox(width: 10),
                      const Text(
                        'BMSCE',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, size: 28, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Profile Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.person, size: 45, color: Color(0xFF1A5F7A)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userData['name'] ?? 'Student'}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'USN: ${userData['usn'] ?? 'N/A'} | ${userData['department_id'] ?? 'Dept'} | Sem: ${userData['semester_id'] ?? 'N/A'} | Sec: ${userData['section'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Error loading profile"));
        }

        var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.account_circle, size: 100, color: Color(0xFF1A5F7A)),
              ),
              const SizedBox(height: 30),
              _infoSection("Name", userData['name'] ?? 'N/A'),
              _infoSection("USN", userData['usn'] ?? 'N/A'),
              _infoSection("Email", userData['email'] ?? 'N/A'),
              _infoSection("Section", userData['section'] ?? 'N/A'),
            ],
          ),
        );
      },
    );
  }

  Widget _infoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}
