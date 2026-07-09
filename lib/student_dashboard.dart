import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const StudentHome(),
    const StudentCourses(),
    const StudentAttendance(),
    const StudentMarks(),
    const StudentProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Persistent Header for all tabs
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10.0,
              bottom: 10.0,
              left: 20.0,
              right: 10.0,
            ),
            child: Row(
              children: [
                Image.asset('assets/logo.png', height: 40),
                const SizedBox(width: 10),
                Text(
                  _getAppBarTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                if (_selectedIndex == 0)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        return NotificationIcon(
                          usn: data['usn'] ?? '',
                          dept: data['department_id'] ?? '',
                          sem: data['semester_id'] ?? '',
                          section: data['section'] ?? '',
                        );
                      }
                      return const IconButton(
                        icon: Icon(Icons.notifications_none, size: 26, color: Color(0xFF2C3E50)),
                        onPressed: null,
                      );
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          // Page Content with Smooth Transition
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _pages,
            ),
          ),
        ],
      ),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Courses'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in), label: 'Marks'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
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
      case 0: return 'BMSCE';
      case 1: return 'My Courses';
      case 2: return 'Attendance';
      case 3: return 'Marks Cards';
      case 4: return 'Profile';
      default: return 'BMSCE';
    }
  }
}

class NotificationIcon extends StatefulWidget {
  final String usn;
  final String dept;
  final String sem;
  final String section;

