# Backend API - Complete Method Documentation

## File Structure Overview

```
backend/
├── config.php              - Database connection & CORS configuration
├── helpers.php             - Utility functions for all APIs
├── auth.php               - Authentication methods (UC1)
├── student.php            - Student operations (UC2, UC3, UC8)
├── teacher.php            - Teacher operations (UC4, UC5, UC6, UC7)
└── admin.php              - Admin operations (UC9, UC10, UC7)
```

---

## 📋 AUTH.PHP - Authentication API

### Overview
Handles user authentication, login, password reset, and account management.

**File:** `backend/auth.php`
**Use Cases:** UC1 (Login)
**Endpoints:** 2

---

### METHOD 1️⃣: UC1 - LOGIN

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /auth.php/login                               ║
║ PURPOSE:  Authenticate user and return user details          ║
║ USE CASE: UC1 - Login                                        ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "username": "string",      // Required
  "password": "string",      // Required
  "role": "Student|Teacher|Admin"  // Required
}

RESPONSE (SUCCESS):
{
  "success": true,
  "data": {
    "id": "USR001",
    "username": "johndoe",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "Student"
  }
}

RESPONSE (ERROR):
{
  "success": false,
  "message": "Invalid username, password, or role",
  "status": 401
}

LOGIC FLOW:
  1. Validate required fields (username, password, role)
  2. Sanitize inputs
  3. Query database for user by username AND role
  4. If user not found → Error 401
  5. Check if account is locked (failed attempts ≥ 5)
  6. Check if account is suspended
  7. Check if account is deleted
  8. Verify password using password_verify()
  9. If password wrong → Increment failed attempts
  10. If failed attempts ≥ 5 → Lock account for 30 minutes
  11. If password correct → Reset failed attempts, update last_login
  12. Return user data with role-specific ID

SECURITY:
  ✓ Password hashed with password_hash()
  ✓ Failed login attempts tracked
  ✓ Account lockout after 5 attempts
  ✓ Account status validation
  ✓ SQL injection prevention

ERROR CASES:
  ❌ Invalid username/password/role → 401
  ❌ Account locked → 429
  ❌ Account suspended → 403
  ❌ Account deleted → 403
  ❌ Missing required fields → 400
```

**Code Location:** Lines 20-120 in auth.php

---

### METHOD 2️⃣: FORGOT PASSWORD

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /auth.php/forgot-password                      ║
║ PURPOSE:  Send password reset email to user                   ║
║ USE CASE: UC1 - Password Recovery                            ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "email": "string"  // Required
}

RESPONSE:
{
  "success": true,
  "message": "Password reset email sent"
}

LOGIC FLOW:
  1. Validate email format
  2. Query database for user by email
  3. If not found → Return generic message (security)
  4. Generate reset token
  5. Store token with expiration
  6. Send email with reset link
  7. Return success message

SECURITY:
  ✓ Generic response (no email enumeration)
  ✓ Token expires after 1 hour
  ✓ One-time use token
```

**Code Location:** Lines 122-135 in auth.php

---

## 📋 STUDENT.PHP - Student API

### Overview
Handles student attendance submission, history viewing, and profile management.

**File:** `backend/student.php`
**Use Cases:** UC2, UC3, UC8 (Student operations)
**Endpoints:** 3

---

### METHOD 1️⃣: UC2 - ENTER ATTENDANCE CODE

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /student.php/enter-code                        ║
║ PURPOSE:  Student submits attendance code                     ║
║ USE CASE: UC2 - Enter Code                                   ║
║ FLOW:     Code validation → Session check → Enroll check →   ║
║           Duplicate check → Exclusion check → Mark present    ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "student_id": "STU001",  // Required
  "code": "ABC123"         // Required (case-insensitive, 6 chars)
}

RESPONSE (SUCCESS):
{
  "success": true,
  "data": {
    "status": "Present",
    "session_id": "SES001",
    "message": "Your attendance has been recorded"
  }
}

RESPONSE (ERROR):
{
  "success": false,
  "message": "Invalid attendance code",
  "status": 400
}

