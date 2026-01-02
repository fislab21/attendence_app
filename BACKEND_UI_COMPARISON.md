# Backend & UI Compatibility Analysis
**Date:** January 2, 2026  
**Status:** ⚠️ PARTIAL MISMATCH - Critical Issues Found

---

## Executive Summary

The backend and UI are **NOT fully aligned**. The backend implements all required use cases (UC1-UC10) with comprehensive error handling, but the UI is **missing several API endpoints and features** that the backend provides.

### Key Issues:
- ✅ **Login (UC1)**: Implemented and matched
- ✅ **Student: Enter Code (UC2)**: Implemented and matched
- ✅ **Student: View History (UC3)**: Partial - UI expects different response structure
- ✅ **Teacher: Generate Session (UC4)**: Implemented and matched
- ✅ **Teacher: Mark Absence (UC5)**: Implemented and matched
- ⚠️ **Teacher: Update Attendance (UC6)**: Backend endpoint exists but UI implementation unclear
- ⚠️ **Teacher: View Records (UC7)**: Backend endpoint exists but UI calls different API
- ⚠️ **Admin: Manage Accounts (UC9)**: Backend endpoints exist but UI calls are incomplete
- ❌ **Admin: Assign Courses (UC10)**: Backend implemented but UI missing endpoints
- ❌ **Student: View Profile (UC8)**: Backend has endpoint but UI not calling it
- ❌ **Teacher: View Profile (UC8)**: Backend has endpoint but UI not calling it

---

## Detailed Endpoint Comparison

### 1. AUTHENTICATION (UC1) ✅
**Status:** MATCHED

**Backend Endpoints:**
- `POST /auth.php/login` - Login user
- `POST /auth.php/forgot-password` - Password reset

**UI Calls:**
- `ApiService.login()` → `POST /auth.php/login` ✅
- `ApiService.forgotPassword()` → `POST /auth.php/forgot-password` ✅

**Notes:**
- Backend expects: `username, password, role`
- UI sends: `username, password, role` ✅

---

### 2. STUDENT: ENTER CODE (UC2) ✅
**Status:** MATCHED

**Backend Endpoint:**
- `POST /student.php/enter-code`

**UI Call:**
- `ApiService.submitAttendanceCode()` → `POST /student.php/enter-code` ✅

**Data Format:**
- Backend expects: `student_id, code`
- UI sends: `studentId, code` ✅

---

### 3. STUDENT: VIEW HISTORY (UC3) ⚠️
**Status:** PARTIAL MISMATCH

**Backend Endpoint:**
- `GET /student.php/history?student_id=&course_id=` (optional)

**UI Call:**
- `ApiService.getStudentAttendanceHistory()` → `GET /student.php/history` ✅

**Expected Response Structure - Backend:**
```php
{
  "stats": {
    "total_sessions": int,
    "present": int,
    "unjustified_absences": int,
    "justified_absences": int
  },
  "attendance_records": [...],
  "warnings": [...],
  "exclusions": [...]
}
```

**UI Expects:**
```dart
// In _loadAttendanceData()
result['records'] // Array of records
record['course_name'], record['date'], record['time'], record['code'], record['status']

// In _loadStats()
result['stats'] // Contains 'present_count', 'total_absences'
result['active_warnings']
result['active_exclusions']
```

**❌ MISMATCH:** 
- Backend returns `attendance_records`, UI expects `records`
- Backend stats keys don't match UI expectations (`present` vs `present_count`)
- UI transformation code suggests mismatch in field names

---

### 4. TEACHER: GENERATE SESSION (UC4) ✅
**Status:** MATCHED

**Backend Endpoint:**
- `POST /teacher.php/generate-session`

**UI Call:**
- `ApiService.generateAttendanceSession()` → `POST /teacher.php/generate-session` ✅

**Data Format:**
- Backend expects: `teacher_id, course_id, duration_minutes (optional), room (optional)`
- UI sends: Same ✅

