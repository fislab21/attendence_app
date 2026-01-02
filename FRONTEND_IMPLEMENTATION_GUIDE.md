# Flutter Frontend Implementation Guide

## Overview
This guide provides comprehensive instructions for implementing the Flutter frontend screens to integrate with the completed PHP backend API that implements all 10 use cases (UC1-UC10).

## Architecture
- **API Service**: `lib/services/api_service.dart` - Complete with 30+ methods covering all use cases
- **Error Handling**: Custom `ApiException` class for consistent error management
- **Screens**: Five main screens handling different use cases based on user role

## API Service Summary

The `api_service.dart` provides a unified interface to the backend with the following method groups:

### Authentication (UC1)
```dart
login(username, password, role) → Map<String, dynamic>
forgotPassword(email) → void
```

### Student Features
- **UC2 (Enter Code)**: `submitAttendanceCode(studentId, code)`
- **UC3 (View History)**: `getStudentAttendanceHistory(studentId, courseId?)`
- **UC8 (Profile)**: `getStudentProfile(studentId)`, `updateStudentProfile(...)`

### Teacher Features
- **UC4 (Generate Session)**: `generateAttendanceSession(teacherId, courseId, ...)`
- **UC5 (Mark Absence)**: `markStudentAbsent(teacherId, sessionId, studentId, absenceType)`
- **UC6 (Update Attendance)**: `updateAttendanceRecord(teacherId, sessionId, studentId, newStatus)`
- **UC7 (View Records)**: `getTeacherRecords(teacherId, courseId?, ...)`, `getNonSubmitters(sessionId, teacherId)`
- **Teacher Utilities**: `getTeacherCourses(teacherId)`

### Admin Features
- **UC9 (Manage Accounts)**: `getUsers(role?, status?)`, `createUser(...)`, `deleteUser(userId)`, `suspendUser(userId)`, `reinstateUser(userId)`
- **UC10 (Assign Courses)**: `assignCoursesToTeacher(teacherId, courseIds)`, `removeTeacherCourseAssignment(teacherId, courseId)`
- **UC7 (View Records)**: `getAllRecords(...)`, `exportRecordsToCSV(courseId?)`

## Implementation Tasks

### 1. StudentScreen (UC2-UC3, UC8)

#### UC2: Attendance Code Entry
**Location**: `lib/screens/student_screen.dart`

**Components needed**:
- Text field for 6-character alphanumeric code (uppercase)
- Real-time validation feedback
- Submit button
- Success/error messages

**Implementation**:
```dart
// Code input validation
bool _isValidCode(String code) {
  return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code);
}

// Submit code
void _submitCode() async {
  try {
    final result = await ApiService.submitAttendanceCode(
      studentId,
      codeController.text.toUpperCase(),
    );
    // Show success: "Attendance marked successfully"
  } on ApiException catch (e) {
    // Handle errors:
    // - "Invalid code format"
    // - "Session expired"
    // - "Code already used"
    // - "Not enrolled in this course"
  }
}
```

#### UC3: Attendance History
**Components needed**:
- Statistics card showing:
  - Total sessions attended/total sessions
  - Active warnings (yellow)
  - Active exclusions (red)
- Attendance records table with:
  - Session date/time
  - Course name
  - Status (Present/Justified/Unjustified/Absent)
  - Column for warnings/exclusions markers

**Implementation**:
```dart
void _loadHistory() async {
  try {
    final history = await ApiService.getStudentAttendanceHistory(
      studentId: studentId,
    );
    
    // Parse statistics
    final stats = history['stats'] ?? {};
    final records = history['records'] ?? [];
    final warnings = history['active_warnings'] ?? [];
    final exclusions = history['active_exclusions'] ?? [];
    
    setState(() {
      _totalSessions = stats['total_sessions'] ?? 0;
      _presentCount = stats['present_count'] ?? 0;
      _attendanceRecords = List<Map<String, dynamic>>.from(records);
      _activeWarnings = List<Map<String, dynamic>>.from(warnings);
      _activeExclusions = List<Map<String, dynamic>>.from(exclusions);
    });
  } on ApiException catch (e) {
    _showError(e.message);
  }
}
```

#### UC8: Profile Management
**Components needed**:
- Display section with:
  - Username (read-only)
  - Email (editable)
