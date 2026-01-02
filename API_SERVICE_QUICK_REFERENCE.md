# API Service Quick Reference

## Overview
Complete reference for the `api_service.dart` with all 30+ methods organized by use case.

## Setup
```dart
import 'package:student_attendence_app/services/api_service.dart';
```

## Authentication (UC1)

### Login
```dart
try {
  final result = await ApiService.login(
    username: 'student1',
    password: 'password123',
    role: 'Student', // or 'Teacher', 'Admin'
  );
  
  String userId = result['user_id'];
  String role = result['role'];
  String email = result['email'];
} on ApiException catch (e) {
  // Possible errors:
  // - "Invalid username or password"
  // - "Account is suspended"
  // - "Account is locked (too many failed attempts)"
  // - "Account has been deleted"
  print('Login failed: ${e.message}');
}
```

### Forgot Password
```dart
try {
  await ApiService.forgotPassword('user@university.edu');
  // Success: Email sent with reset link
} on ApiException catch (e) {
  print('Password recovery failed: ${e.message}');
}
```

---

## Student Features

### UC2: Submit Attendance Code
```dart
try {
  final result = await ApiService.submitAttendanceCode(
    studentId: studentId,
    code: 'ABC123', // Must be 6 alphanumeric
  );
  
  String sessionId = result['session_id'];
  String status = result['status']; // 'Present'
  String markedAt = result['marked_at']; // ISO timestamp
  
  showSnackBar('Attendance marked successfully');
} on ApiException catch (e) {
  // Possible errors:
  // - "Invalid code format (must be 6 alphanumeric)"
  // - "Session has expired"
  // - "Code already used"
  // - "You are not enrolled in this course"
  // - "Session is not active"
  print('Code submission failed: ${e.message}');
}
```

### UC3: Get Attendance History
```dart
try {
  final result = await ApiService.getStudentAttendanceHistory(
    studentId: studentId,
    courseId: null, // Optional filter
  );
  
  // Statistics
  Map<String, dynamic> stats = result['stats'] ?? {};
  int totalSessions = stats['total_sessions'] ?? 0;
  int presentCount = stats['present_count'] ?? 0;
  int totalAbsences = stats['total_absences'] ?? 0;
  int justifiedAbsences = stats['justified_absences'] ?? 0;
  int unjustifiedAbsences = stats['unjustified_absences'] ?? 0;
  
  // Records
  List<Map<String, dynamic>> records = result['records'] ?? [];
  for (var record in records) {
    print('${record["course_name"]} - ${record["date"]} - ${record["status"]}');
  }
  
  // Active warnings (yellow alert)
  List<Map<String, dynamic>> warnings = result['active_warnings'] ?? [];
  for (var warning in warnings) {
    print('⚠️  Warning for ${warning["reason"]} (${warning["triggered_date"]})');
  }
  
  // Active exclusions (red alert)
  List<Map<String, dynamic>> exclusions = result['active_exclusions'] ?? [];
  for (var exclusion in exclusions) {
    print('❌ Excluded: ${exclusion["reason"]}');
  }
} on ApiException catch (e) {
  print('Failed to load history: ${e.message}');
}
```

### UC8a: Get Student Profile
```dart
try {
  final result = await ApiService.getStudentProfile(studentId);
  
  String username = result['username'];
  String email = result['email'];
  String fullName = result['full_name'];
  String role = result['role'];
} on ApiException catch (e) {
  print('Failed to load profile: ${e.message}');
}
```

### UC8b: Update Student Profile - Email
```dart
try {
  await ApiService.updateStudentProfile(
    studentId: studentId,
    email: 'newemail@university.edu',
  );
  showSnackBar('Email updated successfully');
} on ApiException catch (e) {
  // Possible errors:
  // - "Email already in use"
  // - "Invalid email format"
  // - "Email change not allowed"
  print('Email update failed: ${e.message}');
}
```

