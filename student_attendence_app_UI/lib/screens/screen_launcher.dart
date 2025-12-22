import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'student_screen.dart';
import 'teacher_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class ScreenLauncher extends StatelessWidget {
  const ScreenLauncher({super.key});

  void _setMockUser(String role) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    String name = '';
    String email = '';
    
    switch (role) {
      case 'student':
        name = 'John Doe';
        email = 'john.doe@university.edu';
        break;
      case 'teacher':
        name = 'Dr. Jane Smith';
        email = 'jane.smith@university.edu';
        break;
      case 'admin':
        name = 'Admin User';
        email = 'admin@university.edu';
        break;
    }
    
    AuthService.setCurrentUser(
      id: id,
      username: role == 'student' ? 'student123' : role == 'teacher' ? 'teacher123' : 'admin123',
      name: name,
      email: email,
      role: role,
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen, String role) {
    _setMockUser(role);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.dashboard,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Screen Launcher',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a screen to view',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildScreenButton(
                          context,
                          icon: Icons.person,
                          label: 'Login Screen',
                          description: 'User authentication interface',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildScreenButton(
                          context,
                          icon: Icons.school,
                          label: 'Student Screen',
                          description: 'Student dashboard and attendance',
                          color: Colors.green,
                          onTap: () => _navigateToScreen(context, const StudentScreen(), 'student'),
                        ),
                        const SizedBox(height: 16),
                        _buildScreenButton(
                          context,
                          icon: Icons.person_outline,
                          label: 'Teacher Screen',
                          description: 'Teacher dashboard and session management',
                          color: Colors.orange,
                          onTap: () => _navigateToScreen(context, const TeacherScreen(), 'teacher'),
                        ),
                        const SizedBox(height: 16),
                        _buildScreenButton(
                          context,
                          icon: Icons.admin_panel_settings,
                          label: 'Admin Screen',
                          description: 'Admin dashboard and system management',
                          color: Colors.purple,
                          onTap: () => _navigateToScreen(context, const AdminScreen(), 'admin'),
                        ),
                        const SizedBox(height: 16),
                        _buildScreenButton(
                          context,
                          icon: Icons.account_circle,
                          label: 'Profile Screen',
                          description: 'User profile and personal information',
                          color: Colors.teal,
                          onTap: () {
                            _setMockUser('student');
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