VALIDATION STEPS:
  ✓ Code format: 6 alphanumeric characters
  ✓ Code exists in active session
  ✓ Session status is "Active"
  ✓ Code not expired
  ✓ Student enrolled in course
  ✓ Student hasn't submitted already
  ✓ Student not excluded from course

ERROR CASES:
  ❌ Invalid code format → 400
  ❌ Code not found → 400
  ❌ Session not active → 400
  ❌ Code expired → 400
  ❌ Not enrolled in course → 403
  ❌ Already submitted for session → 400
  ❌ Student excluded → 403

DATABASE OPERATIONS:
  1. SELECT sessions WHERE code matches
  2. Check session status and expiration
  3. SELECT student enrollment
  4. SELECT existing attendance record
  5. SELECT student exclusions
  6. INSERT attendance_record (Present)
```

**Code Location:** Lines 23-103 in student.php

---

### METHOD 2️⃣: UC3 - VIEW ATTENDANCE HISTORY

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /student.php/history                            ║
║ QUERY:    ?student_id=STU001&course_id=CRS001 (optional)     ║
║ PURPOSE:  View attendance history and statistics              ║
║ USE CASE: UC3 - View History                                 ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
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
        "session_id": "SES001",
        "course_id": "CRS001",
        "course_name": "Data Structures",
        "course_code": "CSC201",
        "start_time": "2024-01-15 09:00:00"
      }
    ],
    "warnings": [
      {
        "warning_id": "WRN001",
        "course_id": "CRS001",
        "course_name": "Data Structures",
        "issue_date": "2024-01-15",
        "warning_message": "High absence rate"
      }
    ],
    "exclusions": [
      {
        "exclusion_id": "EXC001",
        "course_id": "CRS001",
        "course_name": "Data Structures",
        "issue_date": "2024-01-15",
        "exclusion_reason": "Exceeded absence limit"
      }
    ]
  }
}

DATABASE OPERATIONS:
  1. SELECT attendance_records JOIN sessions, courses
  2. Calculate stats (total, present, absences by type)
  3. SELECT active warnings
  4. SELECT active exclusions
  5. ORDER BY session start_time DESC

FILTERING:
  - Optional: filter by course_id
  - Optional: filter by date range
```

**Code Location:** Lines 105-195 in student.php

---

### METHOD 3️⃣: UC8 - VIEW PROFILE

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /student.php/profile                            ║
║ QUERY:    ?student_id=STU001                                 ║
║ PURPOSE:  View student profile information                    ║
║ USE CASE: UC8 - View Profile                                ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": {
    "user_id": "USR001",
    "username": "johndoe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "account_status": "Active",
    "created_at": "2024-01-01 10:00:00"
  }
}

DATABASE OPERATIONS:
  1. SELECT users JOIN students
  2. Filter by student_id
```

**Code Location:** Lines 197-220 in student.php

---

## 📋 TEACHER.PHP - Teacher API

### Overview
Handles session generation, absence marking, attendance updates, and record viewing.

**File:** `backend/teacher.php`
**Use Cases:** UC4, UC5, UC6, UC7 (Teacher operations)
**Endpoints:** 6

---

### METHOD 1️⃣: UC4 - GENERATE ATTENDANCE SESSION

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /teacher.php/generate-session                  ║
║ PURPOSE:  Create new attendance session with code             ║
║ USE CASE: UC4 - Generate Session                             ║
║ FLOW:     Validate teacher → Generate code → Create session   ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "teacher_id": "TCH001",
  "course_id": "CRS001",
  "duration_minutes": 15,      // Optional (default: 15)
  "room": "A101"               // Optional (default: TBD)
}

RESPONSE:
{
  "success": true,
  "data": {
    "session_id": "SES001",
    "code": "ABC123XYZ",
    "expiration_time": "2024-01-15 09:15:00",
    "duration_minutes": 15,
    "message": "Share code with students. It will expire in 15 minutes."
  }
}

VALIDATION:
  ✓ Teacher assigned to course
  ✓ Valid duration (1-60 minutes)
  ✓ Valid course exists

DATABASE OPERATIONS:
  1. Verify teacher teaches course
  2. Generate unique 6-char code
  3. Calculate expiration time
  4. INSERT into sessions table
  5. Set status to "Active"

CODE GENERATION:
  - 6 alphanumeric characters
  - Unique constraint in database
  - Case-insensitive matching
```

