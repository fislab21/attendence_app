# Student Attendance System - API Implementation Guide

## Overview
This document outlines all 10 use cases with their corresponding API endpoints and implementation details.

---

## UC1: Login
**Endpoint:** `POST /auth.php/login`

### Main Flow:
1. User provides username, password, and role
2. System validates credentials against database
3. System identifies role (Student/Teacher/Admin)
4. Returns user ID and role-specific data
5. Redirects to appropriate dashboard

### Fields Required:
```json
{
  "username": "string",
  "password": "string",
  "role": "Student|Teacher|Admin"
}
```

### Response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "role_specific_id",
    "user_id": "USR_...",
    "username": "username",
    "name": "Full Name",
    "email": "email@example.com",
    "role": "student|teacher|admin"
  }
}
```

### Validations & Exceptions:
- ✓ Invalid username/password → 401 error
- ✓ Account suspended → 403 error with message
- ✓ Account deleted → 403 error with message
- ✓ Invalid role → 400 error
- ✓ Account lock after 5 failed attempts (30 min lockout)

### Alternative Flows:
- Forgot password: `POST /auth.php/forgot-password`

---

## UC2: Enter Attendance Code
**Endpoint:** `POST /student.php/enter-code`

### Main Flow:
1. Student inputs 6-character code
2. System validates code format
3. System checks code is not expired
4. System checks code has not been submitted by this student
5. System marks attendance as "Present"
6. System confirms success

### Fields Required:
```json
{
  "student_id": "STU_...",
  "code": "ABC123"
}
```

### Response:
```json
{
  "success": true,
  "message": "Attendance marked successfully",
  "data": {
    "status": "Present",
    "session_id": "SES_...",
    "message": "Your attendance has been recorded"
  }
}
```

### Validations & Exceptions:
- ✓ Code format validation (6 alphanumeric uppercase)
- ✓ Invalid/non-existent code → 400 error
- ✓ Session not active → 400 error
- ✓ Code expired → 400 error
- ✓ Student not enrolled in course → 403 error
- ✓ Duplicate submission → 400 error
- ✓ Student excluded from course → 403 error

---

## UC3: View Attendance History
**Endpoint:** `GET /student.php/history?student_id=STU_...&course_id=COURSE_...`

### Main Flow:
1. Student views their attendance records
2. System displays:
   - Total sessions
   - Justified absences count
   - Unjustified absences count
   - Active warnings
   - Exclusions
   - Session-by-session breakdown

### Response:
```json
{
  "success": true,
  "message": "Attendance history retrieved",
  "data": {
    "stats": {
      "total_sessions": 10,
      "present": 8,
      "unjustified_absences": 1,
      "justified_absences": 1
    },
    "attendance_records": [
      {
        "record_id": "AR_...",
        "attendance_status": "Present|Justified|Unjustified",
        "submission_time": "2026-01-01 10:00:00",
        "course_name": "Database Systems",
        "start_time": "2026-01-01 09:00:00"
      }
    ],
    "warnings": [
      {
        "warning_id": "WARN_...",
        "course_name": "Database Systems",
        "issue_date": "2026-01-01",
        "warning_message": "Student has reached warning threshold"
      }
    ],
    "exclusions": [
      {
        "exclusion_id": "EXCL_...",
        "course_name": "Database Systems",
        "issue_date": "2026-01-02",
        "exclusion_reason": "Student has reached exclusion threshold"
      }
    ]
  }
}
```

### Filters:
- Optional: `course_id` - Filter by specific course
- Optional: `student_id` - Get history for student

---

## UC4: Generate Attendance Session
**Endpoint:** `POST /teacher.php/generate-session`

### Main Flow:
1. Teacher selects course
2. System generates unique 6-character code (e.g., ABC123)
3. System sets expiration time (default 15 min, customizable)
4. System creates session record
5. System displays code to teacher

### Fields Required:
```json
{
  "teacher_id": "TCH_...",
  "course_id": "COURSE_...",
  "duration_minutes": 15,
  "room": "Room 101"
}
```

### Response:
```json
{
  "success": true,
  "message": "Session generated successfully",
  "data": {
    "session_id": "SES_...",
    "code": "ABC123",
    "expiration_time": "2026-01-01 10:15:00",
    "duration_minutes": 15,
    "message": "Share code with students. It will expire in 15 minutes."
  }
}
```

### Validations & Exceptions:
- ✓ Teacher not assigned to course → 403 error
- ✓ Unique code generation with duplicate check
- ✓ Automatic expiration calculation

---

## UC5: Mark Non-Submitter Absent
**Endpoint:** `POST /teacher.php/mark-absence`

### Main Flow:
1. Teacher views non-submitters for session
2. Teacher selects student
3. Teacher marks as Justified or Unjustified absence
4. System updates attendance record
5. System checks warning/exclusion thresholds
6. System auto-triggers warning or exclusion if threshold met

### Fields Required:
```json
{
  "teacher_id": "TCH_...",
  "session_id": "SES_...",
  "student_id": "STU_...",
  "absence_type": "Justified|Unjustified"
}
```

### Response - Normal:
```json
{
  "success": true,
  "message": "Absence marked successfully",
  "data": {
    "status": "Normal",
    "absence_type": "Justified"
  }
}
```

### Response - Warning Triggered:
```json
{
  "success": true,
  "warning": true,
  "message": "Absence marked. Student now has a WARNING",
  "data": {
    "status": "Warning",
    "message": "Student has reached warning threshold"
  }
}
```

### Response - Excluded:
```json
{
  "success": false,
  "message": "Absence marked. Student has been automatically EXCLUDED from this course",
  "data": {
    "status": "Excluded",
    "message": "Student has reached exclusion threshold"
  }
}
```

### Thresholds:
- **Warning**: 2 unjustified OR 3 total absences
- **Exclusion**: 3 unjustified OR 5 justified absences

### Validations & Exceptions:
- ✓ Invalid absence_type → 400 error
- ✓ Teacher not assigned to course → 403 error
- ✓ Session not found → 404 error
- ✓ Cannot mark absent if already present → 400 error
- ✓ Cannot mark excluded student absent → 403 error

---

## UC6: Update Attendance Record
**Endpoint:** `PUT /teacher.php/update-attendance`

### Main Flow:
1. Teacher finds student + session
2. Teacher changes status (Present → Justified, etc.)
3. System updates attendance record
4. System recalculates warning/exclusion status
5. System reapplies or removes warnings/exclusions if needed

### Fields Required:
```json
{
  "teacher_id": "TCH_...",
  "session_id": "SES_...",
  "student_id": "STU_...",
  "new_status": "Present|Justified|Unjustified|Absent"
}
```

### Response:
```json
{
  "success": true,
  "message": "Attendance updated successfully",
  "data": {
    "old_status": "Unjustified",
    "new_status": "Justified",
    "student_status": "Normal|Warning|Excluded"
  }
}
```

### Validations & Exceptions:
- ✓ Invalid new_status → 400 error
- ✓ Record not found → 404 error
- ✓ Teacher not authorized → 403 error
- ✓ Recalculation triggers warning/exclusion removal if conditions no longer met

---

## UC7: View Records
**Endpoint:** `GET /teacher.php/records?teacher_id=TCH_...&course_id=...&date_from=...&date_to=...`

### Main Flow:
1. Teacher views assigned courses
2. Teacher sees all sessions for their courses
3. For each session:
   - List of attendees and their status
   - Attendance statistics
4. Teacher sees active warnings
5. Teacher sees active exclusions
6. Teacher can filter by date range and course

### Response:
```json
{
  "success": true,
  "message": "Records retrieved",
  "data": {
    "sessions": [
      {
        "session_id": "SES_...",
        "course_id": "COURSE_...",
        "course_name": "Database Systems",
        "attendance_code": "ABC123",
        "start_time": "2026-01-01 09:00:00",
        "status": "Active",
        "attendance": [
          {
            "student_id": "STU_...",
            "full_name": "John Doe",
            "attendance_status": "Present"
          }
        ]
      }
    ],
    "warnings": [...],
    "exclusions": [...],
    "count": 5
  }
}
```

### Filters:
- Optional: `course_id` - Filter by course
- Optional: `date_from` - From date (YYYY-MM-DD)
- Optional: `date_to` - To date (YYYY-MM-DD)

### Alternative Endpoints:
- `GET /teacher.php/courses?teacher_id=TCH_...` - Get assigned courses
- `GET /teacher.php/non-submitters?session_id=SES_...&teacher_id=TCH_...` - Get non-submitters

---

## UC8: View and Edit Profile
**Endpoint:** `GET /student.php/profile?student_id=STU_...`

### GET Response:
```json
{
  "success": true,
  "message": "Profile retrieved",
  "data": {
    "user_id": "USR_...",
    "username": "john_doe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "user_type": "Student",
    "account_status": "Active"
  }
}
```

### Update Profile
**Endpoint:** `PUT /student.php/profile`

```json
{
  "student_id": "STU_...",
  "email": "newemail@example.com",
  "password": "newpassword",
  "old_password": "currentpassword"
}
```

### Validations & Exceptions:
- ✓ Email validation
- ✓ Email uniqueness check
- ✓ Old password verification required for password change
- ✓ Password change updates record with new password

---

## UC9: Manage Accounts
**Endpoint:** `GET/POST/DELETE /admin.php/users`

### Add User (POST)
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "full_name": "John Doe",
  "user_type": "Student|Teacher|Admin"
}
```