- Edit buttons for:
  - Email change (with validation)
  - Password change (with old password verification)

**Implementation**:
```dart
void _loadProfile() async {
  try {
    final profile = await ApiService.getStudentProfile(studentId);
    setState(() {
      _username = profile['username'];
      _email = profile['email'];
    });
  } on ApiException catch (e) {
    _showError('Failed to load profile: ${e.message}');
  }
}

void _updateEmail(String newEmail) async {
  try {
    await ApiService.updateStudentProfile(
      studentId: studentId,
      email: newEmail,
    );
    _showSuccess('Email updated successfully');
  } on ApiException catch (e) {
    _showError('Email update failed: ${e.message}');
  }
}

void _changePassword(String oldPassword, String newPassword) async {
  try {
    await ApiService.updateStudentProfile(
      studentId: studentId,
      password: newPassword,
      oldPassword: oldPassword,
    );
    _showSuccess('Password changed successfully');
  } on ApiException catch (e) {
    _showError('Password change failed: ${e.message}');
  }
}
```

### 2. TeacherScreen (UC4-UC7)

#### UC4: Generate Attendance Session
**Location**: `lib/screens/teacher_screen.dart`

**Components needed**:
- Dropdown/select for course (fetch via `getTeacherCourses`)
- Form for:
  - Duration in minutes (default 15)
  - Room/location (default "TBD")
- Generate button
- Display generated code and expiration time

**Implementation**:
```dart
void _loadCourses() async {
  try {
    final courses = await ApiService.getTeacherCourses(teacherId);
    setState(() => _courses = courses);
  } on ApiException catch (e) {
    _showError('Failed to load courses: ${e.message}');
  }
}

void _generateSession() async {
  try {
    final session = await ApiService.generateAttendanceSession(
      teacherId: teacherId,
      courseId: _selectedCourse['course_id'],
      durationMinutes: _durationMinutes,
      room: _roomController.text.isEmpty ? 'TBD' : _roomController.text,
    );
    
    setState(() {
      _generatedCode = session['code']; // e.g., "ABC123"
      _expiryTime = session['expires_at'];
      _currentSessionId = session['session_id'];
    });
    
    _showSuccess('Session generated: ${session["code"]}');
  } on ApiException catch (e) {
    _showError('Failed to generate session: ${e.message}');
  }
}
```

#### UC5: Mark Absence
**Components needed**:
- Session selector
- Student list (fetch via `getNonSubmitters`)
- For each student: buttons for:
  - "Justified" absence
  - "Unjustified" absence
- Confirmation on success

**Implementation**:
```dart
void _loadNonSubmitters() async {
  try {
    final students = await ApiService.getNonSubmitters(
      sessionId: _currentSessionId,
      teacherId: teacherId,
    );
    setState(() => _absentStudents = students);
  } on ApiException catch (e) {
    _showError('Failed to load students: ${e.message}');
  }
}

void _markAbsent(String studentId, String absenceType) async {
  try {
    await ApiService.markStudentAbsent(
      teacherId: teacherId,
      sessionId: _currentSessionId,
      studentId: studentId,
      absenceType: absenceType, // 'Justified' or 'Unjustified'
    );
    
    // Note: Backend automatically triggers:
    // - Warning if 2 unjustified OR 3 total absences
    // - Exclusion if 3 unjustified OR 5 total absences
    
    _showSuccess('$absenceType absence recorded');
    _loadNonSubmitters(); // Refresh
  } on ApiException catch (e) {
    _showError('Failed to mark absence: ${e.message}');
  }
}
```

#### UC6: Update Attendance
**Components needed**:
- Session selector
- Student list selector
- Status dropdown (Present/Justified/Unjustified)
- Update button

**Implementation**:
```dart
void _updateAttendance(String studentId, String newStatus) async {
  try {
    await ApiService.updateAttendanceRecord(
      teacherId: teacherId,
      sessionId: _currentSessionId,
      studentId: studentId,
      newStatus: newStatus,
    );
    
    // Backend recalculates warning/exclusion status automatically
    _showSuccess('Attendance updated to: $newStatus');
    _loadNonSubmitters(); // Refresh
  } on ApiException catch (e) {
    _showError('Failed to update attendance: ${e.message}');
  }
}
```