**Code Location:** Lines 26-67 in teacher.php

---

### METHOD 2️⃣: UC5 - MARK STUDENT ABSENCE

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /teacher.php/mark-absence                      ║
║ PURPOSE:  Mark student absent (justified/unjustified)         ║
║ USE CASE: UC5 - Mark Absence                                 ║
║ FLOW:     Validate → Check status → Mark absence →            ║
║           Recalculate warning/exclusion                       ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "teacher_id": "TCH001",
  "session_id": "SES001",
  "student_id": "STU001",
  "absence_type": "Justified|Unjustified"  // Required
}

RESPONSE:
{
  "success": true,
  "data": {
    "student_id": "STU001",
    "session_id": "SES001",
    "status": "Unjustified",
    "message": "Absence marked"
  }
}

VALIDATION:
  ✓ Teacher teaches course for session
  ✓ absence_type is Justified or Unjustified
  ✓ Student not already marked Present
  ✓ Student not excluded

DATABASE OPERATIONS:
  1. Verify teacher authorization
  2. Check existing attendance record
  3. UPDATE or INSERT attendance_record
  4. Recalculate student status
  5. Auto-trigger warning if threshold reached
  6. Auto-trigger exclusion if limit exceeded
```

**Code Location:** Lines 69-145 in teacher.php

---

### METHOD 3️⃣: UC6 - UPDATE ATTENDANCE RECORD

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: PUT /teacher.php/update-attendance                  ║
║ PURPOSE:  Modify attendance status (Present/Justified/etc)    ║
║ USE CASE: UC6 - Update History                               ║
║ FLOW:     Find record → Change status → Recalculate trigger   ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "teacher_id": "TCH001",
  "session_id": "SES001",
  "student_id": "STU001",
  "new_status": "Present|Justified|Unjustified"
}

RESPONSE:
{
  "success": true,
  "data": {
    "status": "Present",
    "message": "Attendance updated successfully"
  }
}

DATABASE OPERATIONS:
  1. Find attendance record
  2. UPDATE status
  3. Recalculate student warnings/exclusions
  4. Remove warning if absences drop below threshold
  5. Remove exclusion if absences drop below limit
```

**Code Location:** Lines 147-200 in teacher.php

---

### METHOD 4️⃣: UC7 - VIEW TEACHER RECORDS

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /teacher.php/records                            ║
║ QUERY:    ?teacher_id=TCH001&course_id=CRS001&date_from=X   ║
║ PURPOSE:  View all attendance records for courses             ║
║ USE CASE: UC7 - View Records                                 ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": {
    "records": [...],
    "stats": {...},
    "filters": {...}
  }
}

FILTERING:
  - By teacher_id (required)
  - By course_id (optional)
  - By date range (optional)

DATABASE OPERATIONS:
  1. SELECT attendance_records with JOIN
  2. Filter by course and dates
  3. Calculate aggregated statistics
```

**Code Location:** Lines 202-250 in teacher.php

---

### METHOD 5️⃣: GET TEACHER COURSES

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /teacher.php/courses                            ║
║ QUERY:    ?teacher_id=TCH001                                 ║
║ PURPOSE:  List all courses assigned to teacher                ║
║ USE CASE: UC7 - Course list for filtering                    ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": [
    {
      "course_id": "CRS001",
      "course_code": "CSC201",
      "course_name": "Data Structures",
      "student_count": 30
    }
  ]
}

DATABASE OPERATIONS:
  1. SELECT courses where teacher assigned
  2. COUNT enrolled students
  3. ORDER by course name
```

**Code Location:** Lines 252-270 in teacher.php

---

### METHOD 6️⃣: GET NON-SUBMITTERS

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /teacher.php/non-submitters                     ║
║ QUERY:    ?session_id=SES001&teacher_id=TCH001              ║
║ PURPOSE:  List students who haven't submitted for session     ║
║ USE CASE: UC5 - Mark absences for non-submitters             ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": [
    {
      "student_id": "STU001",
      "user_id": "USR001",
      "full_name": "John Doe",
      "email": "john@example.com",
      "status": "Not submitted"
    }
  ]
}