### Response:
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "user_id": "USR_...",
    "username": "john_doe",
    "email": "john@example.com",
    "temp_password": "a1b2c3d4",
    "message": "User created. Share temp password. User must change it on first login."
  }
}
```

### Get Users (GET)
- Optional filter: `?role=Student` or `?status=Active|Suspended|Deleted`

### Delete User (DELETE)
- `?user_id=USR_...` - Soft delete (mark as Deleted)

### Alternative Endpoints:
- `POST /admin.php/suspend` - Suspend user account
- `POST /admin.php/reinstate` - Reinstate deleted/suspended user

### Validations & Exceptions:
- ✓ Username uniqueness check
- ✓ Email uniqueness check
- ✓ Username format validation (3-50 chars, alphanumeric)
- ✓ Email format validation
- ✓ Role validation
- ✓ Soft delete (mark as Deleted, don't remove)

---

## UC10: Assign Courses to Teacher
**Endpoint:** `POST /admin.php/assign-courses`

### Fields Required:
```json
{
  "teacher_id": "TCH_...",
  "course_ids": ["COURSE_1", "COURSE_2", "COURSE_3"]
}
```

### Response:
```json
{
  "success": true,
  "message": "Courses assigned to teacher successfully",
  "data": {
    "assigned_count": 3,
    "message": "3 courses assigned"
  }
}
```

### Remove Assignment
**Endpoint:** `POST /admin.php/remove-assignment`

```json
{
  "teacher_id": "TCH_...",
  "course_id": "COURSE_1"
}
```

### Validations & Exceptions:
- ✓ Teacher existence check
- ✓ Course existence check
- ✓ Prevent duplicate assignments (via unique constraint)
- ✓ Skip invalid courses and continue

---

## UC7: Admin Records View
**Endpoint:** `GET /admin.php/all-records?course_id=...&student_id=...&date_from=...&date_to=...`

### Response:
```json
{
  "success": true,
  "message": "All records retrieved",
  "data": {
    "records": [...],
    "count": 150
  }
}
```

### Export to CSV
**Endpoint:** `GET /admin.php/export-records?course_id=...`

Returns CSV file with columns:
- Record ID
- Course
- Course Code
- Student Name
- Attendance Status
- Submitted Time
- Session Date

---

## Warning & Exclusion System

### Auto-Triggers:

**Warning:**
```
IF (unjustified_absences >= 2) OR (total_absences >= 3)
  → Issue warning
  → Lock warning in warnings table
  → User cannot be warned again until exclusion is removed
