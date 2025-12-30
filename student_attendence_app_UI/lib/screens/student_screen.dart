import 'package:flutter/material.dart';
import '../widgets/exclusion_alert.dart';
import '../widgets/user_header.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  late TabController _tabController;

  int _sessionsAttended = 0;
  int _totalAbsences = 0;
  List<Map<String, dynamic>> _attendanceHistory = [];
  final List<Map<String, dynamic>> _excludedCourses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAttendanceData();
    _loadStats();
  }

  Future<void> _loadAttendanceData() async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) return;

      // Get attendance records from backend
      final records = await ApiService.getStudentAttendance(userId);

      // Transform data for display
      final history = records.map<Map<String, dynamic>>((record) {
        return {
          'course': record['course_name'] ?? 'Unknown Course',
          'date': record['date'] ?? '',
          'time': record['time'] ?? '',
          'code': record['code'] ?? '',
          'status': record['status'] ?? 'Present',
        };
      }).toList();

      setState(() {
        _attendanceHistory = history;
      });
    } catch (e) {
      // Handle error silently or show message
      debugPrint('Error loading attendance data: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) return;

      // Get student status (warnings/expulsion)
      final status = await ApiService.checkStudentStatus(userId);

      // Get attendance summary
      final records = await ApiService.getStudentAttendance(userId);

      // Calculate stats
      int attended = 0;
      int absences = 0;

      for (var record in records) {
        if (record['status'] == 'Present') {
          attended++;
        } else if (record['status'] == 'Absent') {
          absences++;
        }
      }

      setState(() {
        _sessionsAttended = attended;
        _totalAbsences = absences;
      });

      // Check if student is excluded from any courses
      if (status['warning'] != null) {
        // Show warning but allow attendance
      }
      if (status['expelled'] == true) {
        // Student is expelled from some courses
      }
    } catch (e) {
      // Handle error silently or show message
      debugPrint('Error loading stats: $e');
    }
  }

  void _markAttendance() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMessage('Please enter an attendance code', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    if (!mounted) return;

    try {
      final userId = AuthService.currentUser?['id'];
      if (userId == null) {
        setState(() => _isSubmitting = false);
        _showMessage('User not logged in', isError: true);
        return;
      }

      await ApiService.markAttendance(code, userId);
      setState(() {
        _isSubmitting = false;
        _sessionsAttended++;
      });
      _codeController.clear();
      _showMessage('Attendance recorded successfully!', isError: false);

      // Reload data
      _loadAttendanceData();
      _loadStats();
    } catch (e) {
      setState(() => _isSubmitting = false);
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _showMessage(errorMsg, isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      labelText: 'Enter attendance code',
      hintText: 'e.g. CSC-2024',
      prefixIcon: const Icon(Icons.qr_code_2_outlined),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    if (_attendanceHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No attendance records yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendanceHistory.length,
      itemBuilder: (context, index) {
        final record = _attendanceHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            title: Text(
              record['course'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Date: ${record['date']}'),
                Text('Time: ${record['time']}'),
                Text('Code: ${record['code']}'),
              ],
            ),
            trailing: Chip(
              label: const Text('Present'),
              backgroundColor: Colors.green.shade50,
              labelStyle: const TextStyle(color: Colors.green),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Student Dashboard'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
            Tab(icon: Icon(Icons.history_outlined), text: 'History'),
          ],
        ),
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
          child: TabBarView(
            controller: _tabController,
            children: [
              // Dashboard Tab
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const UserHeader(),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Student!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track your attendance and stay ahead of exclusions.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildQuickStat(
                                icon: Icons.event_available_outlined,
                                label: 'Sessions Attended',
                                value: '$_sessionsAttended',
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              _buildQuickStat(
                                icon: Icons.timer_outlined,
                                label: 'Total Absences',
                                value: '$_totalAbsences',
                                color: Colors.deepPurple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mark Attendance',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.help_outline),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'How to mark attendance',
                                      ),
                                      content: const Text(
                                        'Enter the attendance code provided by your teacher during class. The code is case-insensitive and expires after the session ends.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Got it'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeController,
                            decoration: _fieldDecoration(),
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _markAttendance(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _isSubmitting ? 'Submitting...' : 'Submit',
                              ),
                              onPressed: _isSubmitting ? null : _markAttendance,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_excludedCourses.isNotEmpty)
                    ExclusionAlert(excludedCourses: _excludedCourses),
                  // TODO: Load course attendance data from backend
                  // Example:
                  // FutureBuilder<List<CourseAttendance>>(
                  //   future: ApiService.getCourseAttendance(),
                  //   builder: (context, snapshot) {
                  //     if (snapshot.hasData) {
                  //       return Column(
                  //         children: snapshot.data!.map((course) =>
                  //           AttendanceCard(
                  //             courseCode: course.code,
                  //             courseName: course.name,
                  //             presentCount: course.presentCount,
                  //             justifiedCount: course.justifiedCount,
                  //             unjustifiedCount: course.unjustifiedCount,
                  //           ),
                  //         ).toList(),
                  //       );
                  //     }
                  //     return const SizedBox.shrink();
                  //   },
                  // ),
                ],
              ),
              // History Tab
              _buildAttendanceHistory(),
            ],
          ),
        ),
      ),
    );
  }
}