DATABASE OPERATIONS:
  1. SELECT all students enrolled in course
  2. EXCLUDE those with attendance record for session
  3. Return remaining students
```

**Code Location:** Lines 272-290 in teacher.php

---

## 📋 ADMIN.PHP - Admin API

### Overview
Handles user management, course assignments, and system-wide records.

**File:** `backend/admin.php`
**Use Cases:** UC9, UC10, UC7 (Admin operations)
**Endpoints:** 10

---

### METHOD 1️⃣: UC9 - GET ALL USERS

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /admin.php/users                                ║
║ QUERY:    ?role=Student&status=Active                        ║
║ PURPOSE:  List all users with filtering                       ║
║ USE CASE: UC9 - Manage Accounts                              ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": [
    {
      "user_id": "USR001",
      "username": "johndoe",
      "email": "john@example.com",
      "full_name": "John Doe",
      "user_type": "Student",
      "account_status": "Active",
      "created_at": "2024-01-01"
    }
  ]
}

FILTERING:
  - role: Student|Teacher|Admin (optional)
  - status: Active|Suspended|Deleted (optional)

DATABASE OPERATIONS:
  1. SELECT all users
  2. Apply WHERE filters
  3. ORDER by created_at DESC
```

**Code Location:** Lines 20-40 in admin.php

---

### METHOD 2️⃣: UC9 - CREATE USER

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /admin.php/users                               ║
║ PURPOSE:  Create new user account                             ║
║ USE CASE: UC9 - Add Account                                  ║
║ FLOW:     Validate → Check duplicates → Hash password →       ║
║           Create user → Create role-specific record           ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "username": "johndoe",
  "email": "john@example.com",
  "full_name": "John Doe",
  "user_type": "Student|Teacher|Admin",
  "password": "string"
}

RESPONSE:
{
  "success": true,
  "data": {
    "user_id": "USR001",
    "username": "johndoe",
    "email": "john@example.com"
  }
}

VALIDATION:
  ✓ Username unique
  ✓ Email unique
  ✓ Valid user_type
  ✓ Password strong
  ✓ Email format valid

DATABASE OPERATIONS:
  1. CHECK username not exists
  2. CHECK email not exists
  3. HASH password
  4. INSERT users record
  5. INSERT role-specific record (students/teachers/admins)
  6. Set status to "Active"

SECURITY:
  ✓ Password hashed with PASSWORD_DEFAULT
  ✓ Unique constraints on username and email
```

**Code Location:** Lines 42-100 in admin.php

---

### METHOD 3️⃣: UC9 - DELETE USER

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: DELETE /admin.php/users                             ║
║ QUERY:    ?user_id=USR001                                    ║
║ PURPOSE:  Soft-delete user account                            ║
║ USE CASE: UC9 - Delete Account                               ║
╚════════════════════════════════════════════════════════════════╝

DATABASE OPERATIONS:
  1. UPDATE users SET account_status = 'Deleted'
  2. Soft delete (data preserved)
```

**Code Location:** Lines 102-112 in admin.php

---

### METHOD 4️⃣: UC9 - REINSTATE USER

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /admin.php/reinstate                           ║
║ PURPOSE:  Restore deleted/suspended user                      ║
║ USE CASE: UC9 - Reinstate Account                            ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "user_id": "USR001"
}

DATABASE OPERATIONS:
  1. UPDATE users SET account_status = 'Active'
  2. WHERE user_id = requested
```

**Code Location:** Lines 114-124 in admin.php

---

### METHOD 5️⃣: UC9 - SUSPEND USER

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /admin.php/suspend                             ║
║ PURPOSE:  Temporarily suspend user account                    ║
║ USE CASE: UC9 - Suspend Account                              ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "user_id": "USR001"
}

DATABASE OPERATIONS:
  1. UPDATE users SET account_status = 'Suspended'
```

**Code Location:** Lines 126-136 in admin.php

---

### METHOD 6️⃣: UC10 - ASSIGN COURSES

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /admin.php/assign-courses                      ║
║ PURPOSE:  Assign courses to teacher                           ║
║ USE CASE: UC10 - Assign Courses                              ║
║ FLOW:     Clear existing → Validate courses → Insert new      ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "teacher_id": "TCH001",
  "course_ids": ["CRS001", "CRS002", "CRS003"]
}