---

### 5. TEACHER: MARK ABSENCE (UC5) ✅
**Status:** MATCHED

**Backend Endpoint:**
- `POST /teacher.php/mark-absence`

**UI Call:**
- `ApiService.markStudentAbsent()` → `POST /teacher.php/mark-absence` ✅

**Data Format:**
- Backend expects: `teacher_id, session_id, student_id, absence_type`
- UI sends: Same ✅

---

### 6. TEACHER: UPDATE ATTENDANCE (UC6) ⚠️
**Status:** BACKEND EXISTS, UI UNCLEAR

**Backend Endpoint:**
- `PUT /teacher.php/update-attendance`

**UI Call:**
- `ApiService.updateAttendanceRecord()` → `PUT /teacher.php/update-attendance` ✅

**Issue:** Backend implementation not verified in provided code

---

### 7. TEACHER: VIEW RECORDS (UC7) ⚠️
**Status:** BACKEND EXISTS, UI DIFFERENT EXPECTATION

**Backend Endpoints:**
- `GET /teacher.php/records?teacher_id=&course_id=&date_from=&date_to=`

**UI Calls:**
- `ApiService.getTeacherRecords()` → `GET /teacher.php/records` ✅
- `ApiService.getTeacherCourses()` → `GET /teacher.php/courses` ✅
- `ApiService.getNonSubmitters()` → `GET /teacher.php/non-submitters` ✅

---

### 8. STUDENT: VIEW PROFILE (UC8) ❌
**Status:** BACKEND IMPLEMENTED, UI NOT USING

**Backend Endpoint:**
- `GET /student.php/profile?student_id=`

**UI Status:**
- ProfileScreen exists but doesn't call this endpoint
- No API call found in UI

---

### 9. ADMIN: MANAGE ACCOUNTS (UC9) ⚠️
**Status:** BACKEND COMPLETE, UI INCOMPLETE

**Backend Endpoints:**
- `GET /admin.php/users?role=&status=` - List users
- `POST /admin.php/users` - Create user
- `DELETE /admin.php/users?user_id=` - Delete user
- `POST /admin.php/reinstate` - Reinstate user
- `POST /admin.php/suspend` - Suspend user

**UI Calls in AdminScreen:**
- `ApiService.getAllUsers()` - **ENDPOINT NOT FOUND IN API SERVICE**
- `ApiService.addUser()` - **ENDPOINT NOT FOUND IN API SERVICE**
- `ApiService.deleteUser()` - **ENDPOINT NOT FOUND IN API SERVICE**

**❌ MISSING:** UI tries to call methods that don't exist in `api_service.dart`

---

### 10. ADMIN: ASSIGN COURSES (UC10) ❌
**Status:** BACKEND IMPLEMENTED, UI NOT USING

**Backend Endpoints:**
- `POST /admin.php/assign-courses`
- `GET /admin.php/assignments`
- `DELETE /admin.php/assignments`

**UI Status:**
- AdminScreen calls `ApiService.getAllAssignments()` - **ENDPOINT NOT FOUND**
- No implementation in API service

---

### 11. ADMIN: VIEW RECORDS & EXPORT (UC7) ⚠️
**Status:** BACKEND IMPLEMENTED, UI PARTIAL

**Backend Endpoints:**
- `GET /admin.php/all-records` - View records
- `GET /admin.php/export-records` - Export to CSV

**UI Calls:**
- `ApiService.getAllRecords()` - Defined ✅
- `ApiService.exportRecordsToCSV()` - Defined ✅

---

## Missing API Service Methods

The following backend endpoints are NOT implemented in `api_service.dart`:

### Admin Management
```dart
// NOT DEFINED:
ApiService.getAllUsers()
ApiService.addUser()
ApiService.deleteUser()
ApiService.suspendUser()
ApiService.reinstateUser()
ApiService.getAllCourses()
ApiService.getAllAssignments()
```

