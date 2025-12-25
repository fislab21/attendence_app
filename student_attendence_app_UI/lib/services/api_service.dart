import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  // Base URL from config
  static const String baseUrl = ApiConfig.baseUrl;

  // Helper method for GET requests
  static Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for POST requests
  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PUT requests
  static Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic>? data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: data != null ? json.encode(data) : null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for DELETE requests
  static Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Request failed');
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
    return await _post('/auth/login', {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>> unlockAccount(String userId) async {
    return await _post('/auth/unlock-account/$userId', {});
  }

  // ============ STUDENT ENDPOINTS ============
  static Future<Map<String, dynamic>> markAttendance(
    String code,
    String studentId,
  ) async {
    return await _post('/student/mark-attendance', {
      'code': code,
      'student_id': studentId,
    });
  }

  static Future<List<Map<String, dynamic>>> getAttendanceRecords(
    String studentId,
  ) async {
    final response = await _get('/student/attendance-records/$studentId');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  static Future<Map<String, dynamic>> getStudentStats(
    String studentId,
    String? courseId,
  ) async {
    final endpoint = courseId != null
        ? '/student/stats/$studentId?course_id=$courseId'
        : '/student/stats/$studentId';
    final response = await _get(endpoint);
    return response as Map<String, dynamic>;
  }

  // ============ TEACHER ENDPOINTS ============
  static Future<Map<String, dynamic>> createSession(
    String courseId,
    String teacherId,
    String date, {
    String? room,
    String? timeSlot,
  }) async {
    return await _post('/teacher/sessions', {
      'course_id': courseId,
      'teacher_id': teacherId,
      'date': date,
      'room': room,
      'time_slot': timeSlot,
    });
  }

  static Future<Map<String, dynamic>> startSession(String sessionId) async {
    return await _post('/teacher/sessions/start', {'session_id': sessionId});
  }

  static Future<Map<String, dynamic>> closeSession(String sessionId) async {
    return await _post('/teacher/sessions/close', {'session_id': sessionId});
  }

  static Future<List<Map<String, dynamic>>> getTeacherSessions(
    String teacherId,
  ) async {
    final response = await _get('/teacher/sessions/$teacherId');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getTeacherCourses(
    String teacherId,
  ) async {
    final response = await _get('/teacher/courses/$teacherId');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  static Future<Map<String, dynamic>> getSessionAttendance(
    String sessionId,
  ) async {
    final response = await _get('/teacher/sessions/$sessionId/attendance');
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateAttendanceStatus(
    String sessionId,
    String studentId,
    String absenceType,
  ) async {
    return await _put(
      '/teacher/sessions/$sessionId/attendance/$studentId?absence_type=$absenceType',
      null,
    );
  }

  // ============ ADMIN ENDPOINTS ============
  // Users
  static Future<Map<String, dynamic>> createUser(
    String username,
    String password,
    String email,
    String fullName,
    String role,
  ) async {
    return await _post('/admin/users', {
      'username': username,
      'password': password,
      'email': email,
      'full_name': fullName,
      'role': role,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _get('/admin/users');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String status,
  ) async {
    return await _put('/admin/users/$userId/status', {'status': status});
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    return await _delete('/admin/users/$userId');
  }

  // Courses
  static Future<Map<String, dynamic>> createCourse(
    String courseName,
    String courseCode,
  ) async {
    return await _post('/admin/courses', {
      'course_name': courseName,
      'course_code': courseCode,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    final response = await _get('/admin/courses');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  static Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    return await _delete('/admin/courses/$courseId');
  }

  // Assignments
  static Future<Map<String, dynamic>> assignCoursesToTeacher(
    String teacherId,
    List<String> courseIds,
  ) async {
    return await _post('/admin/assignments', {
      'teacher_id': teacherId,
      'course_ids': courseIds,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllAssignments() async {
    final response = await _get('/admin/assignments');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  static Future<Map<String, dynamic>> deleteAssignment(
    String assignmentId,
  ) async {
    return await _delete('/admin/assignments/$assignmentId');
  }

  // Enrollments
  static Future<Map<String, dynamic>> enrollStudentInCourses(
    String studentId,
    List<String> courseIds,
  ) async {
    return await _post('/admin/enrollments', {
      'student_id': studentId,
      'course_ids': courseIds,
    });
  }

  static Future<List<Map<String, dynamic>>> getStudentEnrollments(
    String studentId,
  ) async {
    final response = await _get('/admin/enrollments/$studentId');
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  // Warnings
  static Future<Map<String, dynamic>> createWarning(
    String studentId,
    String courseId,
    int absenceCount, {
    String? warningMessage,
  }) async {
    return await _post('/admin/warnings', {
      'student_id': studentId,
      'course_id': courseId,
      'absence_count': absenceCount,
      'warning_message': warningMessage,
    });
  }

  static Future<List<Map<String, dynamic>>> getWarnings({
    String? studentId,
    String? courseId,
    bool activeOnly = false,
  }) async {
    String endpoint = '/admin/warnings?';
    if (studentId != null) endpoint += 'student_id=$studentId&';
    if (courseId != null) endpoint += 'course_id=$courseId&';
    if (activeOnly) endpoint += 'active_only=true&';
    endpoint = endpoint.replaceAll(RegExp(r'&$'), '');

    final response = await _get(endpoint);
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }

  // Exclusions
  static Future<Map<String, dynamic>> createExclusion(
    String studentId,
    String courseId,
    int absenceCount, {
    String? exclusionReason,
  }) async {
    return await _post('/admin/exclusions', {
      'student_id': studentId,
      'course_id': courseId,
      'absence_count': absenceCount,
      'exclusion_reason': exclusionReason,
    });
  }

  static Future<List<Map<String, dynamic>>> getExclusions({
    String? studentId,
    String? courseId,
    bool activeOnly = false,
  }) async {
    String endpoint = '/admin/exclusions?';
    if (studentId != null) endpoint += 'student_id=$studentId&';
    if (courseId != null) endpoint += 'course_id=$courseId&';
    if (activeOnly) endpoint += 'active_only=true&';
    endpoint = endpoint.replaceAll(RegExp(r'&$'), '');

    final response = await _get(endpoint);
    if (response is List) {
      return List<Map<String, dynamic>>.from(
        response.map((x) => x as Map<String, dynamic>),
      );
    }
    return [];
  }
}