  const NotificationIcon({
    super.key,
    required this.usn,
    required this.dept,
    required this.sem,
    required this.section,
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wiggleAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasWarning = false;
  List<Map<String, dynamic>> _lowAttendanceData = [];
  StreamSubscription? _attendanceSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _wiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _listenToAttendance();
  }

  void _listenToAttendance() {
    FirebaseFirestore.instance
        .collection('student_course_mappings')
        .where('student_dept', isEqualTo: widget.dept)
        .where('student_sem', isEqualTo: widget.sem)
        .get()
        .then((mappingSnap) {
      if (!mounted) return;
      List<String> studentCourses = mappingSnap.docs.map((d) => d['course_code'] as String).toList();

      _attendanceSubscription = FirebaseFirestore.instance
          .collection('attendance')
          .where('s', isEqualTo: widget.section)
          .snapshots()
          .listen((attSnap) async {
        Map<String, Map<String, List<bool>>> stats = {};

        for (var doc in attSnap.docs) {
          String courseCode = doc['cc'];
          if (!studentCourses.contains(courseCode)) continue;

          String type = doc['t'];
          List presentUsns = doc['present_usns'] ?? [];
          bool isPresent = presentUsns.contains(widget.usn);

          stats.putIfAbsent(courseCode, () => {});
          stats[courseCode]!.putIfAbsent(type, () => []);
          stats[courseCode]![type]!.add(isPresent);
        }

        List<Map<String, dynamic>> lowAtt = [];
        bool warningFound = false;

        for (var courseEntry in stats.entries) {
          String courseCode = courseEntry.key;
          for (var typeEntry in courseEntry.value.entries) {
            String type = typeEntry.key;
            List<bool> attendanceList = typeEntry.value;
            
            int total = attendanceList.length;
            int present = attendanceList.where((p) => p).length;
            double percentage = (present / total) * 100;

            if (percentage < 75) {
              warningFound = true;
              
              // Fetch course name for better display
              var courseSnap = await FirebaseFirestore.instance
                  .collection('courses')
                  .where('course_code', isEqualTo: courseCode)
                  .limit(1)
                  .get();
              
              String courseName = courseSnap.docs.isNotEmpty 
                  ? courseSnap.docs.first['course_name'] 
                  : courseCode;

              lowAtt.add({
                'course': courseName,
                'code': courseCode,
                'type': type,
                'percentage': percentage.toStringAsFixed(1),
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            _hasWarning = warningFound;
            _lowAttendanceData = lowAtt;
          });
          if (_hasWarning) {
            _controller.repeat(reverse: true);
          } else {
            _controller.stop();
            _controller.reset();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showNotifications() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NotificationsScreen(notifications: _lowAttendanceData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _hasWarning ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: _hasWarning ? _wiggleAnimation.value : 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _hasWarning ? Icons.notifications_active : Icons.notifications_none,
                    size: 26,
                    color: _hasWarning ? Colors.orangeAccent : const Color(0xFF2C3E50),
                  ),
                  onPressed: _showNotifications,
                ),
                if (_hasWarning)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _lowAttendanceData.length.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Error loading data"));
        }

        var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        String? profileUrl = userData['profile_url'];
        String name = userData['name'] ?? 'Student';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: ClipOval(
                        child: (profileUrl != null && profileUrl.toString().trim().isNotEmpty)
                            ? Image.network(
                                profileUrl.toString().trim(),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 45, color: Color(0xFF1A5F7A)),
                              )
                            : const Icon(Icons.person, size: 45, color: Color(0xFF1A5F7A)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back,", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Summary Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Academic Profile", style: TextStyle(color: Color(0xFF2C3E50), fontSize: 16, fontWeight: FontWeight.bold)),
                      Divider(color: Colors.grey.shade200, height: 25),
                      _profileRow(Icons.fingerprint, "USN", userData['usn'] ?? 'N/A'),
                      _profileRow(Icons.school, "Department", userData['department_id'] ?? 'N/A'),
                      _profileRow(Icons.grid_view, "Semester & Section", "Sem ${userData['semester_id']} | Section ${userData['section']}"),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text("Performance Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  height: 400, // Explicit height for the analytics view
                  child: PerformanceScreen(
                    usn: userData['usn'] ?? '',
                    dept: userData['department_id'] ?? '',
                    sem: userData['semester_id'] ?? '',
                    section: userData['section'] ?? '',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A5F7A), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10)),
              Text(value, style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class StudentCourses extends StatelessWidget {
  const StudentCourses({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Student data not found"));
        }

        var studentData = studentSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        String dept = studentData['department_id'] ?? '';
        String sem = studentData['semester_id'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('student_course_mappings')
              .where('student_dept', isEqualTo: dept)
              .where('student_sem', isEqualTo: sem)
              .snapshots(),
          builder: (context, mappingSnapshot) {
            if (mappingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!mappingSnapshot.hasData || mappingSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No courses mapped to your department and semester."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: mappingSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var mapping = mappingSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                String courseCode = mapping['course_code'] ?? '';

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('courses')
                      .where('course_code', isEqualTo: courseCode)
                      .limit(1)
                      .get(),
                  builder: (context, courseSnapshot) {
                    if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    var courseData = courseSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    String courseName = courseData['course_name'] ?? 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseDetailScreen(
                                courseName: courseName,
                                courseCode: courseCode,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(15.0),
                        title: Text(
                          courseName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Code: $courseCode", style: const TextStyle(color: Colors.black54)),
                            Text("Credits: ${courseData['credits'] ?? 'N/A'}", style: const TextStyle(color: Color(0xFF1A5F7A), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class CourseDetailScreen extends StatelessWidget {
  final String courseName;
  final String courseCode;

  const CourseDetailScreen({
    super.key,
    required this.courseName,
    required this.courseCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with white background
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 20,
              left: 20,
              right: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            courseName,
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 48.0),
                      child: Text(
                        "Course Code: $courseCode",
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('teacher_mappings')
                      .where('course_code', isEqualTo: courseCode)
                      .get(),
                  builder: (context, mappingSnap) {
                    if (mappingSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (mappingSnap.hasData && mappingSnap.data!.docs.isNotEmpty) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: mappingSnap.data!.docs.length,
                        itemBuilder: (context, index) {
                          var mapping = mappingSnap.data!.docs[index].data() as Map<String, dynamic>;
                          String teacherId = mapping['teacher_id'];
                          String type = mapping['type'] ?? 'Theory';

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('teachers').doc(teacherId).get(),
                            builder: (context, teacherSnap) {
                              if (!teacherSnap.hasData || !teacherSnap.data!.exists) return const SizedBox.shrink();
                              var teacherData = teacherSnap.data!.data() as Map<String, dynamic>;
                              String? profileUrl = teacherData['profile_url'];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("$type Instructor", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A))),
                                      const Divider(),
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 30,
                                            backgroundImage: (profileUrl != null && profileUrl.isNotEmpty) ? NetworkImage(profileUrl) : null,
                                            child: (profileUrl == null || profileUrl.isEmpty) ? const Icon(Icons.person) : null,
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(teacherData['name'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                Text(teacherData['email'] ?? 'N/A', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    return const Center(child: Text("No instructor assigned yet."));
                  },
                ),
              ),
            ],
          ),
        );
      }

      Widget _infoRow(IconData icon, String label, String value) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1A5F7A), size: 24),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                ],
              ),
            ],
          ),
        );
      }
}

class StudentAttendance extends StatelessWidget {
  const StudentAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Student data not found"));
        }

        var studentData = studentSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        String usn = studentData['usn'] ?? '';
        String dept = studentData['department_id'] ?? '';
        String sem = studentData['semester_id'] ?? '';
        String section = studentData['section'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('student_course_mappings')
              .where('student_dept', isEqualTo: dept)
              .where('student_sem', isEqualTo: sem)
              .snapshots(),
          builder: (context, mappingSnapshot) {
            if (mappingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!mappingSnapshot.hasData || mappingSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No courses found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: mappingSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var mapping = mappingSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                String courseCode = mapping['course_code'] ?? '';

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('courses')
                      .where('course_code', isEqualTo: courseCode)
                      .limit(1)
                      .get(),
                  builder: (context, courseSnapshot) {
                    if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    var courseData = courseSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    String courseName = courseData['course_name'] ?? 'Unknown';
                    bool hasLab = courseData['has_lab'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("Code: $courseCode", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 15),
                            if (hasLab)
                              Row(
                                children: [
                                  Expanded(child: _attendanceTypeSummary(usn, section, courseCode, "Theory", true)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _attendanceTypeSummary(usn, section, courseCode, "Lab", true)),
                                ],
                              )
                            else
                              _attendanceTypeSummary(usn, section, courseCode, "Theory", true, isCentered: true),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _attendanceTypeSummary(String usn, String section, String courseCode, String type, bool showTypeLabel, {bool isCentered = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('cc', isEqualTo: courseCode)
          .where('s', isEqualTo: section)
          .where('t', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        double percentage = 0.0;
        int total = 0;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          total = snapshot.data!.docs.length;
          int present = snapshot.data!.docs.where((doc) {
            List presentUsns = doc.get('present_usns') ?? [];
            return presentUsns.contains(usn);
          }).length;
          percentage = (present / total) * 100;
        }

        if (total == 0) return const SizedBox.shrink();

        // Color Logic: >85 Green, 75-85 Yellow, <75 Red
        Color statusColor = Colors.green;
        if (percentage < 75) {
          statusColor = Colors.red;
        } else if (percentage <= 85) {
          statusColor = Colors.orange; // Yellow/Orange
        }

        return Center(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceDetailScreen(
                    courseName: showTypeLabel ? "$courseCode ($type)" : courseCode,
                    courseCode: courseCode,
                    usn: usn,
                    section: section,
                    type: type,
                  ),
                ),
              );
            },
            child: Container(
              width: isCentered ? double.infinity : null,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showTypeLabel) Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AttendanceDetailScreen extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final String usn;
  final String section;
  final String type;

  const AttendanceDetailScreen({
    super.key,
    required this.courseName,
    required this.courseCode,
    required this.usn,
    required this.section,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('cc', isEqualTo: courseCode)
            .where('s', isEqualTo: section)
            .where('t', isEqualTo: type)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No attendance records found."));
          }

          var docs = snapshot.data!.docs;
          docs.sort((a, b) => (b.data() as Map<String, dynamic>)['d']
              .compareTo((a.data() as Map<String, dynamic>)['d']));

          int total = docs.length;
          int present = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List presentUsns = data['present_usns'] ?? [];
            return presentUsns.contains(usn);
          }).length;
          int absent = total - present;
          double percentage = (present / total) * 100;

          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            courseName,
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem("Total", total.toString()),
                        _statItem("Present", present.toString()),
                        _statItem("Absent", absent.toString()),
                        _statItem("Percentage", "${percentage.toStringAsFixed(1)}%"),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    List presentUsns = data['present_usns'] ?? [];
                    bool isPresent = presentUsns.contains(usn);

                    int st = data['st'] ?? 0;
                    int et = data['et'] ?? 0;
                    String startTime = "${(st ~/ 60).toString().padLeft(2, '0')}:${(st % 60).toString().padLeft(2, '0')}";
                    String endTime = "${(et ~/ 60).toString().padLeft(2, '0')}:${(et % 60).toString().padLeft(2, '0')}";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                        title: Text(data['d'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$startTime - $endTime"),
                        trailing: Text(
                          isPresent ? "PRESENT" : "ABSENT",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPresent ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Color(0xFF1A5F7A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class PerformanceScreen extends StatefulWidget {
  final String usn;
  final String dept;
  final String sem;
  final String section;

  const PerformanceScreen({
    super.key,
    required this.usn,
    required this.dept,
    required this.sem,
    required this.section,
  });

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.calendar_today, size: 20), text: "Attendance"),
                Tab(icon: Icon(Icons.assignment_turned_in, size: 20), text: "Marks"),
              ],
              labelColor: const Color(0xFF2C3E50),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orangeAccent,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              children: [
                AttendanceAnalytics(usn: widget.usn, dept: widget.dept, sem: widget.sem, section: widget.section),
                MarksAnalytics(usn: widget.usn, dept: widget.dept, sem: widget.sem, section: widget.section),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceAnalytics extends StatelessWidget {
  final String usn;
  final String dept;
  final String sem;
  final String section;

  const AttendanceAnalytics({super.key, required this.usn, required this.dept, required this.sem, required this.section});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_course_mappings')
          .where('student_dept', isEqualTo: dept)
          .where('student_sem', isEqualTo: sem)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var courses = snapshot.data!.docs.map((d) => d['course_code'] as String).toList();
        
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchAllAttendance(courses),
          builder: (context, attSnapshot) {
            if (!attSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            var data = attSnapshot.data!;

            if (data.isEmpty) return const Center(child: Text("No attendance data available"));

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Subject-wise Attendance (%)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 30),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => const Color(0xFF2C3E50),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                "${data[groupIndex]['code']}\n",
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                    text: "${rod.toY.toStringAsFixed(1)}%",
                                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= data.length) return const Text("");
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Text(
                                      data[value.toInt()]['code'],
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barGroups: data.asMap().entries.map((entry) {
                          int idx = entry.key;
                          double percentage = entry.value['percentage'];
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: percentage,
                                color: percentage < 75 ? Colors.red : const Color(0xFF3B82F6),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLegend(Colors.red, "Below 75%"),
                  _buildLegend(const Color(0xFF3B82F6), "Above 75%"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllAttendance(List<String> courses) async {
    try {
      var snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('s', isEqualTo: section)
          .where('cc', whereIn: courses)
          .get();

      Map<String, List<DocumentSnapshot>> grouped = {};
      for (var doc in snap.docs) {
        String code = doc.get('cc');
        grouped.putIfAbsent(code, () => []).add(doc);
      }

      return courses.map((code) {
        var docs = grouped[code] ?? [];
        if (docs.isEmpty) return {'code': code, 'percentage': 0.0};
        
        int total = docs.length;
        int present = docs.where((doc) {
          List presentUsns = doc.get('present_usns') ?? [];
          return presentUsns.contains(usn);
        }).length;

        return {
          'code': code,
          'percentage': (present / total) * 100,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
      return [];
    }
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class MarksAnalytics extends StatelessWidget {
  final String usn;
  final String dept;
  final String sem;
  final String section;

  const MarksAnalytics({super.key, required this.usn, required this.dept, required this.sem, required this.section});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('student_course_mappings')
          .where('student_dept', isEqualTo: dept)
          .where('student_sem', isEqualTo: sem)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var courses = snapshot.data!.docs.map((d) => d['course_code'] as String).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchAllMarks(courses),
          builder: (context, marksSnapshot) {
            if (!marksSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            var data = marksSnapshot.data!;

            if (data.isEmpty) return const Center(child: Text("No marks data available"));

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Final CIE Marks (out of 50)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 30),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        groupsSpace: 20,
                        alignment: BarChartAlignment.center,
                        maxY: 50,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => const Color(0xFF2C3E50),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                "${data[groupIndex]['code']}\n",
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                    text: "${rod.toY.toStringAsFixed(1)} / 50",
                                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= data.length) return const Text("");
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Text(
                                      data[value.toInt()]['code'],
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barGroups: data.asMap().entries.map((entry) {
                          int idx = entry.key;
                          double cie = entry.value['cie'];
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: cie,
                                color: const Color(0xFFF59E0B),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Target: Minimum 20/50 required to pass CIE", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllMarks(List<String> courses) async {
    try {
      var snap = await FirebaseFirestore.instance
          .collection('marks')
          .where('student_id', isEqualTo: usn)
          .where('section', isEqualTo: section)
          .where('course_id', whereIn: courses)
          .get();

      Map<String, dynamic> marksMap = {
        for (var doc in snap.docs) doc.get('course_id'): doc.data()
      };

      return courses.map((code) {
        var data = marksMap[code];
        return {
          'code': code,
          'cie': (data?['cie_total'] ?? 0.0).toDouble(),
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching marks: $e");
      return [];
    }
  }
}

class StudentMarks extends StatelessWidget {
  const StudentMarks({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Student data not found"));
        }

        var studentData = studentSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        String usn = studentData['usn'] ?? '';
        String dept = studentData['department_id'] ?? '';
        String sem = studentData['semester_id'] ?? '';
        String section = studentData['section'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('student_course_mappings')
              .where('student_dept', isEqualTo: dept)
              .where('student_sem', isEqualTo: sem)
              .snapshots(),
          builder: (context, mappingSnapshot) {
            if (mappingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!mappingSnapshot.hasData || mappingSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No courses found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: mappingSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var mapping = mappingSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                String courseCode = mapping['course_code'] ?? '';

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('courses')
                      .where('course_code', isEqualTo: courseCode)
                      .limit(1)
                      .get(),
                  builder: (context, courseSnapshot) {
                    if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    var courseData = courseSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    String courseName = courseData['course_name'] ?? 'Unknown';
                    bool hasLab = courseData['has_lab'] ?? false;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('marks')
                          .doc("${courseCode}_${section}_$usn")
                          .snapshots(),
                      builder: (context, marksSnap) {
                        Map<String, dynamic> marks = {};
                        if (marksSnap.hasData && marksSnap.data!.exists) {
                          marks = marksSnap.data!.data() as Map<String, dynamic>;
                        }

                        double i1 = (marks['internal1_reduced'] ?? 0.0).toDouble();
                        double i2 = (marks['internal2_reduced'] ?? 0.0).toDouble();
                        double i3 = (marks['internal3_reduced'] ?? 0.0).toDouble();
                        double labOrQuiz = hasLab 
                            ? (marks['lab_exam_reduced'] ?? 0.0).toDouble()
                            : (marks['quiz_marks'] ?? 0.0).toDouble();
                        double aat = (marks['aat_marks'] ?? 0.0).toDouble();
                        double cieTotal = (marks['cie_total'] ?? 0.0).toDouble();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 15.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text("Code: $courseCode", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (marks.containsKey('grade')) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "Grade: ${marks['grade']}",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A5F7A),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "CIE: $cieTotal/50",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  children: [
                                    const Text("Performance Trend", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 180,
                                      child: LineChart(
                                        LineChartData(
                                          gridData: const FlGridData(show: false),
                                          titlesData: FlTitlesData(
                                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  switch (value.toInt()) {
                                                    case 0: return const Text("I1", style: TextStyle(fontSize: 10));
                                                    case 1: return const Text("I2", style: TextStyle(fontSize: 10));
                                                    case 2: return const Text("I3", style: TextStyle(fontSize: 10));
                                                    case 3: return Text(hasLab ? "Lab" : "Quiz", style: const TextStyle(fontSize: 10));
                                                    case 4: return const Text("AAT", style: TextStyle(fontSize: 10));
                                                  }
                                                  return const Text("");
                                                },
                                              ),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: [
                                                FlSpot(0, i1),
                                                FlSpot(1, i2),
                                                FlSpot(2, i3),
                                                FlSpot(3, labOrQuiz),
                                                FlSpot(4, aat),
                                              ],
                                              isCurved: true,
                                              color: const Color(0xFF1A5F7A),
                                              barWidth: 4,
                                              isStrokeCapRound: true,
                                              dotData: const FlDotData(show: true),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: const Color(0xFF1A5F7A).withAlpha(30),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _markComponent("I1", i1, hasLab ? 10 : 20),
                                        _markComponent("I2", i2, hasLab ? 10 : 20),
                                        _markComponent("I3", i3, hasLab ? 10 : 20),
                                        _markComponent(hasLab ? "Lab" : "Quiz", labOrQuiz, hasLab ? 25 : 5),
                                        _markComponent("AAT", aat, 5),
                                      ],
                                    ),
                                    if (marks.containsKey('see_marks')) ...[
                                      const SizedBox(height: 15),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(20),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blue.withAlpha(50)),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text("Semester End Exam (SEE)", style: TextStyle(fontWeight: FontWeight.w600)),
                                                Text("${marks['see_marks']}/100", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                              ],
                                            ),
                                            const Divider(height: 20),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text("Total (CIE + SEE/2)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Text("${marks['total_marks'] ?? '--'}/100", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A5F7A))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _markComponent(String label, dynamic value, int max) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? "--",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A)),
        ),
        Text("/$max", style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}




class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(String currentEmail, String docId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child('students_profiles/$currentEmail');
      await storageRef.putFile(File(image.path));
      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('students').doc(docId).update({
        'profile_url': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.width * 0.85,
              child: ClipOval(
                child: Container(
                  color: Colors.white,
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1A5F7A)));
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Error loading profile"));
        }

        var doc = snapshot.data!.docs.first;
        var userData = doc.data() as Map<String, dynamic>;
        String? profileUrl = userData['profile_url'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, profileUrl),
                      child: Hero(
                        tag: 'profile_pic',
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: ClipOval(
                            child: _isUploading 
                              ? const CircularProgressIndicator()
                              : (profileUrl != null && profileUrl.toString().trim().isNotEmpty)
                                ? Image.network(
                                    profileUrl.toString().trim(),
                                    width: 130,
                                    height: 130,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.account_circle, size: 130, color: Color(0xFF1A5F7A));
                                    },
                                  )
                                : const Icon(Icons.account_circle, size: 130, color: Color(0xFF1A5F7A)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadImage(user!.email!, doc.id),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1A5F7A),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _infoSection("Name", userData['name'] ?? 'N/A'),
              _infoSection("USN", userData['usn'] ?? 'N/A'),
              _infoSection("Email", userData['email'] ?? 'N/A'),
              _infoSection("Section", userData['section'] ?? 'N/A'),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}



class NotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const NotificationsScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No new notifications", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var data = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            color: Colors.red,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Low Attendance Warning",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${data['course']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Your ${data['type']} attendance is currently ${data['percentage']}%. A minimum of 75% is required.",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


