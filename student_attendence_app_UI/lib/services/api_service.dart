import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ===========================
  // HELPER METHODS
  // ===========================

  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final queryUri = queryParams != null && queryParams.isNotEmpty
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      late final http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(queryUri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            queryUri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            queryUri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(queryUri, headers: headers);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      // Handle empty responses
      if (response.body.isEmpty) {
        throw ApiException(
          'Empty response from server',
          statusCode: response.statusCode,
        );
      }

      Map<String, dynamic> responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (parseError) {
        throw ApiException(
          'Invalid JSON response: ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          responseBody['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // ===========================
  // UC1: LOGIN
  // ===========================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
    String role,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/auth.php/login',
      body: {'username': username, 'password': password, 'role': role},
    );

    return response['data'] ?? {};
  }

  static Future<void> forgotPassword(String email) async {
    await _makeRequest(
      'POST',
      '/auth.php/forgot-password',
      body: {'email': email},
    );
  }

  // ===========================
  // UC2: ENTER CODE
  // ===========================

  static Future<Map<String, dynamic>> submitAttendanceCode(
    String studentId,
    String code,
  ) async {
    final response = await _makeRequest(
      'POST',
      '/student.php/enter-code',
      body: {'student_id': studentId, 'code': code},
    );

    return response['data'] ?? {};
  }

  // ===========================
  // UC3: VIEW HISTORY
  // ===========================

  static Future<Map<String, dynamic>> getStudentAttendanceHistory({
    required String studentId,
    String? courseId,
  }) async {
    final queryParams = {
      'student_id': studentId,
      if (courseId != null) 'course_id': courseId,
    };

    final response = await _makeRequest(
      'GET',
      '/student.php/history',
      queryParams: queryParams,
    );

    return response['data'] ?? {};
  }

  // ===========================
  // UC4: GENERATE SESSION
  // ===========================

  static Future<Map<String, dynamic>> generateAttendanceSession({
    required String teacherId, // Can be either teacher_id or user_id
    required String courseId,
    int durationMinutes = 15,
    String room = 'TBD',
  }) async {
    final response = await _makeRequest(
      'POST',
      '/teacher.php/generate-session',
      body: {
        'user_id': teacherId, // Backend accepts user_id
        'course_id': courseId,
        'duration_minutes': durationMinutes,
        'room': room,
      },
    );

    return response['data'] ?? {};
  }

  static Future<List<Map<String, dynamic>>> getActiveSessions({
    String? teacherId,
    String? userId,
  }) async {
    final queryParams = <String, String>{};
    if (teacherId != null) {
      queryParams['teacher_id'] = teacherId;
    }
    if (userId != null) {
      queryParams['user_id'] = userId;
    }

    final response = await _makeRequest(
      'GET',
      '/teacher.php/active-sessions',
      queryParams: queryParams,
    );

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  static Future<void> closeSession(String sessionId) async {
    await _makeRequest(
      'POST',
      '/teacher.php/close-session',
      body: {'session_id': sessionId},
    );
  }

  // ===========================
  // UC5: MARK ABSENCE
  // ===========================

  static Future<Map<String, dynamic>> markStudentAbsent({
    required String teacherId,
    required String sessionId,
    required String studentId,
    required String absenceType, // 'Justified' or 'Unjustified'
  }) async {
    final response = await _makeRequest(
      'POST',
      '/teacher.php/mark-absence',
      body: {
        'teacher_id': teacherId,
        'session_id': sessionId,
        'student_id': studentId,
        'absence_type': absenceType,
      },
    );

    return response['data'] ?? {};
  }

  // ===========================
  // UC6: UPDATE ATTENDANCE
  // ===========================

  static Future<Map<String, dynamic>> updateAttendanceRecord({
    required String teacherId,
    required String sessionId,
    required String studentId,
    required String newStatus, // 'Present', 'Justified', 'Unjustified'
  }) async {
    final response = await _makeRequest(
      'PUT',
      '/teacher.php/update-attendance',
      body: {
        'teacher_id': teacherId,
        'session_id': sessionId,
        'student_id': studentId,
        'new_status': newStatus,
      },
    );

    return response['data'] ?? {};
  }

  // ===========================
  // UC7: VIEW RECORDS (Teacher)
  // ===========================

  static Future<Map<String, dynamic>> getTeacherRecords({
    required String teacherId, // Can be either teacher_id or user_id
    String? courseId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = {
      'user_id': teacherId, // Backend accepts user_id
      if (courseId != null) 'course_id': courseId,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    };

    final response = await _makeRequest(
      'GET',
      '/teacher.php/records',
      queryParams: queryParams,
    );

    return response['data'] ?? {};
  }

  static Future<List<Map<String, dynamic>>> getTeacherCourses(
    String teacherId, // Can be either teacher_id or user_id
  ) async {
    final response = await _makeRequest(
      'GET',
      '/teacher.php/courses',
      queryParams: {'user_id': teacherId}, // Backend accepts user_id
    );

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  static Future<List<Map<String, dynamic>>> getNonSubmitters({
    required String sessionId,
    required String teacherId, // Can be either teacher_id or user_id
  }) async {
    final response = await _makeRequest(
      'GET',
      '/teacher.php/non-submitters',
      queryParams: {'session_id': sessionId, 'user_id': teacherId}, // Backend accepts user_id
    );

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  // ===========================
  // UC7: VIEW RECORDS (Admin)
  // ===========================

  static Future<Map<String, dynamic>> getAllRecords({
    String? courseId,
    String? studentId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = {
      if (courseId != null) 'course_id': courseId,
      if (studentId != null) 'student_id': studentId,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    };

    final response = await _makeRequest(
      'GET',
      '/admin.php/all-records',
      queryParams: queryParams,
    );

    return response['data'] ?? {};
  }

  static Future<String> exportRecordsToCSV({String? courseId}) async {
    final uri = Uri.parse('$baseUrl/admin.php/export-records');
    final queryUri = courseId != null
        ? uri.replace(queryParameters: {'course_id': courseId})
        : uri;

    try {
      final response = await http.get(queryUri);
      if (response.statusCode == 200) {
        return response.body; // CSV content
      } else {
        throw ApiException(
          'Failed to export records',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Export error: ${e.toString()}');
    }
  }

  // ===========================
  // UC8: PROFILE
  // ===========================

  static Future<Map<String, dynamic>> getStudentProfile(
    String studentId,
  ) async {
    final response = await _makeRequest(
      'GET',
      '/student.php/profile',
      queryParams: {'student_id': studentId},
    );

    return response['data'] ?? {};
  }

  static Future<void> updateStudentProfile({
    required String studentId,
    String? email,
    String? password,
    String? oldPassword,
  }) async {
    final body = {'student_id': studentId};
    if (email != null) body['email'] = email;
    if (password != null && oldPassword != null) {
      body['password'] = password;
      body['old_password'] = oldPassword;
    }

    await _makeRequest('PUT', '/student.php/profile', body: body);
  }

  // ===========================
  // UC9: MANAGE ACCOUNTS
  // ===========================

  static Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    String? status,
  }) async {
    final queryParams = {
      if (role != null) 'role': role,
      if (status != null) 'status': status,
    };

    final response = await _makeRequest(
      'GET',
      '/admin.php/users',
      queryParams: queryParams,
    );

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String fullName,
    required String userType, // 'Student', 'Teacher', 'Admin'
    String? password, // Auto-generated if not provided
  }) async {
    // Generate a default password if not provided
    final pwd =
        password ?? 'DefaultPass@${DateTime.now().millisecondsSinceEpoch}';

    final response = await _makeRequest(
      'POST',
      '/admin.php/users',
      body: {
        'username': username,
        'email': email,
        'full_name': fullName,
        'user_type': userType,
        'password': pwd,
      },
    );

    return response['data'] ?? {};
  }

  static Future<void> deleteUser(String userId) async {
    await _makeRequest(
      'DELETE',
      '/admin.php/users',
      queryParams: {'user_id': userId},
    );
  }

  static Future<void> suspendUser(String userId) async {
    await _makeRequest('POST', '/admin.php/suspend', body: {'user_id': userId});
  }

  static Future<void> reinstateUser(String userId) async {
    await _makeRequest(
      'POST',
      '/admin.php/reinstate',
      body: {'user_id': userId},
    );
  }

  // ===========================
  // UC10: ASSIGN COURSES
  // ===========================

  static Future<Map<String, dynamic>> assignCoursesToTeacher({
    required String teacherId, // Can be either teacher_id or user_id
    required List<String> courseIds,
  }) async {
    final response = await _makeRequest(
      'POST',
      '/admin.php/assign-courses',
      body: {'user_id': teacherId, 'course_ids': courseIds}, // Backend accepts user_id
    );

    // Handle case where backend returns an empty array or object
    final data = response['data'];
    if (data is List) {
      return {};
    }
    return (data as Map<String, dynamic>?) ?? {};
  }

  static Future<void> removeTeacherCourseAssignment({
    required String teacherId,
    required String courseId,
  }) async {
    await _makeRequest(
      'POST',
      '/admin.php/remove-assignment',
      body: {'teacher_id': teacherId, 'course_id': courseId},
    );
  }

  // ===========================
  // ADMIN: GET ALL COURSES
  // ===========================

  static Future<List<Map<String, dynamic>>> getAllCourses() async {
    final response = await _makeRequest('GET', '/admin.php/courses');

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  // ===========================
  // ADMIN: GET ALL ASSIGNMENTS
  // ===========================

  static Future<List<Map<String, dynamic>>> getAllAssignments() async {
    final response = await _makeRequest('GET', '/admin.php/assignments');

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  // ===========================
  // ADMIN: GET ALL USERS (alternative name)
  // ===========================

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _makeRequest('GET', '/admin.php/users');

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }
}