### UC8c: Update Student Profile - Password
```dart
try {
  await ApiService.updateStudentProfile(
    studentId: studentId,
    password: 'newPassword123',
    oldPassword: 'oldPassword123',
  );
  showSnackBar('Password changed successfully');
} on ApiException catch (e) {
  // Possible errors:
  // - "Old password is incorrect"
  // - "New password does not meet requirements"
  // - "Cannot change password twice in 24 hours"
  print('Password change failed: ${e.message}');
}
```

---

## Teacher Features

### UC4: Generate Attendance Session
```dart
try {
  final result = await ApiService.generateAttendanceSession(
    teacherId: teacherId,
    courseId: courseId,
    durationMinutes: 15, // Default: 15
    room: 'Room 101', // Default: 'TBD'
  );
  
  String code = result['code']; // 6-char unique code
  String sessionId = result['session_id'];
  String expiresAt = result['expires_at']; // ISO timestamp
  int durationSeconds = result['duration_seconds'];
  
  showSnackBar('Session generated: $code');
} on ApiException catch (e) {
  // Possible errors:
  // - "You don't teach this course"
  // - "Course not found"
  // - "Session already active for this course"
  print('Session generation failed: ${e.message}');
}
```

### Get Teacher Courses
```dart
try {
  final courses = await ApiService.getTeacherCourses(teacherId);
  
  for (var course in courses) {
    print('${course["course_id"]} - ${course["course_name"]}');
  }
} on ApiException catch (e) {
  print('Failed to load courses: ${e.message}');
}
```

### Get Non-Submitters (for marking absences)
```dart
try {
  final students = await ApiService.getNonSubmitters(
    sessionId: sessionId,
    teacherId: teacherId,
  );
  
  for (var student in students) {
    print('${student["student_id"]} - ${student["name"]}');
  }
} on ApiException catch (e) {
  print('Failed to load students: ${e.message}');
}
```

### UC5: Mark Student Absent
```dart
try {
  final result = await ApiService.markStudentAbsent(
    teacherId: teacherId,
    sessionId: sessionId,
    studentId: studentId,
    absenceType: 'Justified', // or 'Unjustified'
  );
  
  String newStatus = result['new_status'];
  bool warningIssued = result['warning_issued'] ?? false;
  bool exclusionIssued = result['exclusion_issued'] ?? false;
  
  if (warningIssued) {
    showAlert('⚠️ Warning issued to student');
  }
  if (exclusionIssued) {
    showAlert('❌ Student excluded from course');
  }
} on ApiException catch (e) {
  // Possible errors:
  // - "Student not enrolled in this course"
  // - "Session not found"
  // - "Already submitted attendance"
  // - "Session expired"
  print('Absence marking failed: ${e.message}');
}
```

### UC6: Update Attendance Record
```dart
try {
  final result = await ApiService.updateAttendanceRecord(
    teacherId: teacherId,
    sessionId: sessionId,
    studentId: studentId,
    newStatus: 'Present', // or 'Justified', 'Unjustified'
  );
  
  String updatedStatus = result['new_status'];
  bool recalculated = result['recalculated'] ?? false;
  bool warningRemoved = result['warning_removed'] ?? false;
  bool exclusionRemoved = result['exclusion_removed'] ?? false;
  
  if (warningRemoved) {
    showInfo('Warning removed based on new status');
  }
  if (exclusionRemoved) {
    showInfo('Exclusion lifted based on new status');
  }
} on ApiException catch (e) {
  print('Attendance update failed: ${e.message}');
}
```

### UC7: Get Teacher Records
```dart
try {
  final result = await ApiService.getTeacherRecords(
    teacherId: teacherId,
    courseId: 'CS101', // Optional
    dateFrom: '2024-01-01', // Optional
    dateTo: '2024-12-31', // Optional
  );
  
  List<Map<String, dynamic>> records = result['records'] ?? [];
  for (var record in records) {
    print('''
      Course: ${record["course_name"]}
      Student: ${record["student_name"]}
      Date: ${record["date"]}
      Status: ${record["status"]}
    ''');
  }
} on ApiException catch (e) {
  print('Failed to load records: ${e.message}');
}
```