#### UC7: View Records
**Components needed**:
- Filters:
  - Course selector (multi-select or single)
  - Date range (from-to)
- Records table with:
  - Student name
  - Course
  - Date
  - Status
- Optional: Export to CSV button

**Implementation**:
```dart
void _loadRecords() async {
  try {
    final records = await ApiService.getTeacherRecords(
      teacherId: teacherId,
      courseId: _selectedCourse?['course_id'],
      dateFrom: _dateFromController.text,
      dateTo: _dateToController.text,
    );
    
    setState(() => _recordsList = records['records'] ?? []);
  } on ApiException catch (e) {
    _showError('Failed to load records: ${e.message}');
  }
}
```

### 3. AdminScreen (UC9-UC10)

#### UC9: Manage Accounts
**Location**: `lib/screens/admin_screen.dart`

**Components needed**:
- User list table showing:
  - Username
  - Email
  - Role
  - Status (Active/Suspended/Deleted)
  - Actions (View, Edit, Suspend/Reinstate, Delete)
- Create user button
- Status filter selector

**Implementation**:
```dart
void _loadUsers() async {
  try {
    final users = await ApiService.getUsers(
      role: _selectedRole,
      status: _selectedStatus,
    );
    setState(() => _usersList = users);
  } on ApiException catch (e) {
    _showError('Failed to load users: ${e.message}');
  }
}

void _createUser(Map<String, String> formData) async {
  try {
    final result = await ApiService.createUser(
      username: formData['username']!,
      email: formData['email']!,
      fullName: formData['full_name']!,
      userType: formData['user_type']!, // 'Student', 'Teacher', 'Admin'
    );
    
    // Backend generates temporary password and returns it
    _showSuccess(
      'User created successfully!\nTemp Password: ${result["temp_password"]}',
    );
    _loadUsers(); // Refresh
  } on ApiException catch (e) {
    _showError('Failed to create user: ${e.message}');
  }
}

void _suspendUser(String userId) async {
  try {
    await ApiService.suspendUser(userId);
    _showSuccess('User suspended successfully');
    _loadUsers();
  } on ApiException catch (e) {
    _showError('Failed to suspend user: ${e.message}');
  }
}

void _reinstateUser(String userId) async {
  try {
    await ApiService.reinstateUser(userId);
    _showSuccess('User reinstated successfully');
    _loadUsers();
  } on ApiException catch (e) {
    _showError('Failed to reinstate user: ${e.message}');
  }
}

void _deleteUser(String userId) async {
  try {
    await ApiService.deleteUser(userId);
    _showSuccess('User deleted successfully');
    _loadUsers();
  } on ApiException catch (e) {
    _showError('Failed to delete user: ${e.message}');
  }
}
```

#### UC10: Assign Courses
**Components needed**:
- Teacher selector dropdown
- Course multi-select
- Assign button
- Current assignments list showing teacher-course mappings

**Implementation**:
```dart
void _assignCourses() async {
  try {
    await ApiService.assignCoursesToTeacher(
      teacherId: _selectedTeacher['user_id'],
      courseIds: _selectedCourses.map((c) => c['course_id']).toList(),
    );
    
    _showSuccess('Courses assigned successfully');
    _loadCourses(); // Refresh
  } on ApiException catch (e) {
    _showError('Failed to assign courses: ${e.message}');
  }
}

void _removeAssignment(String teacherId, String courseId) async {
  try {
    await ApiService.removeTeacherCourseAssignment(
      teacherId: teacherId,
      courseId: courseId,
    );
    
    _showSuccess('Course assignment removed');
    _loadCourses(); // Refresh
  } on ApiException catch (e) {
    _showError('Failed to remove assignment: ${e.message}');
  }
}
```

#### UC7 (Admin): View All Records
**Components needed**:
- Advanced filters:
  - Student selector
  - Course selector
  - Date range
- Records table
- Export to CSV button