RESPONSE:
{
  "success": true,
  "data": {
    "message": "3 courses assigned"
  }
}

DATABASE OPERATIONS:
  1. DELETE FROM teacher_courses WHERE teacher_id
  2. For each course_id:
     - VALIDATE course exists
     - INSERT teacher_courses record
  3. Skip invalid courses

CONSTRAINTS:
  - One-to-many: teacher → courses
  - Prevents duplicates
```

**Code Location:** Lines 146-167 in admin.php

---

### METHOD 7️⃣: UC10 - GET ALL COURSES

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /admin.php/courses                              ║
║ PURPOSE:  List all available courses                          ║
║ USE CASE: UC10 - Course list for assignment                  ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": [
    {
      "course_id": "CRS001",
      "course_code": "CSC201",
      "course_name": "Data Structures",
      "description": "...",
      "created_at": "2024-01-01"
    }
  ]
}

DATABASE OPERATIONS:
  1. SELECT all courses
  2. ORDER BY course_name
```

**Code Location:** Lines 169-177 in admin.php

---

### METHOD 8️⃣: UC10 - GET ALL ASSIGNMENTS

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /admin.php/assignments                          ║
║ PURPOSE:  List all teacher-course assignments                 ║
║ USE CASE: UC10 - View Assignments                            ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": [
    {
      "assignment_id": "TASN001",
      "teacher_id": "TCH001",
      "teacher_name": "John Doe",
      "course_id": "CRS001",
      "course_name": "Data Structures"
    }
  ]
}

DATABASE OPERATIONS:
  1. SELECT teacher_courses JOIN teachers, users, courses
  2. ORDER BY teacher_name, course_name
```

**Code Location:** Lines 179-192 in admin.php

---

### METHOD 9️⃣: UC10 - REMOVE ASSIGNMENT

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: POST /admin.php/remove-assignment                   ║
║ PURPOSE:  Remove course from teacher assignment               ║
║ USE CASE: UC10 - Remove Assignment                           ║
╚════════════════════════════════════════════════════════════════╝

REQUEST:
{
  "teacher_id": "TCH001",
  "course_id": "CRS001"
}

DATABASE OPERATIONS:
  1. DELETE FROM teacher_courses
  2. WHERE teacher_id AND course_id
```

**Code Location:** Lines 194-205 in admin.php

---

### METHOD 🔟: UC7 - VIEW ALL RECORDS

```
╔════════════════════════════════════════════════════════════════╗
║ ENDPOINT: GET /admin.php/all-records                          ║
║ PURPOSE:  System-wide attendance records                       ║
║ USE CASE: UC7 - View Records (Admin)                         ║
╚════════════════════════════════════════════════════════════════╝

RESPONSE:
{
  "success": true,
  "data": [
    {
      "record_id": "AR001",
      "session_id": "SES001",
      "student_id": "STU001",
      "course_name": "Data Structures",
      "full_name": "John Doe",
      "attendance_status": "Present",
      "submission_time": "2024-01-15 09:30:00"
    }
  ]
}

DATABASE OPERATIONS:
  1. SELECT attendance_records JOIN sessions, courses, students, users
  2. ORDER BY start_time DESC
```

**Code Location:** Lines 207-225 in admin.php

---

## 📋 HELPERS.PHP - Utility Functions

### Overview
Contains reusable helper functions used across all API files.

**File:** `backend/helpers.php`
**Functions:** 20+

---

### Key Helper Functions