---

## Admin Features

### UC9a: Get All Users
```dart
try {
  final users = await ApiService.getUsers(
    role: 'Student', // Optional: 'Student', 'Teacher', 'Admin'
    status: 'Active', // Optional: 'Active', 'Suspended', 'Deleted'
  );
  
  for (var user in users) {
    print('${user["username"]} - ${user["role"]} - ${user["status"]}');
  }
} on ApiException catch (e) {
  print('Failed to load users: ${e.message}');
}
```

### UC9b: Create User
```dart
try {
  final result = await ApiService.createUser(
    username: 'newstudent',
    email: 'student@university.edu',
    fullName: 'John Doe',
    userType: 'Student', // or 'Teacher', 'Admin'
  );
  
  String userId = result['user_id'];
  String tempPassword = result['temp_password']; // Show to admin!
  
  showAlert('User created!\nTemp Password: $tempPassword');
} on ApiException catch (e) {
  // Possible errors:
  // - "Username already exists"
  // - "Email already in use"
  // - "Invalid role"
  print('User creation failed: ${e.message}');
}
```

### UC9c: Delete User (soft delete)
```dart
try {
  await ApiService.deleteUser(userId);
  showSnackBar('User deleted successfully');
} on ApiException catch (e) {
  print('User deletion failed: ${e.message}');
}
```

### UC9d: Suspend User
```dart
try {
  await ApiService.suspendUser(userId);
  showSnackBar('User suspended successfully');
} on ApiException catch (e) {
  print('User suspension failed: ${e.message}');
}
```

### UC9e: Reinstate User
```dart
try {
  await ApiService.reinstateUser(userId);
  showSnackBar('User reinstated successfully');
} on ApiException catch (e) {
  print('User reinstatement failed: ${e.message}');
}
```

### UC10a: Assign Courses to Teacher
```dart
try {
  final result = await ApiService.assignCoursesToTeacher(
    teacherId: teacherId,
    courseIds: ['CS101', 'CS102', 'CS103'],
  );
  
  int assignedCount = result['assigned_count'] ?? 0;
  showSnackBar('$assignedCount courses assigned');
} on ApiException catch (e) {
  // Possible errors:
  // - "Teacher not found"
  // - "One or more courses not found"
  // - "Some assignments already exist"
  print('Course assignment failed: ${e.message}');
}
```

### UC10b: Remove Course Assignment
```dart
try {
  await ApiService.removeTeacherCourseAssignment(
    teacherId: teacherId,
    courseId: courseId,
  );
  showSnackBar('Course assignment removed');
} on ApiException catch (e) {
  print('Assignment removal failed: ${e.message}');
}
```

### UC7 (Admin): Get All Records
```dart
try {
  final result = await ApiService.getAllRecords(
    courseId: 'CS101', // Optional
    studentId: 'S001', // Optional
    dateFrom: '2024-01-01', // Optional
    dateTo: '2024-12-31', // Optional
  );
  
  List<Map<String, dynamic>> records = result['records'] ?? [];
} on ApiException catch (e) {
  print('Failed to load records: ${e.message}');
}
```

### Export Records to CSV
```dart
try {
  final csvContent = await ApiService.exportRecordsToCSV(
    courseId: 'CS101', // Optional
  );
  
  // Save file (implementation depends on platform)
  saveFile('attendance_records.csv', csvContent);
  showSnackBar('Records exported successfully');
} on ApiException catch (e) {
  print('Export failed: ${e.message}');
}
```

---

## Error Handling Pattern