```

**Exclusion:**
```
IF (unjustified_absences >= 3) OR (justified_absences >= 5)
  → Issue exclusion
  → Remove active warning
  → Student cannot submit attendance codes
  → Student cannot be marked absent
```

### Recalculation:
When attendance status is updated:
1. Recalculate stats
2. Check if exclusion threshold met → exclude
3. If not excluded, check if warning threshold met → warn
4. If neither threshold met, remove warning/exclusion

---

## Key Validations Across All Use Cases

### Input Validation:
- ✓ Required fields check
- ✓ Email format validation
- ✓ Code format validation (6 alphanumeric)
- ✓ Role validation (Student/Teacher/Admin)
- ✓ Absence type validation (Justified/Unjustified)
- ✓ Status validation (Present/Absent/Justified/Unjustified)

### Permission Checks:
- ✓ Teacher must teach course to access session
- ✓ Student must be enrolled in course to submit code
- ✓ Admin can access all records
- ✓ Teachers access only assigned courses
- ✓ Students access only enrolled courses

### Data Integrity:
- ✓ No duplicate username/email
- ✓ No duplicate attendance submission per session
- ✓ No duplicate code submission
- ✓ Session-student pairing validation
- ✓ Teacher-course assignment validation
- ✓ Student-course enrollment validation

### Error Responses:
- 400: Bad request (validation error)
- 401: Unauthorized (authentication error)
- 403: Forbidden (permission error)
- 404: Not found
- 429: Too many requests (account locked)
- 500: Server error

---

## Database Tables Used

1. **users** - All user accounts
2. **students** - Student-specific data
3. **teachers** - Teacher-specific data
4. **admins** - Admin-specific data
5. **courses** - Course definitions
6. **teacher_courses** - Teacher-course assignments
7. **course_students** - Student enrollments
8. **sessions** - Attendance sessions
9. **attendance_records** - Individual attendance records
10. **warnings** - Student warnings
11. **exclusions** - Student exclusions

---

## Helper Functions Available

- `sanitize()` - SQL injection prevention
- `validateRequired()` - Field validation
- `validateEmail()` - Email format check
- `validateUsername()` - Username format check
- `validateRole()` - Role validation
- `validateCodeFormat()` - Code format check
- `generateAttendanceCode()` - Unique code generation
- `generateId()` - Unique ID generation
- `executeSelect()` - Query execution (multiple rows)
- `executeSelectOne()` - Query execution (single row)
- `executeInsertUpdateDelete()` - DML execution
- `recordExists()` - Existence check
- `getStudentAttendanceStats()` - Calculate stats
- `shouldWarnStudent()` - Check warning threshold
- `shouldExcludeStudent()` - Check exclusion threshold
- `issueWarning()` - Create warning record
- `issueExclusion()` - Create exclusion record
- `recalculateStudentStatus()` - Recalc and update status
- `isCodeExpired()` - Check code expiration
- `isStudentExcluded()` - Check exclusion status
- `teacherTeachesCourse()` - Permission check
- `studentEnrolledInCourse()` - Enrollment check
- `hasStudentAlreadySubmitted()` - Duplicate check

---

## Error Response Examples

### Validation Error:
```json
{
  "success": false,
  "message": "Invalid code format. Code must be 6 alphanumeric characters",
  "code": 400
}
```

### Authentication Error:
```json
{
  "success": false,
  "message": "Invalid username, password, or role",
  "code": 401
}
```

### Permission Error:
```json
{
  "success": false,
  "message": "You are not assigned to teach this course",
  "code": 403
}
```

### Not Found Error:
```json
{
  "success": false,
  "message": "Session not found",
  "code": 404
}
```

---

## Usage Summary

| Use Case | Endpoint | Method | Purpose |
|----------|----------|--------|---------|
| UC1 | /auth.php/login | POST | Login user |
| UC2 | /student.php/enter-code | POST | Submit attendance code |
| UC3 | /student.php/history | GET | View attendance history |
| UC4 | /teacher.php/generate-session | POST | Create attendance session |
| UC5 | /teacher.php/mark-absence | POST | Mark student absent |
| UC6 | /teacher.php/update-attendance | PUT | Update attendance status |
| UC7 | /teacher.php/records | GET | View records |
| UC7 | /admin.php/all-records | GET | View all records |
| UC7 | /admin.php/export-records | GET | Export to CSV |
| UC8 | /student.php/profile | GET/PUT | View/edit profile |
| UC9 | /admin.php/users | GET/POST/DELETE | Manage accounts |
| UC10 | /admin.php/assign-courses | POST | Assign courses |

