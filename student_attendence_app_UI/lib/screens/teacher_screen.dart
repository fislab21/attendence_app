import 'package:flutter/material.dart';
import '../widgets/user_header.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String? _currentCode;
  String? _activeSessionId;
  final List<Map<String, dynamic>> _sessions = [];
  final List<Map<String, dynamic>> _students = [];

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    for (int i = 0; i < 6; i++) {
      code.write(chars[(random + i) % chars.length]);
    }
    return code.toString();
  }

  void _startSession(String sessionId) {
    final code = _generateCode();
    final expiresAt = DateTime.now().add(const Duration(hours: 2));
    final sessionIndex = _sessions.indexWhere((s) => s['id'] == sessionId);

    setState(() {
      _currentCode = code;
      _activeSessionId = sessionId;
      _sessions[sessionIndex]['status'] = 'active';
      _sessions[sessionIndex]['code'] = code;
      _sessions[sessionIndex]['expiresAt'] = expiresAt;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Share this code with your students. The session is now active.',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            child: const Text('Copy Code'),
          ),
        ],
      ),
    );
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
          'Are you sure you want to close this session? Students will no longer be able to mark attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final sessionIndex = _sessions.indexWhere(
                (s) => s['id'] == sessionId,
              );
              setState(() {
                _sessions[sessionIndex]['status'] = 'completed';
                if (_activeSessionId == sessionId) {
                  _currentCode = null;
                  _activeSessionId = null;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session closed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Close Session'),
          ),
        ],
      ),
    );
  }

  void _viewAttendanceList(String sessionId) {
    final session = _sessions.firstWhere((s) => s['id'] == sessionId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceListScreen(
          session: session,
          students: _students,
          onUpdate: () => setState(() {}),
        ),
      ),
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
                        onPressed: () => _startSession(session['id']),
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