**Implementation**:
```dart
void _loadAllRecords() async {
  try {
    final records = await ApiService.getAllRecords(
      courseId: _selectedCourse?['course_id'],
      studentId: _selectedStudent?['user_id'],
      dateFrom: _dateFromController.text,
      dateTo: _dateToController.text,
    );
    
    setState(() => _recordsList = records['records'] ?? []);
  } on ApiException catch (e) {
    _showError('Failed to load records: ${e.message}');
  }
}

void _exportRecords() async {
  try {
    final csvContent = await ApiService.exportRecordsToCSV(
      courseId: _selectedCourse?['course_id'],
    );
    
    // Save to file or open download
    _saveAndOpenFile('attendance_records.csv', csvContent);
    _showSuccess('Records exported successfully');
  } on ApiException catch (e) {
    _showError('Failed to export records: ${e.message}');
  }
}
```

### 4. ProfileScreen (UC8 - General Profile)

**Components needed**:
- Display user info (username, email, role)
- Email change section
- Password change section
- Logout button

**Implementation** (shared with StudentScreen profile but for all roles):
```dart
// Same as StudentScreen profile implementation above
```

## Error Handling Patterns

All API methods throw `ApiException` which contains:
- `message` - User-friendly error message
- `statusCode` - HTTP status code (400, 401, 403, 404, 429, 500)

**Common error scenarios**:

```dart
try {
  // API call
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Redirect to login
  } else if (e.statusCode == 403) {
    // Permission denied
  } else if (e.statusCode == 404) {
    // Resource not found
  } else if (e.statusCode == 429) {
    // Too many requests (account lockout)
  } else if (e.statusCode == 400) {
    // Validation error
  } else {
    // Generic error
  }
  _showError(e.message);
}
```

## Key Backend Behaviors to Implement

### Automatic Warning/Exclusion System
The backend automatically triggers warnings and exclusions based on absence counts:
- **Warning**: 2 unjustified absences OR 3 total absences
- **Exclusion**: 3 unjustified absences OR 5 total absences

**Frontend implications**:
- When marking absence, show notification if warning/exclusion triggered
- Display active warnings/exclusions in student history
- Teachers can recalculate by updating attendance records

### Account Lockout
After 5 failed login attempts, account is locked for 30 minutes.
- Show user "Account temporarily locked" message
- Suggest password recovery

### Code Validation
Codes are 6 alphanumeric characters (A-Z, 0-9), uppercase.
- Implement real-time validation UI
- Show format hint

### Enrollment Check
Students can only submit codes for courses they're enrolled in.
- Backend returns error if not enrolled
- Show clear message about course enrollment

## Testing Checklist

- [ ] Login works for all roles (Student, Teacher, Admin)
- [ ] Failed login shows correct error (invalid credentials, account locked, suspended, etc.)
- [ ] Student code entry validates 6-char format and shows errors
- [ ] Student history shows correct statistics and records
- [ ] Student profile edit works with email validation
- [ ] Teacher course selection populates correctly
- [ ] Session generation shows unique code and expiration
- [ ] Non-submitter list updates correctly
- [ ] Marking absence as Justified/Unjustified works
- [ ] Updating attendance recalculates status
- [ ] Records view filters work correctly
- [ ] Admin can create/delete/suspend users
- [ ] Course assignment to teachers works
- [ ] Warning/exclusion status displays correctly
- [ ] API errors show friendly messages
- [ ] Network errors handled gracefully

## API Response Examples

### Login Success
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

### Attendance Code Entry Success
```json
{
  "data": {
    "session_id": "123",
    "course_id": "CS101",
    "status": "Present",
    "marked_at": "2024-01-15 10:30:00"
  }
}
```

### Student History
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
    "records": [
      {
        "session_id": "123",
        "course_name": "Data Structures",
        "date": "2024-01-15",
        "status": "Present"
      }
    ],
    "active_warnings": [],
    "active_exclusions": []
  }
}
```

## Next Steps

1. **Implement StudentScreen** - Focus on code entry validation and history display
2. **Implement TeacherScreen** - Add session generation, absence marking, records viewing
3. **Implement AdminScreen** - Add user management and course assignment
4. **Testing** - Verify all error flows and edge cases
5. **Polish UI** - Add loading states, animations, better error displays
6. **Documentation** - Create user guide for each role

---

**Total Frontend Implementation Items**: 8 screens/features × 5-10 components each = ~50+ UI components to implement

**Estimated Timeline**: 2-4 days for complete implementation with testing