```dart
try {
  // API call
  final result = await ApiService.someMethod();
} on ApiException catch (e) {
  // Check status code for specific handling
  switch (e.statusCode) {
    case 400:
      // Bad request - validation error
      showError('Invalid data: ${e.message}');
      break;
    case 401:
      // Unauthorized - redirect to login
      showError('Session expired. Please login again.');
      navigateToLogin();
      break;
    case 403:
      // Forbidden - permission denied
      showError('You don\'t have permission: ${e.message}');
      break;
    case 404:
      // Not found
      showError('Resource not found: ${e.message}');
      break;
    case 429:
      // Too many requests - account locked
      showError('Account locked due to failed attempts. Try again later.');
      break;
    case 500:
      // Server error
      showError('Server error. Please try again later.');
      break;
    default:
      showError(e.message);
  }
} catch (e) {
  // General exception handling
  showError('Unexpected error: ${e.toString()}');
}
```

---

## Common Patterns

### With Loading State
```dart
bool _isLoading = false;

void _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final result = await ApiService.getStudentAttendanceHistory(
      studentId: studentId,
    );
    setState(() {
      _data = result;
      _isLoading = false;
    });
  } on ApiException catch (e) {
    setState(() => _isLoading = false);
    _showError(e.message);
  }
}
```

### With Caching
```dart
Map<String, dynamic>? _cachedCourses;

Future<List<Map<String, dynamic>>> getTeacherCourses() async {
  if (_cachedCourses != null) {
    return _cachedCourses!;
  }
  
  try {
    final courses = await ApiService.getTeacherCourses(teacherId);
    _cachedCourses = courses;
    return courses;
  } on ApiException catch (e) {
    _showError(e.message);
    return [];
  }
}
```

### With Retry Logic
```dart
Future<Map<String, dynamic>> _retryableRequest(
  Future<Map<String, dynamic>> Function() request,
) async {
  int attempts = 0;
  const maxAttempts = 3;
  
  while (attempts < maxAttempts) {
    try {
      return await request();
    } on ApiException catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: 1));
    }
  }
  throw Exception('Max retry attempts exceeded');
}
```

---

## Response Data Structures

### Login Response
```json
{
  "data": {
    "user_id": "S001",
    "username": "student1",
    "role": "Student",
    "email": "student@university.edu"
  }
}
```

### Attendance Code Submission Response
```json
{
  "data": {
    "session_id": "123",
    "status": "Present",
    "course_id": "CS101",
    "course_name": "Data Structures",
    "marked_at": "2024-01-15T10:30:00Z"
  }
}
```

### History Response
```json
{
  "data": {
    "stats": {
      "total_sessions": 20,
      "present_count": 18,
      "total_absences": 2,
      "justified_absences": 1,
      "unjustified_absences": 1
    },
    "records": [...],
    "active_warnings": [],
    "active_exclusions": []
  }
}
```

---

## Method Signatures Summary

| Method | Parameters | Returns | Use Case |
|--------|-----------|---------|----------|
| `login` | username, password, role | Map | UC1 |
| `submitAttendanceCode` | studentId, code | Map | UC2 |
| `getStudentAttendanceHistory` | studentId, courseId? | Map | UC3 |
| `generateAttendanceSession` | teacherId, courseId, durationMinutes?, room? | Map | UC4 |
| `markStudentAbsent` | teacherId, sessionId, studentId, absenceType | Map | UC5 |
| `updateAttendanceRecord` | teacherId, sessionId, studentId, newStatus | Map | UC6 |
| `getTeacherRecords` | teacherId, courseId?, dateFrom?, dateTo? | Map | UC7 |
| `getStudentProfile` | studentId | Map | UC8 |
| `updateStudentProfile` | studentId, email?, password?, oldPassword? | void | UC8 |
| `getUsers` | role?, status? | List | UC9 |
| `createUser` | username, email, fullName, userType | Map | UC9 |
| `deleteUser` | userId | void | UC9 |
| `suspendUser` | userId | void | UC9 |
| `reinstateUser` | userId | void | UC9 |
| `assignCoursesToTeacher` | teacherId, courseIds | Map | UC10 |
| `removeTeacherCourseAssignment` | teacherId, courseId | void | UC10 |

---

**Last Updated**: Phase 1 Complete
**Total Methods**: 30+
**Use Cases Covered**: 10/10