```
╔════════════════════════════════════════════════════════════════╗
║ COMMON UTILITY FUNCTIONS                                       ║
╚════════════════════════════════════════════════════════════════╝

✓ sanitize($input)
  - Prevents SQL injection
  - Used for all user inputs

✓ validateRequired($data, $fields)
  - Validates required fields present
  - Returns 400 if missing

✓ validateRole($role)
  - Validates role in (Student, Teacher, Admin)

✓ validateEmail($email)
  - Validates email format

✓ validateUsername($username)
  - Checks username format

✓ validateCodeFormat($code)
  - 6 alphanumeric characters

✓ generateId($prefix)
  - Generates unique IDs (USR001, TCH001, etc.)

✓ generateAttendanceCode()
  - Random 6-char code

✓ executeSelect($sql)
  - Returns multiple records

✓ executeSelectOne($sql)
  - Returns single record

✓ executeInsertUpdateDelete($sql)
  - Modifies database

✓ success($message, $data)
  - Returns success JSON response

✓ error($message, $status)
  - Returns error JSON response

✓ warning($message, $data)
  - Returns warning JSON response

✓ recordExists($table, $field, $value)
  - Checks if record exists

✓ isCodeExpired($time)
  - Checks if code expired

✓ studentEnrolledInCourse($student_id, $course_id)
  - Validates enrollment

✓ teacherTeachesCourse($teacher_id, $course_id)
  - Validates assignment

✓ isStudentExcluded($student_id, $course_id)
  - Checks exclusion status

✓ hasStudentAlreadySubmitted($student_id, $session_id)
  - Duplicate submission check

✓ recalculateStudentStatus($student_id, $course_id)
  - Auto-triggers warnings/exclusions
```

---

## 📊 API Summary Table

| File | Method | Endpoint | HTTP | Use Case | Status |
|------|--------|----------|------|----------|--------|
| auth.php | Login | /auth.php/login | POST | UC1 | ✅ |
| auth.php | Forgot Password | /auth.php/forgot-password | POST | UC1 | ✅ |
| student.php | Enter Code | /student.php/enter-code | POST | UC2 | ✅ |
| student.php | View History | /student.php/history | GET | UC3 | ✅ |
| student.php | View Profile | /student.php/profile | GET | UC8 | ✅ |
| teacher.php | Generate Session | /teacher.php/generate-session | POST | UC4 | ✅ |
| teacher.php | Mark Absence | /teacher.php/mark-absence | POST | UC5 | ✅ |
| teacher.php | Update Attendance | /teacher.php/update-attendance | PUT | UC6 | ✅ |
| teacher.php | View Records | /teacher.php/records | GET | UC7 | ✅ |
| teacher.php | Get Courses | /teacher.php/courses | GET | UC7 | ✅ |
| teacher.php | Non-Submitters | /teacher.php/non-submitters | GET | UC5 | ✅ |
| admin.php | Get Users | /admin.php/users | GET | UC9 | ✅ |
| admin.php | Create User | /admin.php/users | POST | UC9 | ✅ |
| admin.php | Delete User | /admin.php/users | DELETE | UC9 | ✅ |
| admin.php | Reinstate User | /admin.php/reinstate | POST | UC9 | ✅ |
| admin.php | Suspend User | /admin.php/suspend | POST | UC9 | ✅ |
| admin.php | Assign Courses | /admin.php/assign-courses | POST | UC10 | ✅ |
| admin.php | Get Courses | /admin.php/courses | GET | UC10 | ✅ |
| admin.php | Get Assignments | /admin.php/assignments | GET | UC10 | ✅ |
| admin.php | Remove Assignment | /admin.php/remove-assignment | POST | UC10 | ✅ |
| admin.php | View All Records | /admin.php/all-records | GET | UC7 | ✅ |

---

## 🔐 Security Features Across All APIs

```
AUTHENTICATION & AUTHORIZATION:
  ✓ Password hashing with PASSWORD_DEFAULT
  ✓ Password verification via password_verify()
  ✓ Role-based access control (Student, Teacher, Admin)
  ✓ Account lockout after 5 failed attempts
  ✓ Account status validation (Active, Suspended, Deleted)

INPUT VALIDATION:
  ✓ sanitize() prevents SQL injection
  ✓ Type casting and validation
  ✓ Format validation (email, username, code)
  ✓ Required field validation

DATA PROTECTION:
  ✓ Soft deletes (data preserved)
  ✓ Audit trail via created_at, last_login
  ✓ CORS headers for cross-origin requests
  ✓ JSON request/response format

ERROR HANDLING:
  ✓ Proper HTTP status codes
  ✓ User-friendly error messages
  ✓ No sensitive info in errors
  ✓ Consistent error response format
```

---

**Last Updated:** January 2, 2026  
**Total Endpoints:** 21  
**Total Use Cases:** 10  
**All Status:** ✅ PRODUCTION READY

