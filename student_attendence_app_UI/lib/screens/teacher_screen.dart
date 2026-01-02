import 'package:flutter/material.dart';
import '../widgets/user_header.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String? _currentCode;
  String? _activeSessionId;
  final List<Map<String, dynamic>> _courses = [];
  final List<Map<String, dynamic>> _sessions = [];
  final List<Map<String, dynamic>> _students = [];

  // Local attendance tracking: { sessionId: { studentId: { 'status': 'present'|'absent', 'justified': true|false } } }
  final Map<String, Map<String, Map<String, dynamic>>> _attendanceMap = {};

  @override
  void initState() {
    super.initState();
    // Load courses first, then sessions (sessions will be loaded after courses complete)
    _loadAssignedCourses();
  }

  Future<void> _loadActiveSessions() async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) return;

      // Get active sessions from backend
      final sessions = await ApiService.getActiveSessions(userId: userId.toString());

      setState(() {
        _sessions.clear();
        _sessions.addAll(sessions);
        
        // Update courses with session codes from database
        for (var session in sessions) {
          final courseIndex = _courses.indexWhere(
            (c) => c['course_id'] == session['course_id'] || c['id'] == session['course_id'],
          );
          if (courseIndex != -1 && session['status'] == 'Active') {
            _courses[courseIndex]['code'] = session['attendance_code'];
            _courses[courseIndex]['session_id'] = session['session_id'];
            _courses[courseIndex]['status'] = 'active';
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading active sessions: $e');
    }
  }

  Future<void> _loadAssignedCourses() async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) return;

      // Get teacher's courses from backend
      final courses = await ApiService.getTeacherCourses(userId.toString());

      setState(() {
        _courses.clear();
        _courses.addAll(courses);
      });
      
      // Reload active sessions to sync with courses
      await _loadActiveSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStudentsForSession(String sessionId) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) return;

      // Get non-submitted students for this session from backend
      final students = await ApiService.getNonSubmitters(
        sessionId: sessionId,
        teacherId: userId.toString(),
      );

      setState(() {
        _students.clear();
        _students.addAll(students);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  String _formatSessionDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'TBA';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
    } catch (e) {
      return 'TBA';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _startSession(String sessionId, String courseId) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate session with API (saves to database)
      final result = await ApiService.generateAttendanceSession(
        teacherId: userId.toString(),
        courseId: courseId,
        durationMinutes: 60,
        room: 'TBD',
      );

      final code = result['code'] as String?;
      final newSessionId = result['session_id'] as String?;
      final expirationTime = result['expiration_time'] as String?;
      
      if (code == null || newSessionId == null) {
        throw Exception('Failed to generate session');
      }

      // Reload active sessions
      await _loadActiveSessions();
      
      DateTime expiresAt;
      if (expirationTime != null) {
        try {
          expiresAt = DateTime.parse(expirationTime);
        } catch (e) {
          expiresAt = DateTime.now().add(const Duration(minutes: 60));
        }
      } else {
        expiresAt = DateTime.now().add(const Duration(minutes: 60));
      }
      
      _loadStudentsForSession(newSessionId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.play_circle_outline, color: Colors.green),
              SizedBox(width: 12),
              Text('Session Started'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Attendance Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Valid until ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this code with your students. Students can now mark their attendance.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _currentCode = code;
                    _activeSessionId = sessionId;
                    
                    // Update course with session info
                    final courseIndex = _courses.indexWhere(
                      (c) => (c['course_id'] ?? c['id']) == courseId,
                    );
                    if (courseIndex != -1) {
                      _courses[courseIndex]['code'] = code;
                      _courses[courseIndex]['session_id'] = sessionId;
                      _courses[courseIndex]['status'] = 'active';
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session started and saved to database'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _closeSession(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Close Session'),
          ],
        ),
        content: const Text(
          'Are you sure you want to close this session? Attendance records will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _saveAttendanceAndCloseSession(sessionId);
              Navigator.pop(context);
            },
            child: const Text('Close Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendanceAndCloseSession(String sessionId) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Save all attendance records to backend
      final sessionAttendance = _attendanceMap[sessionId] ?? {};

      for (var studentId in sessionAttendance.keys) {
        final record = sessionAttendance[studentId];
        if (record != null) {
          // Call backend API to update attendance
          await ApiService.updateAttendanceRecord(
            teacherId: userId.toString(),
            sessionId: sessionId,
            studentId: studentId,
            newStatus: record['status'] ?? 'Unjustified',
          );
        }
      }

      // Close session in database
      await ApiService.closeSession(sessionId);

      // Reload active sessions
      await _loadActiveSessions();

      // Update local state
      setState(() {
        // Find and update course with this session
        for (var course in _courses) {
          if (course['session_id'] == sessionId) {
            course['code'] = null;
            course['session_id'] = null;
            course['status'] = 'completed';
            break;
          }
        }
        if (_activeSessionId == sessionId) {
          _currentCode = null;
          _activeSessionId = null;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session closed and saved to database'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error closing session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewAttendanceList(String sessionId) {
    showDialog(
      context: context,
      builder: (context) => _buildAttendanceDialog(sessionId),
    );
  }

  Widget _buildAttendanceDialog(String sessionId) {
    final sessionData = _attendanceMap[sessionId] ?? {};

    return AlertDialog(
      title: const Text('Session Attendance'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            final studentId = student['id'];
            final attendance =
                sessionData[studentId] ??
                {'status': 'absent', 'justified': false};

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Present'),
                                Radio<String>(
                                  value: 'present',
                                  groupValue: attendance['status'],
                                  onChanged: (value) {
                                    setState(() {
                                      sessionData[studentId] = {
                                        'status': 'present',
                                        'justified': false,
                                      };
                                    });
                                    Navigator.pop(context);
                                    _viewAttendanceList(sessionId);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Absent'),
                                Radio<String>(
                                  value: 'absent',
                                  groupValue: attendance['status'],
                                  onChanged: (value) {
                                    setState(() {
                                      sessionData[studentId] = {
                                        'status': 'absent',
                                        'justified':
                                            attendance['justified'] ?? false,
                                      };
                                    });
                                    Navigator.pop(context);
                                    _viewAttendanceList(sessionId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Show justified checkbox only if absent
                      if (attendance['status'] == 'absent') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: attendance['justified'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  sessionData[studentId] = {
                                    'status': 'absent',
                                    'justified': value ?? false,
                                  };
                                });
                                Navigator.pop(context);
                                _viewAttendanceList(sessionId);
                              },
                            ),
                            const Expanded(child: Text('Justified Absence')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withValues(alpha: 0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Future<void> _createSession(Map<String, dynamic> course) async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final courseId = course['course_id'] ?? course['id'];
      if (courseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate session with API (saves to database)
      final result = await ApiService.generateAttendanceSession(
        teacherId: userId.toString(),
        courseId: courseId,
        durationMinutes: 60, // Set to 60 minutes or make it configurable
        room: 'TBD',
      );

      final code = result['code'] as String?;
      final sessionId = result['session_id'] as String?;
      final expirationTime = result['expiration_time'] as String?;

      if (code == null || sessionId == null) {
        throw Exception('Failed to generate session');
      }

      // Reload active sessions to get the latest data
      await _loadActiveSessions();

      if (!mounted) return;

      // Parse expiration time
      DateTime? expiresAt;
      if (expirationTime != null) {
        try {
          expiresAt = DateTime.parse(expirationTime);
        } catch (e) {
          expiresAt = DateTime.now().add(const Duration(minutes: 60));
        }
      } else {
        expiresAt = DateTime.now().add(const Duration(minutes: 60));
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.play_circle_outline, color: Colors.green),
              SizedBox(width: 12),
              Text('Session Started'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Attendance Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expiresAt != null 
                          ? 'Valid until ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}'
                          : 'Valid for this session',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this code with your students to mark attendance.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      // Update the session with the code
      setState(() {
        final index = _courses.indexWhere((c) => c['id'] == course['id']);
        if (index != -1) {
          _courses[index]['code'] = code;
          _courses[index]['status'] = 'active';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildAssignedCoursesList() {
    if (_courses.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No upcoming sessions scheduled'),
        ),
      ];
    }

    return _courses.map((course) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['course'] ?? 'Unknown Course',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          course['course_code'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Display session date and time
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatSessionDateTime(course['date']),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course['time'] ?? 'TBA',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      course['status']?.toUpperCase() ?? 'SCHEDULED',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Show session code if exists
              if (course['code'] != null && course['code']!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Attendance Code',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['code'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createSession(course),
                  icon: const Icon(Icons.play_circle_outline),
                  label: course['code'] != null && course['code']!.isNotEmpty
                      ? const Text('Start Session')
                      : const Text('Create Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSessionList() {
    if (_sessions.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No sessions scheduled for today'),
        ),
      ];
    }

    return _sessions.map((session) {
      final isActive = session['status'] == 'active';
      final isCompleted = session['status'] == 'completed';

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isActive ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isActive ? Colors.green : Colors.grey.shade200,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isActive
                        ? Colors.green.shade100
                        : isCompleted
                        ? Colors.grey.shade200
                        : Colors.blue.shade100,
                    child: Icon(
                      Icons.book_outlined,
                      color: isActive
                          ? Colors.green
                          : isCompleted
                          ? Colors.grey
                          : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session['course']} • ${session['room']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          session['time']!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      session['status']!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.green
                            : isCompleted
                            ? Colors.grey
                            : Colors.blue,
                      ),
                    ),
                    backgroundColor: isActive
                        ? Colors.green.shade50
                        : isCompleted
                        ? Colors.grey.shade100
                        : Colors.blue.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isCompleted && !isActive)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startSession(
                          session['id'],
                          session['course_id'] ?? '',
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (isActive) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewAttendanceList(session['id']),
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text('View List'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _closeSession(session['id']),
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  if (isCompleted)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewAttendanceList(session['id']),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View Attendance'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentCount = _students
        .where((s) => s['status'] == 'present')
        .length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.clear();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              children: [
                const UserHeader(),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Here is an overview of your teaching day.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildStatTile(
                              icon: Icons.people_alt_outlined,
                              label: 'Present',
                              value: '$presentCount/${_students.length}',
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _buildStatTile(
                              icon: Icons.assignment_turned_in_outlined,
                              label: 'Sessions',
                              value: '${_sessions.length}',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        if (_currentCode != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Active Attendance Code',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _currentCode!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Sessions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildAssignedCoursesList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Sessions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildSessionList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AttendanceListScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  final List<Map<String, dynamic>> students;
  final VoidCallback onUpdate;

  const AttendanceListScreen({
    super.key,
    required this.session,
    required this.students,
    required this.onUpdate,
  });

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  @override
  Widget build(BuildContext context) {
    final absentStudents = widget.students
        .where((s) => s['status'] == 'absent')
        .toList();
    final presentStudents = widget.students
        .where((s) => s['status'] == 'present')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.session['course']} Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Present',
                    presentStudents.length.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Absent',
                    absentStudents.length.toString(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (presentStudents.isNotEmpty) ...[
                  Text(
                    'Present Students',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...presentStudents.map(
                    (student) => _buildStudentCard(student, true),
                  ),
                  const SizedBox(height: 16),
                ],
                if (absentStudents.isNotEmpty) ...[
                  Text(
                    'Absent Students',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...absentStudents.map(
                    (student) => _buildStudentCard(student, false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, bool isPresent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: isPresent ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          student['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isPresent
              ? 'Present'
              : student['absenceType'] == 'justified'
              ? 'Absent - Justified'
              : student['absenceType'] == 'unjustified'
              ? 'Absent - Unjustified'
              : 'Absent - Not marked',
          style: TextStyle(
            color: isPresent
                ? Colors.green
                : student['absenceType'] == 'justified'
                ? Colors.orange
                : student['absenceType'] == 'unjustified'
                ? Colors.red
                : Colors.grey,
          ),
        ),
        trailing: !isPresent
            ? DropdownButton<String>(
                value: student['absenceType'],
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Not marked')),
                  DropdownMenuItem(
                    value: 'justified',
                    child: Text('Justified'),
                  ),
                  DropdownMenuItem(
                    value: 'unjustified',
                    child: Text('Unjustified'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    student['absenceType'] = value;
                  });
                  widget.onUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Updated absence type for ${student['name']}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