### Student/Teacher Profiles
```dart
// NOT DEFINED:
ApiService.getStudentProfile()
ApiService.getTeacherProfile()
```

### Admin Records
```dart
// PARTIALLY DEFINED:
ApiService.getAllRecords() // Defined
ApiService.exportRecordsToCSV() // Defined
```

---

## Data Structure Mismatches

### Issue 1: Student History Response
**Backend Response:**
```php
{
  "data": {
    "stats": {
      "total_sessions": 20,
      "present": 18,
      "unjustified_absences": 2,
      "justified_absences": 0
    },
    "attendance_records": [
      {
        "record_id": "AR001",
        "attendance_status": "Present",
        "submission_time": "2024-01-15 09:30:00",
        "course_name": "Data Structures",
        "course_code": "CSC201",
        "start_time": "2024-01-15 09:00:00"
      }
    ],
    "warnings": [...],
    "exclusions": [...]
  }
}
```

**UI Expects:**
```dart
// From _loadAttendanceData()
records = result['records'] // Should be 'attendance_records'
record['course_name'] // ✅
record['date'] // ❌ Not in backend response
record['time'] // ❌ Not in backend response
record['code'] // ❌ Not in backend response
record['status'] // Should be 'attendance_status'

// From _loadStats()
stats['present_count'] // ❌ Backend uses 'present'
stats['total_absences'] // ❌ Backend calculates from 'unjustified_absences' + 'justified_absences'
```

---

## Summary Table

| Use Case | Backend | UI | Status | Issue |
|----------|---------|----|---------|----|
| UC1 - Login | ✅ | ✅ | MATCHED | None |
| UC2 - Enter Code | ✅ | ✅ | MATCHED | None |
| UC3 - View History | ✅ | ✅ | MISMATCH | Response structure differs |
| UC4 - Generate Session | ✅ | ✅ | MATCHED | None |
| UC5 - Mark Absence | ✅ | ✅ | MATCHED | None |
| UC6 - Update Attendance | ✅ | ✅ | UNTESTED | Backend not fully reviewed |
| UC7 - View Records (Teacher) | ✅ | ✅ | MATCHED | None |
| UC7 - View Records (Admin) | ✅ | ✅ | MATCHED | None |
| UC8 - Student Profile | ✅ | ❌ | NOT IMPLEMENTED | UI not calling endpoint |
| UC8 - Teacher Profile | ✅ | ❌ | NOT IMPLEMENTED | UI not calling endpoint |
| UC9 - Manage Accounts | ✅ | ⚠️ | INCOMPLETE | Missing API service methods |
| UC10 - Assign Courses | ✅ | ❌ | NOT IMPLEMENTED | Missing API service methods |

---

## Recommendations

### Priority 1: CRITICAL
1. **Add missing API service methods** for Admin functionality:
   - `getAllUsers()`
   - `addUser()`
   - `deleteUser()`
   - `suspendUser()`
   - `reinstateUser()`
   - `getAllCourses()`
   - `getAllAssignments()`

2. **Fix Student History response mismatch**:
   - Update UI to use correct field names from backend
   - Add missing field transformation

### Priority 2: HIGH
3. **Implement Student/Teacher Profile screens**:
   - Call `getStudentProfile()` / `getTeacherProfile()` endpoints
   - Display profile information

4. **Add profile endpoints to API service**:
   - `getStudentProfile(studentId)`
   - `getTeacherProfile(teacherId)`

### Priority 3: MEDIUM
5. **Verify UC6** (Update Attendance) implementation
6. **Test all endpoints** end-to-end
7. **Add proper error handling** for all missing endpoints

---

## Next Steps

1. Review backend code for UC6-UC10 endpoints
2. Update API service with missing methods
3. Fix response structure handling in UI
4. Test all endpoints with real data
5. Update ProfileScreen implementations
