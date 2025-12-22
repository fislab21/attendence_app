import 'package:flutter/material.dart';
import '../widgets/user_header.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _studentAbsenceRecords = [];
  final List<Map<String, dynamic>> _courses = [];
  final List<Map<String, dynamic>> _courseAssignments = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCourses();
    _loadAssignments();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getAllUsers();
      setState(() {
        _users.clear();
        _users.addAll(users);
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await ApiService.getAllCourses();
      setState(() {
        _courses.clear();
        _courses.addAll(courses);
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final assignments = await ApiService.getAllAssignments();
      setState(() {
        _courseAssignments.clear();
        _courseAssignments.addAll(assignments);
      });
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    }
  }

  void _addAccount() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? errorMessage;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Add New Account'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v ?? 'student'),
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  if (errorMessage != null)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      usernameController.text.trim().isEmpty ||
                      emailController.text.trim().isEmpty ||
                      passwordController.text.trim().isEmpty) {
                    setDialogState(
                      () => errorMessage =
                          'Name, username, email, and password are required',
                    );
                    return;
                  }
                  final duplicate = _users.any(
                    (u) => u['username'] == usernameController.text.trim(),
                  );
                  if (duplicate) {
                    setDialogState(
                      () => errorMessage = 'Username already exists',
                    );
                    return;
                  }

                  try {
                    // Call backend API to create user
                    final response = await ApiService.createUser(
                      usernameController.text.trim(),
                      passwordController.text.trim(),
                      emailController.text.trim(),
                      nameController.text.trim(),
                      selectedRole,
                    );

                    if (response['success'] == true) {
                      Navigator.pop(context);
                      await _loadUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(
                      () => errorMessage = 'Error: ${e.toString()}',
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteAccount(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete ${user['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                final index = _users.indexWhere((u) => u['id'] == user['id']);
                if (index != -1) {
                  _users[index] = {..._users[index], 'status': 'deleted'};
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _manageAccounts();
                }
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reinstateAccount(Map<String, dynamic> user) {
    setState(() {
      final index = _users.indexWhere((u) => u['id'] == user['id']);
      if (index != -1) {
        _users[index] = {..._users[index], 'status': 'active'};
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account reinstated successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _manageAccounts();
      }
    });
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user['name'][0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'], style: const TextStyle(fontSize: 18)),
                  Text(
                    user['role'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(Icons.badge, 'User ID', user['id']),
              const Divider(height: 24),
              _buildInfoRow(Icons.person_outline, 'Username', user['username']),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.email_outlined,
                'Email',
                user['email'].isEmpty ? 'Not provided' : user['email'],
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.verified_user,
                'Status',
                user['status'] == 'active' ? 'Active' : 'Deleted',
                statusColor: user['status'] == 'active'
                    ? Colors.green
                    : Colors.red,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.school,
                'Role',
                user['role'].toString().toUpperCase(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _manageAccounts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.manage_accounts, color: Colors.blue),
            SizedBox(width: 12),
            Text('Manage Accounts'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _users.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No accounts yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isDeleted = user['status'] == 'deleted';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isDeleted ? Colors.grey.shade100 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDeleted
                              ? Colors.grey.shade300
                              : Colors.blue.shade100,
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDeleted
                                  ? Colors.grey.shade600
                                  : Colors.blue,
                            ),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? user['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDeleted ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user['username']} • ${user['role']}',
                              style: TextStyle(
                                color: isDeleted ? Colors.grey : null,
                              ),
                            ),
                            if (isDeleted)
                              Text(
                                'DELETED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _viewUserDetails(user);
                              },
                              tooltip: 'View Details',
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                if (user['status'] == 'active')
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  )
                                else
                                  const PopupMenuItem(
                                    value: 'reinstate',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.restore,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Reinstate'),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) {
                                Navigator.pop(context);
                                if (value == 'delete') {
                                  _deleteAccount(user);
                                } else if (value == 'reinstate') {
                                  _reinstateAccount(user);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
            onPressed: () {
              Navigator.pop(context);
              _addAccount();
            },
          ),
        ],
      ),
    );
  }

  void _assignCoursesToTeacher() {
    final teachers = _users
        .where((u) => u['role'] == 'teacher' && u['status'] == 'active')
        .toList();

    if (teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active teachers available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic>? selectedTeacher;
    final Set<String> selectedCourses = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentAssignments = selectedTeacher != null
              ? _courseAssignments
                    .where((a) => a['teacherId'] == selectedTeacher!['id'])
                    .map((a) => a['courseId'] as String)
                    .toSet()
              : <String>{};

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.assignment_ind, color: Colors.blue),
                SizedBox(width: 12),
                Text('Assign Courses to Teacher'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Teacher',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedTeacher,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Choose a teacher',
                      ),
                      items: teachers.map((teacher) {
                        return DropdownMenuItem(
                          value: teacher,
                          child: Text(teacher['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTeacher = value;
                          selectedCourses.clear();
                        });
                      },
                    ),
                    if (selectedTeacher != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Courses',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (currentAssignments.isNotEmpty)
                            Text(
                              '${currentAssignments.length} currently assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select courses to assign. Previously assigned courses will be replaced.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._courses.map((course) {
                        final isCurrentlyAssigned = currentAssignments.contains(
                          course['id'],
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isCurrentlyAssigned
                              ? Colors.green.shade50
                              : null,
                          child: CheckboxListTile(
                            title: Text(
                              course['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course['code'] ?? 'N/A'),
                                if (isCurrentlyAssigned)
                                  Text(
                                    'Currently assigned',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            value: selectedCourses.contains(course['id']),
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedCourses.add(course['id']);
                                } else {
                                  selectedCourses.remove(course['id']);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTeacher == null || selectedCourses.isEmpty
                    ? null
                    : () async {
                        try {
                          // Call backend API to assign courses
                          await ApiService.assignCoursesToTeacher(
                            selectedTeacher!['id'],
                            selectedCourses.toList(),
                          );

                          // Update local state only after successful API call
                          _courseAssignments.removeWhere(
                            (a) => a['teacherId'] == selectedTeacher!['id'],
                          );

                          for (final courseId in selectedCourses) {
                            _courseAssignments.add({
                              'id':
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString() +
                                  courseId,
                              'teacherId': selectedTeacher!['id'],
                              'courseId': courseId,
                              'assignedAt': DateTime.now(),
                            });
                          }

                          setState(() {});

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selectedCourses.length} course(s) assigned to ${selectedTeacher!['name']}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error assigning courses: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text('Assign Courses'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _viewCourseAssignments() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.list_alt, color: Colors.blue),
            SizedBox(width: 12),
            Text('Course Assignments'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _courseAssignments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No course assignments yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Assign courses to teachers to get started',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: () {
                      final Map<String, List<Map<String, dynamic>>>
                      groupedAssignments = {};

                      for (final assignment in _courseAssignments) {
                        final teacherId = assignment['teacherId'] as String;
                        groupedAssignments.putIfAbsent(teacherId, () => []);
                        groupedAssignments[teacherId]!.add(assignment);
                      }

                      return groupedAssignments.entries.map((entry) {
                        final teacher = _users.firstWhere(
                          (u) => u['id'] == entry.key,
                        );
                        final assignments = entry.value;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              teacher['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${assignments.length} course(s) assigned',
                            ),
                            children: assignments.map((assignment) {
                              final course = _courses.firstWhere(
                                (c) => c['id'] == assignment['courseId'],
                              );
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.book, size: 20),
                                title: Text(course['name']),
                                subtitle: Text(course['code'] ?? 'N/A'),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _courseAssignments.removeWhere(
                                        (a) => a['id'] == assignment['id'],
                                      );
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Course assignment removed',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Future.delayed(
                                      const Duration(milliseconds: 300),
                                      () {
                                        if (mounted) _viewCourseAssignments();
                                      },
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList();
                    }(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Assign Courses'),
            onPressed: () {
              Navigator.pop(context);
              _assignCoursesToTeacher();
            },
          ),
        ],
      ),
    );
  }

  void _showStudentAbsenceList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Student Absences'),
        content: SizedBox(
          width: double.maxFinite,
          child: _studentAbsenceRecords.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No absence records yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Records are maintained by academic affairs',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _studentAbsenceRecords.map((record) {
                      final totalAbsences =
                          (record['justified'] as int) +
                          (record['unjustified'] as int);
                      final excluded = record['excluded'] as bool;
                      final statusColor = excluded ? Colors.red : Colors.orange;
                      final statusText = excluded
                          ? 'Excluded'
                          : 'Warning issued';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: excluded
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            child: Icon(
                              excluded
                                  ? Icons.block
                                  : Icons.warning_amber_outlined,
                              color: statusColor,
                            ),
                          ),
                          title: Text(record['name'] as String),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record['course'] as String),
                              Text(
                                'Justified: ${record['justified']} • Unjustified: ${record['unjustified']}',
                              ),
                              Text('Total absences: $totalAbsences'),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(statusText),
                            avatar: Icon(
                              excluded ? Icons.shield : Icons.info_outline,
                              size: 14,
                            ),
                            backgroundColor: statusColor.withValues(
                              alpha: 0.15,
                            ),
                            labelStyle: TextStyle(color: statusColor),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Profile and Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const UserHeader(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person, color: Colors.white),
                            tooltip: 'Profile',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () {
                              AuthService.clear();
                              Navigator.pushReplacementNamed(context, '/');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Dashboard Title
                  Text(
                    'Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'System Statistics & Overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Statistics Cards Grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: [
                      _buildStatisticCard(
                        icon: Icons.people,
                        title: 'Students',
                        value: _users
                            .where(
                              (u) =>
                                  u['role'] == 'student' &&
                                  u['status'] == 'active',
                            )
                            .length
                            .toString(),
                        color: Colors.blue,
                      ),
                      _buildStatisticCard(
                        icon: Icons.school,
                        title: 'Teachers',
                        value: _users
                            .where(
                              (u) =>
                                  u['role'] == 'teacher' &&
                                  u['status'] == 'active',
                            )
                            .length
                            .toString(),
                        color: Colors.green,
                      ),
                      _buildStatisticCard(
                        icon: Icons.book,
                        title: 'Courses',
                        value: _courses.length.toString(),
                        color: Colors.orange,
                      ),
                      _buildStatisticCard(
                        icon: Icons.person_add,
                        title: 'Admins',
                        value: _users
                            .where(
                              (u) =>
                                  u['role'] == 'admin' &&
                                  u['status'] == 'active',
                            )
                            .length
                            .toString(),
                        color: Colors.purple,
                      ),
                      _buildStatisticCard(
                        icon: Icons.assignment_outlined,
                        title: 'Assignments',
                        value: _courseAssignments.length.toString(),
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Quick Actions Section
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text('Manage Accounts'),
                      onPressed: _manageAccounts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_ind),
                      label: const Text('Assign Courses to Teachers'),
                      onPressed: _assignCoursesToTeacher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View Course Assignments'),
                      onPressed: _viewCourseAssignments,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('View Student Absences'),
                      onPressed: _showStudentAbsenceList,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
