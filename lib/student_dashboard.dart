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
                IconButton(
                  icon: const Icon(Icons.notifications_none, size: 26, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Page Content
          Expanded(
            child: _pages[_selectedIndex],
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
              .collection('courses')
              .where('department_id', isEqualTo: dept)
              .where('semester_id', isEqualTo: sem)
              .snapshots(),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (courseSnapshot.hasError) {
              return Center(child: Text("Error: ${courseSnapshot.error}"));
            }
            if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "No courses found for your department and semester.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: courseSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var course = courseSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 15.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15.0),
                    title: Text(
                      course['course_name'] ?? 'Unknown Course',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text("Code: ${course['course_code'] ?? 'N/A'}", style: const TextStyle(color: Colors.black54)),
                        Text("Credits: ${course['credits'] ?? 'N/A'}", style: const TextStyle(color: Color(0xFF1A5F7A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A5F7A).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Credits: ${course['credits'] ?? '-'}",
                        style: const TextStyle(color: Color(0xFF1A5F7A), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .where('department_id', isEqualTo: dept)
              .where('semester_id', isEqualTo: sem)
              .snapshots(),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No courses found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15.0),
              itemCount: courseSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var course = courseSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                String courseCode = course['course_code'] ?? '';
                String courseName = course['course_name'] ?? '';

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('attendance')
                      .where('usn', isEqualTo: usn)
                      .where('course_code', isEqualTo: courseCode)
                      .snapshots(),
                  builder: (context, attendanceSnapshot) {
                    double percentage = 0.0;
                    if (attendanceSnapshot.hasData && attendanceSnapshot.data!.docs.isNotEmpty) {
                      int totalClasses = attendanceSnapshot.data!.docs.length;
                      int presentClasses = attendanceSnapshot.data!.docs
                          .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Present')
                          .length;
                      percentage = (presentClasses / totalClasses) * 100;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceDetailScreen(
                                courseName: courseName,
                                courseCode: courseCode,
                                usn: usn,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(15.0),
                        title: Text(
                          courseName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text("Code: $courseCode", style: const TextStyle(color: Colors.black54)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${percentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: percentage >= 75 ? Colors.green : Colors.red,
                              ),
                            ),
                            const Text("Attendance", style: TextStyle(fontSize: 10)),
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
}

class AttendanceDetailScreen extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final String usn;

  const AttendanceDetailScreen({
    super.key,
    required this.courseName,
    required this.courseCode,
    required this.usn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('usn', isEqualTo: usn)
            .where('course_code', isEqualTo: courseCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No attendance records found."));
          }

          var docs = snapshot.data!.docs;
          docs.sort((a, b) => (b.data() as Map<String, dynamic>)['date']
              .compareTo((a.data() as Map<String, dynamic>)['date']));

          int total = docs.length;
          int present = docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Present').length;
          int absent = total - present;
          double percentage = (present / total) * 100;

          return Column(
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
              // List of classes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isPresent = data['status'] == 'Present';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                        title: Text(data['date'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['start_time'] ?? 'N/A'} - ${data['end_time'] ?? 'N/A'}"),
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
      // 1. Upload to Storage (overwriting existing file for the email)
      final storageRef = FirebaseStorage.instance.ref().child('students_profiles/$currentEmail');
      await storageRef.putFile(File(image.path));
      final String downloadUrl = await storageRef.getDownloadURL();

      // 2. Update Firestore
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
