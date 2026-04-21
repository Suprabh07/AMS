import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
    const Center(child: Text('Marks Screen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
              image: DecorationImage(
                image: AssetImage('assets/Top_Background.jpg'),
                fit: BoxFit.cover,
              ),
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
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_selectedIndex == 0)
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 26, color: Colors.white),
                    onPressed: () {},
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

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, size: 45, color: Color(0xFF1A5F7A));
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                },
                              )
                            : const Icon(Icons.person, size: 45, color: Color(0xFF1A5F7A)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['name'] ?? 'Student', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                          const SizedBox(height: 5),
                          Text(
                            'USN: ${userData['usn'] ?? 'N/A'} | ${userData['department_id'] ?? 'Dept'} | Sem: ${userData['semester_id'] ?? 'N/A'} | Sec: ${userData['section'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
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
        );
      },
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
      body: Column(
        children: [
          // Header with Image background
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Top_Background.jpg'),
                fit: BoxFit.cover,
              ),
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            courseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Course Code: $courseCode",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                  image: DecorationImage(
                    image: AssetImage('assets/Top_Background.jpg'),
                    fit: BoxFit.cover,
                  ),
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            courseName,
                            style: const TextStyle(
                              color: Colors.white,
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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
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
