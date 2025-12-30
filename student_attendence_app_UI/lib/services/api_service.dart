import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ============ HELPER METHODS ============

  static Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return decoded;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? error['warning'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<dynamic> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      final decoded = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<dynamic> _put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      final decoded = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception(decoded['error'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ============ AUTHENTICATION ============

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
    String role,
  ) async {
    final response = await _post('/auth.php?action=login', {
      'username': username,
      'password': password,
      'role': role,
    });

    if (response['success'] == true) {
      return response['data'] ?? response;
    }
    throw Exception(response['error'] ?? 'Login failed');
  }

  // ============ TEACHER ENDPOINTS ============

  static Future<List<Map<String, dynamic>>> getTeacherSessions(
    dynamic teacherId,
  ) async {
    try {
      final response = await _get(
        '/teacher.php?action=get_sessions&teacher_id=$teacherId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map(
            (x) => {
              'id': x['session_id']?.toString() ?? '',
              'session_id': x['session_id'],
              'teacher_id': x['teacher_id'],
              'course_id': x['course_id'],
              'course_code': x['course_code'] ?? '',
              'course_name': x['course_name'] ?? '',
              'date': x['start_time'] ?? '',
              'room': x['room'] ?? '',
              'status': x['status'] ?? 'upcoming',
            },
          ),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load teacher sessions: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherCourses(
    dynamic teacherId,
  ) async {
    try {
      final response = await _get(
        '/teacher.php?action=get_courses&teacher_id=$teacherId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load teacher courses: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getSessionStudents(
    dynamic sessionId,
  ) async {
    try {
      final response = await _get(
        '/teacher.php?action=get_students&session_id=$sessionId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map(
            (x) => {
              'id': x['student_id']?.toString() ?? '',
              'student_id': x['student_id'],
              'name': '${x['first_name'] ?? ''} ${x['last_name'] ?? ''}',
              'first_name': x['first_name'],
              'last_name': x['last_name'],
              'email': x['email'] ?? '',
              'status': 'absent', // Default status
            },
          ),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load session students: $e');
    }
  }

  static Future<Map<String, dynamic>> startSession(
    dynamic sessionId,
    String code,
  ) async {
    try {
      final response = await _post('/teacher.php?action=start_session', {
        'session_id': sessionId,
        'code': code,
      });

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to start session');
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  static Future<Map<String, dynamic>> closeSession(dynamic sessionId) async {
    try {
      final response = await _post('/teacher.php?action=close_session', {
        'session_id': sessionId,
      });

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to close session');
    } catch (e) {
      throw Exception('Failed to close session: $e');
    }
  }

  // ============ STUDENT ENDPOINTS ============

  static Future<List<Map<String, dynamic>>> getStudentCourses(
    dynamic studentId,
  ) async {
    try {
      final response = await _get(
        '/student.php?action=get_courses&student_id=$studentId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load student courses: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentAttendance(
    dynamic studentId,
  ) async {
    try {
      final response = await _get(
        '/student.php?action=get_attendance&student_id=$studentId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load student attendance: $e');
    }
  }

  // Mark attendance by code (student version - code, studentId)
  static Future<Map<String, dynamic>> markAttendance(
    dynamic code,
    dynamic studentId, [
    String? status,
    int? justified,
  ]) async {
    try {
      // If called with 2 params: markAttendance(code, studentId)
      // If called with 4 params: markAttendance(sessionId, studentId, status, justified)

      if (status == null) {
        // Code-based attendance marking (student enters code)
        final response = await _post('/attendance.php?action=mark_by_code', {
          'code': code,
          'student_id': studentId,
        });

        if (response['success'] == true || response['message'] != null) {
          return response['data'] ?? response;
        }
        throw Exception(
          response['error'] ?? 'Invalid code or session not active',
        );
      } else {
        // Session-based attendance marking (teacher marking students)
        final response = await _post('/student.php?action=mark_attendance', {
          'session_id': code,
          'student_id': studentId,
          'status': status,
          'justified': justified ?? 0,
        });

        if (response['success'] == true || response['message'] != null) {
          return response['data'] ?? response;
        }
        throw Exception(response['error'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // ============ ATTENDANCE ENDPOINTS ============

  static Future<List<Map<String, dynamic>>> getSessionAttendance(
    dynamic sessionId,
  ) async {
    try {
      final response = await _get(
        '/attendance.php?action=get_session_attendance&session_id=$sessionId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load session attendance: $e');
    }
  }

  static Future<Map<String, dynamic>> checkStudentStatus(
    dynamic studentId, {
    dynamic courseId,
  }) async {
    try {
      final endpoint = courseId != null
          ? '/attendance.php?action=check_status&student_id=$studentId&course_id=$courseId'
          : '/attendance.php?action=check_status&student_id=$studentId';

      final response = await _get(endpoint);
      return response['data'] ?? response;
    } catch (e) {
      throw Exception('Failed to check student status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getExpelledStudents({
    dynamic courseId,
  }) async {
    try {
      final endpoint = courseId != null
          ? '/attendance.php?action=get_expelled&course_id=$courseId'
          : '/attendance.php?action=get_expelled';

      final response = await _get(endpoint);

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load expelled students: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceReport(
    dynamic courseId,
  ) async {
    try {
      final response = await _get(
        '/attendance.php?action=get_report&course_id=$courseId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load attendance report: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAttendanceStatus(
    dynamic sessionId,
    dynamic studentId,
    String status, {
    int justified = 0,
    dynamic courseId,
  }) async {
    try {
      final response = await _put('/attendance.php?action=update_attendance', {
        'session_id': sessionId,
        'student_id': studentId,
        'status': status,
        'justified': justified,
        if (courseId != null) 'course_id': courseId,
      });

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to update attendance');
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // ============ ADMIN ENDPOINTS ============

  static Future<List<Map<String, dynamic>>> getAllUsers({String? role}) async {
    try {
      final endpoint = role != null
          ? '/admin.php?action=get_users&role=$role'
          : '/admin.php?action=get_users';

      final response = await _get(endpoint);

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final response = await _get('/admin.php?action=get_courses');

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load courses: $e');
    }
  }

  static Future<Map<String, dynamic>> createUser(
    String username,
    String password,
    String firstName,
    String lastName,
    String email,
    String role,
  ) async {
    try {
      final response = await _post('/admin.php?action=create_user', {
        'username': username,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'role': role,
      });

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to create user');
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<Map<String, dynamic>> createCourse(
    String courseCode,
    String courseName,
  ) async {
    try {
      final response = await _post('/admin.php?action=create_course', {
        'course_code': courseCode,
        'course_name': courseName,
      });

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to create course');
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteUser(dynamic userId) async {
    try {
      final response = await _get(
        '/admin.php?action=delete_user&user_id=$userId',
      );

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to delete user');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteCourse(dynamic courseId) async {
    try {
      final response = await _get(
        '/admin.php?action=delete_course&course_id=$courseId',
      );

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to delete course');
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // ============ ASSIGNMENT ENDPOINTS (Teacher-Course Assignment) ============

  static Future<List<Map<String, dynamic>>> getAllAssignments() async {
    try {
      final response = await _get('/admin.php?action=get_assignments');

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      if (response is Map && response['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (response['data'] as List).map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load assignments: $e');
    }
  }

  static Future<Map<String, dynamic>> assignCoursesToTeacher(
    dynamic teacherId,
    List<dynamic> courseIds,
  ) async {
    try {
      final response = await _post('/admin.php?action=assign_courses', {
        'teacher_id': teacherId,
        'course_ids': courseIds,
      });

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to assign courses');
    } catch (e) {
      throw Exception('Failed to assign courses to teacher: $e');
    }
  }

  static Future<Map<String, dynamic>> removeTeacherAssignment(
    dynamic teacherId,
    dynamic courseId,
  ) async {
    try {
      final response = await _get(
        '/admin.php?action=remove_assignment&teacher_id=$teacherId&course_id=$courseId',
      );

      if (response['success'] == true || response['message'] != null) {
        return response['data'] ?? response;
      }
      throw Exception(response['error'] ?? 'Failed to remove assignment');
    } catch (e) {
      throw Exception('Failed to remove teacher assignment: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherAssignments(
    dynamic teacherId,
  ) async {
    try {
      final response = await _get(
        '/admin.php?action=get_teacher_assignments&teacher_id=$teacherId',
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((x) => x as Map<String, dynamic>),
        );
      }
      if (response is Map && response['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (response['data'] as List).map((x) => x as Map<String, dynamic>),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load teacher assignments: $e');
    }
  }
}
