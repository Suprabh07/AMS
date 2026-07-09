import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const TeacherHome(),
    const TeacherMarks(),
    const TeacherAttendanceMarking(),
    const TeacherProfile(),
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
          // Persistent Header
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
                // Bell icon only on Home (Dashboard)
                if (_selectedIndex == 0)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('teachers')
                        .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return TeacherNotificationIcon(teacherId: snapshot.data!.docs.first.id);
                      }
                      return const IconButton(
                        icon: Icon(Icons.notifications_none, size: 26, color: Colors.white),
                        onPressed: null,
                      );
                    },
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          // Page Content with Transitions
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
            BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in), label: 'Marks'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Attendance'),
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
      case 1: return 'Marks';
      case 2: return 'Attendance';
      case 3: return 'Profile';
      default: return 'BMSCE';
    }
  }
}

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, teacherSnapshot) {
        if (teacherSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (teacherSnapshot.hasError || !teacherSnapshot.hasData || teacherSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Error loading teacher data"));
        }

        var teacherDoc = teacherSnapshot.data!.docs.first;
        var teacherData = teacherDoc.data() as Map<String, dynamic>;
        String teacherId = teacherDoc.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: (teacherData['profile_url'] != null && teacherData['profile_url'].toString().trim().isNotEmpty)
                        ? NetworkImage(teacherData['profile_url'].toString().trim())
                        : null,
                    child: (teacherData['profile_url'] == null || teacherData['profile_url'].toString().trim().isEmpty)
                        ? const Icon(Icons.person, size: 45, color: Color(0xFF1A5F7A))
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacherData['name'] ?? 'Teacher', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        Text(
                          '${teacherData['department_id'] ?? 'N/A'} Department',
                          style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "My Assigned Courses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A)),
              ),
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('teacher_mappings')
                    .where('teacher_id', isEqualTo: teacherId)
                    .snapshots(),
                builder: (context, mappingSnapshot) {
                  if (mappingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (mappingSnapshot.hasError || !mappingSnapshot.hasData || mappingSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No assigned courses found."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(15.0),
                    itemCount: mappingSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var mapping = mappingSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                      String courseCode = mapping['course_code'] ?? '';
                      String section = mapping['section'] ?? '';
                      String type = mapping['type'] ?? 'Theory';

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('courses')
                            .where('course_code', isEqualTo: courseCode)
                            .limit(1)
                            .get(),
                        builder: (context, qSnap) {
                          String courseName = "Loading...";
                          bool hasLab = false;
                          if (qSnap.hasData && qSnap.data!.docs.isNotEmpty) {
                            var cData = qSnap.data!.docs.first.data() as Map<String, dynamic>;
                            courseName = cData['course_name'];
                            hasLab = cData['has_lab'] ?? false;
                          }

                          String displayLabel = hasLab ? " ($type)" : "";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 15.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15.0),
                              title: Text(
                                courseName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text("Code: $courseCode$displayLabel", style: const TextStyle(color: Colors.black54)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A5F7A).withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Section: $section",
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class TeacherAttendanceMarking extends StatefulWidget {
  const TeacherAttendanceMarking({super.key});

  @override
  State<TeacherAttendanceMarking> createState() => _TeacherAttendanceMarkingState();
}

class _TeacherAttendanceMarkingState extends State<TeacherAttendanceMarking> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedCourse;
  String? _selectedSection;
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 55);
  
  Map<String, bool> _attendance = {}; // USN -> Present/Absent
  bool _isLoadingStudents = false;
  bool _showHistory = false;
  String? _editingDocId;

  void _markAll(bool status) {
    setState(() {
      _attendance.updateAll((key, value) => status);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedCourse == null || _selectedSection == null || _selectedType == null || _attendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete selection')));
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = "${_startTime.hour.toString().padLeft(2, '0')}${_startTime.minute.toString().padLeft(2, '0')}";
    
    // Use existing doc ID if editing, else create a new unique one
    final docId = _editingDocId ?? "${_selectedCourse}_${_selectedSection}_${_selectedType}_${dateStr.replaceAll('-', '')}_$timeStr";

    final presentUsns = _attendance.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final st = _startTime.hour * 60 + _startTime.minute;
    final et = _endTime.hour * 60 + _endTime.minute;

    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
        'cc': _selectedCourse,
        'd': dateStr,
        's': _selectedSection,
        't': _selectedType,
        'present_usns': presentUsns,
        'st': st,
        'et': et,
        'marked_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSuccessAnimation();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(_editingDocId == null ? "Attendance Submitted!" : "Attendance Updated!",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        setState(() {
          _selectedCourse = null; // This will reset view to selection menu
          _editingDocId = null;
          _showHistory = false;
          _attendance.clear();
        });
      }
    });
  }

  void _loadForEditing(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    setState(() {
      _selectedDate = DateFormat('yyyy-MM-dd').parse(data['d']);
      int st = data['st'];
      int et = data['et'];
      _startTime = TimeOfDay(hour: st ~/ 60, minute: st % 60);
      _endTime = TimeOfDay(hour: et ~/ 60, minute: et % 60);
      
      List presentUsns = data['present_usns'] ?? [];
      _attendance.forEach((usn, _) {
        _attendance[usn] = presentUsns.contains(usn);
      });

      _editingDocId = doc.id;
      _showHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, teacherSnapshot) {
        if (!teacherSnapshot.hasData || teacherSnapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        String teacherId = teacherSnapshot.data!.docs.first.id;

        return Column(
          children: [
            // Selection Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teacher_mappings')
                  .where('teacher_id', isEqualTo: teacherId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var mappings = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCourse != null ? "${_selectedCourse}_${_selectedSection}_${_selectedType}" : null,
                    decoration: const InputDecoration(labelText: "Select Course & Section", border: OutlineInputBorder()),
                    items: mappings.map((m) {
                      var data = m.data() as Map<String, dynamic>;
                      String c = data['course_code'] ?? '';
                      String s = data['section'] ?? '';
                      String t = data['type'] ?? 'Theory';
                      return DropdownMenuItem(
                        value: "${c}_${s}_$t",
                        child: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('courses').where('course_code', isEqualTo: c).limit(1).get(),
                          builder: (context, cSnap) {
                            bool hasLab = false;
                            if (cSnap.hasData && cSnap.data!.docs.isNotEmpty) {
                              hasLab = cSnap.data!.docs.first.get('has_lab') ?? false;
                            }
                            String displayType = hasLab ? " ($t)" : "";
                            return Text("$c - Sec $s$displayType");
                          },
                        ),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      var parts = val.split('_');
                      setState(() {
                        _selectedCourse = parts[0];
                        _selectedSection = parts[1];
                        _selectedType = parts[2];
                        _attendance.clear();
                        _isLoadingStudents = true;
                        _editingDocId = null;
                      });

                      var scmMappings = await FirebaseFirestore.instance
                          .collection('student_course_mappings')
                          .where('course_code', isEqualTo: _selectedCourse)
                          .get();
                      
                      Map<String, bool> newAttendance = {};
                      for (var mappingDoc in scmMappings.docs) {
                        var mData = mappingDoc.data();
                        var students = await FirebaseFirestore.instance
                            .collection('students')
                            .where('department_id', isEqualTo: mData['student_dept'])
                            .where('semester_id', isEqualTo: mData['student_sem'])
                            .where('section', isEqualTo: _selectedSection)
                            .get();
                        for (var sDoc in students.docs) {
                          newAttendance[sDoc.get('usn')] = true;
                        }
                      }
                      
                      var sortedKeys = newAttendance.keys.toList()..sort();
                      Map<String, bool> sortedAttendance = {};
                      for (var key in sortedKeys) {
                        sortedAttendance[key] = newAttendance[key]!;
                      }

                      setState(() {
                        _attendance = sortedAttendance;
                        _isLoadingStudents = false;
                      });
                    },
                  ),
                );
              },
            ),

            if (_selectedCourse != null) ...[
              // Toggle between Mark and History
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showHistory = false),
                        icon: const Icon(Icons.edit_calendar),
                        label: Text(_editingDocId == null ? "Mark New" : "Edit Selected"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_showHistory ? const Color(0xFF1A5F7A) : Colors.grey.shade200,
                          foregroundColor: !_showHistory ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showHistory = true),
                        icon: const Icon(Icons.history),
                        label: const Text("History"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showHistory ? const Color(0xFF1A5F7A) : Colors.grey.shade200,
                          foregroundColor: _showHistory ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: _showHistory 
                  ? _buildHistoryView()
                  : _buildMarkingView(),
              ),
            ] else 
              const Expanded(child: Center(child: Text("Please select a course to proceed"))),
          ],
        );
      },
    );
  }

  Widget _buildMarkingView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_month, size: 18),
                label: Text(DateFormat('dd-MM-yyyy').format(_selectedDate)),
              ),
              Row(
                children: [
                  TextButton(onPressed: () => _selectTime(context, true), child: Text(_startTime.format(context))),
                  const Text("-"),
                  TextButton(onPressed: () => _selectTime(context, false), child: Text(_endTime.format(context))),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Students: ${_attendance.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(onPressed: () => _markAll(true), child: const Text("All Present")),
                  TextButton(onPressed: () => _markAll(false), child: const Text("All Absent")),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingStudents 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _attendance.length,
                itemBuilder: (context, index) {
                  String usn = _attendance.keys.elementAt(index);
                  return CheckboxListTile(
                    title: Text(usn, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('students').where('usn', isEqualTo: usn).limit(1).get(),
                      builder: (context, snap) {
                        if (snap.hasData && snap.data!.docs.isNotEmpty) {
                          return Text(snap.data!.docs.first.get('name'));
                        }
                        return const Text("Loading...");
                      },
                    ),
                    value: _attendance[usn],
                    activeColor: const Color(0xFF1A5F7A),
                    onChanged: (val) => setState(() => _attendance[usn] = val!),
                  );
                },
              ),
        ),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitAttendance,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
              child: Text(_editingDocId == null ? "SUBMIT ATTENDANCE" : "UPDATE ATTENDANCE", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('cc', isEqualTo: _selectedCourse)
          .where('s', isEqualTo: _selectedSection)
          .where('t', isEqualTo: _selectedType)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}", 
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No history found for this course/section."));

        docs.sort((a, b) {
          var dateA = a.get('d') as String;
          var dateB = b.get('d') as String;
          return dateB.compareTo(dateA);
        });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            List present = data['present_usns'] ?? [];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                title: Text(data['d'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Present: ${present.length} Students"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF1A5F7A)),
                      onPressed: () => _loadForEditing(docs[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(docs[index].id),
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

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Attendance?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('attendance').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted.")));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class TeacherMarks extends StatefulWidget {
  const TeacherMarks({super.key});

  @override
  State<TeacherMarks> createState() => _TeacherMarksState();
}

class _TeacherMarksState extends State<TeacherMarks> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedCourse;
  String? _selectedSection;
  bool _hasLab = false;
  
  // Marks selection
  String _selectedComponent = 'I1'; // I1, I2, I3, Quiz, AAT, Lab
  Map<String, double> _marksMap = {}; // USN -> Mark
  bool _isLoadingStudents = false;

  final List<String> _nonLabComponents = ['I1', 'I2', 'I3', 'Quiz', 'AAT', 'CIE', 'SEE'];
  final List<String> _labComponents = ['I1', 'I2', 'I3', 'Lab', 'AAT', 'CIE', 'SEE'];

  String _getGradeFromTotal(double total) {
    if (total >= 90) return 'O';
    if (total >= 80) return 'A+';
    if (total >= 70) return 'A';
    if (total >= 60) return 'B+';
    if (total >= 50) return 'B';
    return 'F';
  }

  Future<void> _saveMarks() async {
    if (_selectedCourse == null || _selectedSection == null) return;

    double maxMark = _calculateMaxMark();
    List<String> invalidUsns = [];
    _marksMap.forEach((usn, mark) {
      if (mark > maxMark || mark < 0) {
        invalidUsns.add(usn);
      }
    });

    if (invalidUsns.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marks for ${invalidUsns.length} students exceed the maximum of $maxMark!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    try {
      Map<String, double> cieMap = {};
      if (_selectedComponent == 'SEE') {
        var scmMappings = await FirebaseFirestore.instance
            .collection('student_course_mappings')
            .where('course_code', isEqualTo: _selectedCourse)
            .get();
        
        for (var mappingDoc in scmMappings.docs) {
          var mData = mappingDoc.data();
          var students = await FirebaseFirestore.instance
              .collection('students')
              .where('department_id', isEqualTo: mData['student_dept'])
              .where('semester_id', isEqualTo: mData['student_sem'])
              .where('section', isEqualTo: _selectedSection)
              .get();
          
          for (var sDoc in students.docs) {
            String usn = sDoc.get('usn');
            var mDoc = await FirebaseFirestore.instance
                .collection('marks')
                .doc("${_selectedCourse}_${_selectedSection}_$usn")
                .get();
            if (mDoc.exists) {
              cieMap[usn] = (mDoc.get('cie_total') ?? 0.0).toDouble();
            }
          }
        }
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (var entry in _marksMap.entries) {
        String usn = entry.key;
        double mark = entry.value;
        
        DocumentReference docRef = FirebaseFirestore.instance
            .collection('marks')
            .doc("${_selectedCourse}_${_selectedSection}_$usn");
            
        Map<String, dynamic> dataToSave = {
          'course_id': _selectedCourse,
          'section': _selectedSection,
          'student_id': usn,
          'last_updated': FieldValue.serverTimestamp(),
        };

        String fieldName = _selectedComponent.toLowerCase();
        if (_selectedComponent.startsWith('I')) {
          fieldName = "internal${_selectedComponent.substring(1)}_raw";
        } else if (_selectedComponent == 'Lab') {
          fieldName = "lab_exam_raw";
        } else if (_selectedComponent == 'Quiz') {
          fieldName = "quiz_marks";
        } else if (_selectedComponent == 'AAT') {
          fieldName = "aat_marks";
        } else if (_selectedComponent == 'CIE') {
          fieldName = "cie_total";
        } else if (_selectedComponent == 'SEE') {
          fieldName = "see_marks";
          
          // Calculate final grade
          double cie = cieMap[usn] ?? 0.0;
          double total = cie + (mark / 2.0); // SEE is out of 100, reduced to 50
          dataToSave['total_marks'] = double.parse(total.toStringAsFixed(2));
          dataToSave['grade'] = _getGradeFromTotal(total);
        }
            
        dataToSave[fieldName] = mark;
            
        batch.set(docRef, dataToSave, SetOptions(merge: true));
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving marks: $e')));
      }
    }
  }

  Future<void> _calculateAndPopulateCIE() async {
    setState(() => _isLoadingStudents = true);
    
    Map<String, double> calculatedCIE = {};
    
    for (var usn in _marksMap.keys) {
      var markDoc = await FirebaseFirestore.instance
          .collection('marks')
          .doc("${_selectedCourse}_${_selectedSection}_$usn")
          .get();
      
      if (markDoc.exists) {
        var data = markDoc.data() as Map<String, dynamic>;
        double i1Raw = (data['internal1_raw'] ?? 0.0).toDouble();
        double i2Raw = (data['internal2_raw'] ?? 0.0).toDouble();
        double i3Raw = (data['internal3_raw'] ?? 0.0).toDouble();
        double aat = (data['aat_marks'] ?? 0.0).toDouble();
        
        // Reduction logic
        double i1Red, i2Red, i3Red;
        if (_hasLab) {
          i1Red = i1Raw / 4.0; // 40 -> 10
          i2Red = i2Raw / 4.0;
          i3Red = i3Raw / 4.0;
        } else {
          i1Red = i1Raw / 2.0; // 40 -> 20
          i2Red = i2Raw / 2.0;
          i3Red = i3Raw / 2.0;
        }

        List<double> reducedInternals = [i1Red, i2Red, i3Red]..sort((a, b) => b.compareTo(a));
        double best1 = reducedInternals[0];
        double best2 = reducedInternals[1];
        double bestTwoTotal = best1 + best2;

        double finalCie = 0;
        double labRed = 0;
        double quiz = 0;

        if (_hasLab) {
          double labRaw = (data['lab_exam_raw'] ?? 0.0).toDouble();
          labRed = labRaw / 2.0; // 50 -> 25
          finalCie = bestTwoTotal + labRed + aat;
        } else {
          quiz = (data['quiz_marks'] ?? 0.0).toDouble();
          finalCie = bestTwoTotal + quiz + aat;
        }

        double roundedCie = double.parse(finalCie.toStringAsFixed(2));
        calculatedCIE[usn] = roundedCie;

        await FirebaseFirestore.instance
            .collection('marks')
            .doc("${_selectedCourse}_${_selectedSection}_$usn")
            .set({
          'course_id': _selectedCourse,
          'section': _selectedSection,
          'student_id': usn,
          'internal1_reduced': i1Red,
          'internal2_reduced': i2Red,
          'internal3_reduced': i3Red,
          'best_internal_1': best1,
          'best_internal_2': best2,
          'best_two_total': bestTwoTotal,
          'lab_exam_reduced': _hasLab ? labRed : 0.0,
          'cie_total': roundedCie,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        calculatedCIE[usn] = 0.0;
      }
    }

    setState(() {
      _marksMap = calculatedCIE;
      _isLoadingStudents = false;
    });
  }

  double _calculateMaxMark() {
    if (_selectedComponent == 'Quiz' || _selectedComponent == 'AAT') return 5.0;
    if (_selectedComponent == 'Lab') return 50.0;
    if (_selectedComponent == 'CIE') return 50.0;
    if (_selectedComponent == 'SEE') return 100.0;
    if (_selectedComponent.startsWith('I')) return 40.0;
    return 100.0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, teacherSnapshot) {
        if (!teacherSnapshot.hasData || teacherSnapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        String teacherId = teacherSnapshot.data!.docs.first.id;

        return Column(
          children: [
            // Course Selection
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teacher_mappings')
                  .where('teacher_id', isEqualTo: teacherId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var mappings = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCourse != null ? "${_selectedCourse}_${_selectedSection}" : null,
                    decoration: const InputDecoration(labelText: "Select Course & Section", border: OutlineInputBorder()),
                    items: mappings.map((m) {
                      var data = m.data() as Map<String, dynamic>;
                      String c = data['course_code'] ?? '';
                      String s = data['section'] ?? '';
                      return DropdownMenuItem(
                        value: "${c}_$s",
                        child: Text("$c - Sec $s"),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      var parts = val.split('_');
                      String courseCode = parts[0];
                      String section = parts[1];

                      // Check if course has lab
                      var courseDoc = await FirebaseFirestore.instance
                          .collection('courses')
                          .where('course_code', isEqualTo: courseCode)
                          .limit(1)
                          .get();
                      
                      bool hasLab = false;
                      if (courseDoc.docs.isNotEmpty) {
                        hasLab = courseDoc.docs.first.get('has_lab') ?? false;
                      }

                      setState(() {
                        _selectedCourse = courseCode;
                        _selectedSection = section;
                        _hasLab = hasLab;
                        _marksMap.clear();
                        _isLoadingStudents = true;
                        // Reset component if it's not valid for the new course type
                        if (_hasLab && !_labComponents.contains(_selectedComponent)) {
                          _selectedComponent = 'I1';
                        } else if (!_hasLab && !_nonLabComponents.contains(_selectedComponent)) {
                          _selectedComponent = 'I1';
                        }
                      });

                      // Fetch Students and existing marks
                      await _loadStudentsAndMarks();
                    },
                  ),
                );
              },
            ),

            if (_selectedCourse != null) ...[
              // Component Selection (I1, I2, I3, etc.)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: (_hasLab ? _labComponents : _nonLabComponents).map((comp) {
                    bool isSelected = _selectedComponent == comp;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(comp),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedComponent = comp;
                            });
                            _loadStudentsAndMarks();
                          }
                        },
                        selectedColor: const Color(0xFF1A5F7A),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Component: $_selectedComponent (Max: ${_calculateMaxMark()})", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5F7A))),
                    if (_selectedComponent == 'CIE')
                      ElevatedButton.icon(
                        onPressed: _calculateAndPopulateCIE,
                        icon: const Icon(Icons.calculate, size: 18),
                        label: const Text("Calculate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoadingStudents
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _marksMap.length,
                        itemBuilder: (context, index) {
                          String usn = _marksMap.keys.elementAt(index);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: ListTile(
                              title: Text(usn, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance.collection('students').where('usn', isEqualTo: usn).limit(1).get(),
                                builder: (context, snap) {
                                  if (snap.hasData && snap.data!.docs.isNotEmpty) {
                                    return Text(snap.data!.docs.first.get('name'));
                                  }
                                  return const Text("Loading...");
                                },
                              ),
                              trailing: SizedBox(
                                width: 85,
                                child: TextFormField(
                                  key: ValueKey("${usn}_${_selectedComponent}"),
                                  initialValue: _marksMap[usn]?.toString() ?? '',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  readOnly: _selectedComponent == 'CIE',
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    border: const OutlineInputBorder(),
                                    filled: _selectedComponent == 'CIE',
                                    fillColor: _selectedComponent == 'CIE' ? Colors.grey[200] : null,
                                    errorStyle: const TextStyle(fontSize: 10, height: 0.8),
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return null;
                                    double? mark = double.tryParse(val);
                                    double max = _calculateMaxMark();
                                    if (mark == null) return "Invalid";
                                    if (mark > max) return "Max $max";
                                    if (mark < 0) return "Min 0";
                                    return null;
                                  },
                                  onChanged: (val) {
                                    double? mark = double.tryParse(val);
                                    _marksMap[usn] = mark ?? 0.0;
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(15.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveMarks,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5F7A), foregroundColor: Colors.white),
                    child: Text(_selectedComponent == 'CIE' ? "SAVE CALCULATED CIE" : "SAVE MARKS", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ] else 
              const Expanded(child: Center(child: Text("Please select a course to proceed"))),
          ],
        );
      },
    );
  }

  Future<void> _loadStudentsAndMarks() async {
    setState(() => _isLoadingStudents = true);

    // 1. Get students for this course/section
    var scmMappings = await FirebaseFirestore.instance
        .collection('student_course_mappings')
        .where('course_code', isEqualTo: _selectedCourse)
        .get();
    
    Set<String> studentUsns = {};
    for (var mappingDoc in scmMappings.docs) {
      var mData = mappingDoc.data();
      var students = await FirebaseFirestore.instance
          .collection('students')
          .where('department_id', isEqualTo: mData['student_dept'])
          .where('semester_id', isEqualTo: mData['student_sem'])
          .where('section', isEqualTo: _selectedSection)
          .get();
      for (var sDoc in students.docs) {
        studentUsns.add(sDoc.get('usn'));
      }
    }

    // 2. Get existing marks for these students
    Map<String, double> newMarksMap = {};
    for (var usn in studentUsns) {
      var markDoc = await FirebaseFirestore.instance
          .collection('marks')
          .doc("${_selectedCourse}_${_selectedSection}_$usn")
          .get();
      
      if (markDoc.exists) {
        var data = markDoc.data() as Map<String, dynamic>;
        String fieldName = _selectedComponent.toLowerCase();
        if (_selectedComponent.startsWith('I')) {
          fieldName = "internal${_selectedComponent.substring(1)}_raw";
        } else if (_selectedComponent == 'Lab') {
          fieldName = "lab_exam_raw";
        } else if (_selectedComponent == 'Quiz') {
          fieldName = "quiz_marks";
        } else if (_selectedComponent == 'AAT') {
          fieldName = "aat_marks";
        } else if (_selectedComponent == 'CIE') {
          fieldName = "cie_total";
        } else if (_selectedComponent == 'SEE') {
          fieldName = "see_marks";
        }
        newMarksMap[usn] = (data[fieldName] ?? 0.0).toDouble();
      } else {
        newMarksMap[usn] = 0.0;
      }
    }

    // Sort by USN
    var sortedKeys = newMarksMap.keys.toList()..sort();
    Map<String, double> sortedMarks = {};
    for (var key in sortedKeys) {
      sortedMarks[key] = newMarksMap[key]!;
    }

    setState(() {
      _marksMap = sortedMarks;
      _isLoadingStudents = false;
    });
  }
}

class TeacherProfile extends StatefulWidget {
  const TeacherProfile({super.key});

  @override
  State<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(String currentEmail, String docId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child('teachers_profiles/$currentEmail');
      await storageRef.putFile(File(image.path));
      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('teachers').doc(docId).update({
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
          .collection('teachers')
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
                        tag: 'teacher_profile_pic',
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
              _infoSection("Email", userData['email'] ?? 'N/A'),
              _infoSection("Department", userData['department_id'] ?? 'N/A'),
              _infoSection("Phone", userData['phone'] ?? 'N/A'),
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

class TeacherNotificationIcon extends StatefulWidget {
  final String teacherId;
  const TeacherNotificationIcon({super.key, required this.teacherId});

  @override
  State<TeacherNotificationIcon> createState() => _TeacherNotificationIconState();
}

class _TeacherNotificationIconState extends State<TeacherNotificationIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wiggleAnimation;
  bool _hasWarning = false;
  List<Map<String, dynamic>> _lowAttendanceList = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _wiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startMonitoring();
  }

  void _startMonitoring() {
    _subscription = FirebaseFirestore.instance
        .collection('teacher_mappings')
        .where('teacher_id', isEqualTo: widget.teacherId)
        .snapshots()
        .listen((mappingsSnap) async {
      
      List<Map<String, dynamic>> alerts = [];
      
      for (var mapDoc in mappingsSnap.docs) {
        var mapData = mapDoc.data() as Map<String, dynamic>;
        String cc = mapData['course_code'];
        String sec = mapData['section'];
        String type = mapData['type'] ?? 'Theory';

        // Get total classes for this mapping
        var attSnap = await FirebaseFirestore.instance
            .collection('attendance')
            .where('cc', isEqualTo: cc)
            .where('s', isEqualTo: sec)
            .where('t', isEqualTo: type)
            .get();
        
        if (attSnap.docs.isEmpty) continue;
        int totalClasses = attSnap.docs.length;

        // Get all students in this section
        var scmMappings = await FirebaseFirestore.instance
            .collection('student_course_mappings')
            .where('course_code', isEqualTo: cc)
            .get();

        for (var scmDoc in scmMappings.docs) {
          var scm = scmDoc.data() as Map<String, dynamic>;
          var students = await FirebaseFirestore.instance
              .collection('students')
              .where('department_id', isEqualTo: scm['student_dept'])
              .where('semester_id', isEqualTo: scm['student_sem'])
              .where('section', isEqualTo: sec)
              .get();

          for (var sDoc in students.docs) {
            var sData = sDoc.data() as Map<String, dynamic>;
            String usn = sData['usn'];
            String name = sData['name'];
            
            int presentCount = attSnap.docs.where((doc) {
              var attData = doc.data() as Map<String, dynamic>;
              return (attData['present_usns'] as List).contains(usn);
            }).length;
            double percentage = (presentCount / totalClasses) * 100;

            if (percentage < 75) {
              alerts.add({
                'name': name,
                'usn': usn,
                'course': cc,
                'section': sec,
                'type': type,
                'percentage': percentage.toStringAsFixed(1),
              });
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _lowAttendanceList = alerts;
          _hasWarning = alerts.isNotEmpty;
        });
        if (_hasWarning) _controller.repeat(reverse: true);
        else { _controller.stop(); _controller.reset(); }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _hasWarning ? _wiggleAnimation.value : 0,
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                  _hasWarning ? Icons.notifications_active : Icons.notifications_none,
                  color: _hasWarning ? Colors.orangeAccent : Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherNotificationsScreen(alerts: _lowAttendanceList)));
                },
              ),
              if (_hasWarning)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(_lowAttendanceList.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TeacherNotificationsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  const TeacherNotificationsScreen({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Low Attendance Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      body: alerts.isEmpty
          ? const Center(child: Text("No critical attendance warnings."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                var data = alerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.warning_amber_rounded, color: Colors.white)),
                    title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['usn']} | ${data['course']} (${data['type']})\nSection: ${data['section']}"),
                    trailing: Text("${data['percentage']}%", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
