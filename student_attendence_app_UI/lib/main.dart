import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/student_screen.dart';
import 'screens/teacher_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  // Normal mode: Login required
  // No demo user - users must login
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Always start at login screen
    // User must login to access other screens
    return MaterialApp(
      title: 'Attendance System',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/student': (context) => const StudentScreen(),
        '/teacher': (context) => const TeacherScreen(),
        '/admin': (context) => const AdminScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
