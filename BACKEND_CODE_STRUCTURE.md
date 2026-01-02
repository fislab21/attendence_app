# Backend Code Structure - Organized Method Blocks

## Quick Navigation Guide

This file shows the organization and line numbers for each method across all backend files.

---

## 📁 AUTH.PHP - Authentication API

```
╔════════════════════════════════════════════════════════════════╗
║ FILE: backend/auth.php                                         ║
║ SIZE: 135 lines                                                ║
║ METHODS: 1                                                     ║
║ USE CASES: UC1 (Login)                                         ║
╚════════════════════════════════════════════════════════════════╝

CODE STRUCTURE:

Line 1-6:       File header & documentation
Line 8:         Include config.php
Line 10-12:     CORS OPTIONS handler

Line 14-16:     Extract action from URL path

┌────────────────────────────────────────────────────────────────┐
│ METHOD 1: POST /auth.php/login                                 │
│ Lines: 18-127                                                   │
│ UC1: LOGIN                                                      │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 18-20:     Method declaration & comment
  Line 22:        Parse JSON input
  Line 23:        Validate required fields
  
  Line 25-27:     Sanitize inputs
  Line 28:        Format role (Student/Teacher/Admin)
  Line 30:        Validate role
  
  Line 32-37:     Query user by username & role
  Line 39:        Execute query
  
  Line 41-43:     Check: User exists
  Line 45-47:     Check: Account not locked
  Line 49-51:     Check: Account not suspended
  Line 53-55:     Check: Account not deleted
  
  Line 57-83:     🔐 VERIFY PASSWORD
                  - If wrong: Track failed attempts
                  - If 5+ attempts: Lock account 30min
                  - If correct: Reset attempts
  
  Line 85-88:     Update login metadata
  Line 90-100:    Get role-specific ID (student/teacher/admin)
  
  Line 102-110:   Return success response with user data

Line 113-115:   Invalid route error handler

═══════════════════════════════════════════════════════════════════

SECURITY FEATURES:
  ✓ Password verified with password_verify()
  ✓ Account lockout after 5 failed attempts
  ✓ Account status validation
  ✓ Last login timestamp updated
  ✓ SQL injection prevention via sanitize()

ERROR CASES:
  ❌ Invalid credentials → 401
  ❌ Account locked → 403
  ❌ Account suspended → 403
  ❌ Account deleted → 403
  ❌ Missing fields → 400

```

---

## 📁 STUDENT.PHP - Student API

```
╔════════════════════════════════════════════════════════════════╗
║ FILE: backend/student.php                                      ║
║ SIZE: 509 lines                                                ║
║ METHODS: 3                                                     ║
║ USE CASES: UC2, UC3, UC8 (Student operations)                 ║
╚════════════════════════════════════════════════════════════════╝

CODE STRUCTURE:

Line 1-6:       File header & documentation
Line 8:         Include config.php
Line 10-12:     CORS OPTIONS handler
Line 14-18:     Extract action & resource_id from URL

┌────────────────────────────────────────────────────────────────┐
│ METHOD 1: POST /student.php/enter-code                         │
│ Lines: 20-103                                                   │
│ UC2: ENTER ATTENDANCE CODE                                     │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 20-22:     Method declaration & UC comment
  Line 23:        Parse JSON request
  Line 25-26:     Validate required fields
  
  Line 27-28:     Sanitize inputs
  Line 29:        Convert code to uppercase
  
  Line 31-32:     Validate code format (6 alphanumeric)
  
  Line 34-36:     Query: Find session by attendance code
  Line 38:        Execute query
  
  Line 40-42:     Exception: Code not found
  Line 44-46:     Exception: Session not active
  Line 48-50:     Exception: Code expired
  
  Line 51-52:     Extract session info
  
  Line 54-56:     Exception: Check student enrolled
  Line 58-60:     Exception: Check no duplicate submission
  Line 62-64:     Exception: Check not excluded
  
  Line 66-75:     Main flow: Create attendance record
                  - Generate record ID
                  - Insert into database
                  - Set status to "Present"
  
  Line 77-81:     Return success response

  VALIDATIONS: 7 checks before marking present
  DATABASE: 3 queries + 1 insert

┌────────────────────────────────────────────────────────────────┐
│ METHOD 2: GET /student.php/history                             │
│ Lines: 104-195                                                  │
│ UC3: VIEW ATTENDANCE HISTORY                                   │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 104-106:   Method declaration & UC comment
  Line 107-111:   Extract & validate student_id
  Line 113-114:   Optional course_id filter
  
  Line 116-126:   Query: Attendance records with joins
                  JOIN sessions, courses
                  ORDER BY start_time DESC
  
  Line 128-142:   Query: Attendance statistics
                  Count by status (Present, Absent, etc)
                  Calculate totals
  
  Line 144-151:   Query: Active warnings
                  Filter by is_active = TRUE
  
  Line 153-160:   Query: Active exclusions
                  Filter by is_active = TRUE
  
  Line 162-169:   Return: Complete history object
                  - stats: Counts
                  - attendance_records: Array of records
                  - warnings: Array of warnings
                  - exclusions: Array of exclusions

  DATABASE: 4 complex queries with joins
  FILTERING: Optional course_id parameter

┌────────────────────────────────────────────────────────────────┐
│ METHOD 3: GET /student.php/profile                             │
│ Lines: 196-220                                                  │
│ UC8: VIEW PROFILE                                              │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 196-198:   Method declaration & UC comment
  Line 199-200:   Validate student_id required
  
  Line 202-207:   Query: Profile info
                  SELECT users JOIN students
                  Get full name, email, created_at
  
  Line 209-212:   Check: Profile exists
  
  Line 214-218:   Return: Profile response

  DATABASE: 1 join query
  SECURITY: Student can only view own profile

═══════════════════════════════════════════════════════════════════

TOTAL LINES: 509
- 83 lines for UC2 (Enter Code)
- 92 lines for UC3 (View History)
- 25 lines for UC8 (Profile)
- 309 remaining for helpers, validation, formatting

```

---

## 📁 TEACHER.PHP - Teacher API

```
╔════════════════════════════════════════════════════════════════╗
║ FILE: backend/teacher.php                                      ║
║ SIZE: 383 lines                                                ║
║ METHODS: 6                                                     ║
║ USE CASES: UC4, UC5, UC6, UC7 (Teacher operations)            ║
╚════════════════════════════════════════════════════════════════╝

CODE STRUCTURE:

Line 1-6:       File header & documentation
Line 8:         Include config.php
Line 10-12:     CORS OPTIONS handler
Line 14-18:     Extract action & resource_id from URL

┌────────────────────────────────────────────────────────────────┐
│ METHOD 1: POST /teacher.php/generate-session                   │
│ Lines: 20-67                                                    │
│ UC4: GENERATE ATTENDANCE SESSION                               │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 20-22:     Method declaration & UC comment
  Line 23:        Parse JSON request
  Line 25-26:     Validate required fields
  
  Line 27-30:     Sanitize inputs
  Line 31:        Optional: duration_minutes (default 15)
  Line 32:        Optional: room (default TBD)
  
  Line 34-36:     Validate: Teacher teaches this course
  
  Line 38-39:     Generate: Unique 6-char attendance code
  Line 41-42:     Calculate: Expiration time (current + duration)
  
  Line 44-53:     Create: Session record
                  - Generate session_id
                  - INSERT into sessions table
                  - Set status to "Active"
  
  Line 55-61:     Return: Success with code & expiration

  DATABASE: 1 insert operation
  CODE GENERATION: Random 6-char code

┌────────────────────────────────────────────────────────────────┐
│ METHOD 2: POST /teacher.php/mark-absence                       │
│ Lines: 69-145                                                   │
│ UC5: MARK STUDENT ABSENCE                                      │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 69-71:     Method declaration & UC comment
  Line 72:        Parse JSON request
  Line 74-75:     Validate required fields
  
  Line 76-80:     Sanitize inputs
  Line 81-82:     Validate: absence_type is valid
  
  Line 84-86:     Query: Session & course info
  Line 88-90:     Check: Teacher teaches this course
  
  Line 92-98:     Check: Existing attendance record
  
  Line 100-102:   Check: Student not already marked present
  Line 104-106:   Check: Student not excluded
  
  Line 108-124:   Main flow: Mark absence
                  - INSERT or UPDATE attendance record
                  - Set status to Justified/Unjustified
  
  Line 126-134:   Recalculate: Student status
                  - Check warning threshold
                  - Check exclusion limit
                  - Auto-trigger if needed
  
  Line 136-141:   Return: Success response

  DATABASE: 2-3 queries + insert/update
  AUTO-TRIGGER: Warnings & exclusions

┌────────────────────────────────────────────────────────────────┐
│ METHOD 3: PUT /teacher.php/update-attendance                   │
│ Lines: 147-200                                                  │
│ UC6: UPDATE ATTENDANCE RECORD                                  │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 147-149:   Method declaration & UC comment
  Line 150-160:   Parse & validate input
  
  Line 162-166:   Query: Find existing record
  Line 168-170:   Check: Record exists
  
  Line 172-182:   Update: Change attendance status
                  - UPDATE attendance_records
                  - Recalculate warnings
                  - Recalculate exclusions
  
  Line 184-191:   Return: Success response

  DATABASE: 1 find + 1-2 updates

┌────────────────────────────────────────────────────────────────┐
│ METHOD 4: GET /teacher.php/records                             │
│ Lines: 202-250                                                  │
│ UC7: VIEW TEACHER RECORDS                                      │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 202-204:   Method declaration & UC comment
  Line 205-216:   Parse query parameters
  
  Line 218-235:   Query: Complex join
                  - attendance_records
                  - JOIN sessions, courses
                  - WHERE teacher_id
                  - ORDER BY start_time DESC
  
  Line 237-244:   Return: Records + statistics

  DATABASE: 1 complex query with multiple joins
  FILTERING: Optional course_id, date range

┌────────────────────────────────────────────────────────────────┐
│ METHOD 5: GET /teacher.php/courses                             │
│ Lines: 252-270                                                  │
│ HELPER: List teacher's assigned courses                        │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 252-262:   Query: Assigned courses
                  SELECT teacher_courses
                  JOIN courses
                  WHERE teacher_id
  
  Line 264-268:   Return: Courses list

  DATABASE: 1 query with join

┌────────────────────────────────────────────────────────────────┐
│ METHOD 6: GET /teacher.php/non-submitters                      │
│ Lines: 272-290                                                  │
│ HELPER: Students who didn't submit for session                 │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 272-282:   Query: Non-submitters
                  SELECT all course students
                  EXCLUDE those with attendance
  
  Line 284-288:   Return: Students list

  DATABASE: 1 query with subquery

═══════════════════════════════════════════════════════════════════

TOTAL LINES: 383
- 47 lines for UC4 (Generate Session)
- 76 lines for UC5 (Mark Absence)
- 53 lines for UC6 (Update Attendance)
- 48 lines for UC7 (View Records)
- 18 lines for GET courses
- 18 lines for GET non-submitters

```

---

## 📁 ADMIN.PHP - Admin API

```
╔════════════════════════════════════════════════════════════════╗
║ FILE: backend/admin.php                                        ║
║ SIZE: 225 lines (after additions)                             ║
║ METHODS: 10                                                    ║
║ USE CASES: UC9, UC10, UC7 (Admin operations)                  ║
╚════════════════════════════════════════════════════════════════╝

CODE STRUCTURE:

Line 1-6:       File header & documentation
Line 8:         Include config.php
Line 10-12:     CORS OPTIONS handler
Line 14-18:     Extract action & resource_id from URL

┌────────────────────────────────────────────────────────────────┐
│ METHOD 1: GET /admin.php/users                                 │
│ Lines: 20-40                                                    │
│ UC9: GET ALL USERS                                             │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 20:        Parse query: role, status (optional)
  Line 21-23:     Build WHERE clause dynamically
  Line 24-27:     Query: All users with filters
  Line 28:        Return: Users array

  FILTERING: By role (Student/Teacher/Admin)
             By status (Active/Suspended/Deleted)

┌────────────────────────────────────────────────────────────────┐
│ METHOD 2: POST /admin.php/users                                │
│ Lines: 42-100                                                   │
│ UC9: CREATE NEW USER                                           │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 42:        Parse JSON request
  Line 43:        Validate required fields
  Line 45-50:     Sanitize inputs
  
  Line 51-54:     Validate: username format
  Line 55-56:     Validate: email format
  Line 57-58:     Validate: role valid
  
  Line 60-62:     Check: Username not duplicate
  Line 64-66:     Check: Email not duplicate
  
  Line 68:        🔐 Hash password
  Line 70:        Generate user_id
  
  Line 72-80:     Insert: User record
  Line 82-99:     Create: Role-specific record
                  (students/teachers/admins table)
  
  Line 101:       Return: Success with user_id

  DATABASE: 2-3 insert operations
  SECURITY: Password hashed, duplicates checked

┌────────────────────────────────────────────────────────────────┐
│ METHOD 3: DELETE /admin.php/users                              │
│ Lines: 102-112                                                  │
│ UC9: DELETE USER (SOFT DELETE)                                │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 102-104:   Validate: user_id provided
  Line 106:       Update: Set status = "Deleted"
  Line 107:       Return: Success

  NOTE: Soft delete - data preserved

┌────────────────────────────────────────────────────────────────┐
│ METHOD 4: POST /admin.php/reinstate                            │
│ Lines: 114-124                                                  │
│ UC9: REINSTATE USER                                            │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 115:       Parse JSON request
  Line 116:       Validate required fields
  Line 118:       Sanitize user_id
  Line 120:       Update: Set status = "Active"
  Line 121:       Return: Success

┌────────────────────────────────────────────────────────────────┐
│ METHOD 5: POST /admin.php/suspend                              │
│ Lines: 126-136                                                  │
│ UC9: SUSPEND USER                                              │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 127:       Parse JSON request
  Line 128:       Validate required fields
  Line 130:       Sanitize user_id
  Line 131:       Update: Set status = "Suspended"
  Line 132:       Return: Success

┌────────────────────────────────────────────────────────────────┐
│ METHOD 6: POST /admin.php/assign-courses                       │
│ Lines: 146-167                                                  │
│ UC10: ASSIGN COURSES TO TEACHER                               │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 147-148:   Parse & validate input
  Line 150-151:   Sanitize teacher_id
  Line 153:       Clear existing assignments
  Line 155-161:   Loop: Assign each course
                  - Validate course exists
                  - Skip if invalid
                  - INSERT assignment
  
  Line 162:       Return: Success message

  DATABASE: 1 delete + N inserts
  VALIDATION: Verify each course

┌────────────────────────────────────────────────────────────────┐
│ METHOD 7: GET /admin.php/courses [NEW]                         │
│ Lines: 169-177                                                  │
│ UC10: GET ALL AVAILABLE COURSES                               │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 170:       Query: All courses
  Line 172:       Order by name
  Line 174:       Return: Courses array

┌────────────────────────────────────────────────────────────────┐
│ METHOD 8: GET /admin.php/assignments [NEW]                     │
│ Lines: 179-192                                                  │
│ UC10: GET ALL COURSE ASSIGNMENTS                              │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 180-184:   Query: Complex join
                  teacher_courses
                  JOIN teachers, users, courses
  
  Line 186:       Order by teacher, course
  Line 189:       Return: Assignments array

  DATABASE: 1 query with 3 joins

┌────────────────────────────────────────────────────────────────┐
│ METHOD 9: POST /admin.php/remove-assignment [NEW]              │
│ Lines: 194-205                                                  │
│ UC10: REMOVE COURSE ASSIGNMENT                                │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 195-196:   Parse & validate input
  Line 198-199:   Sanitize inputs
  Line 201-202:   Delete: Assignment record
  Line 203:       Return: Success

  DATABASE: 1 delete operation

┌────────────────────────────────────────────────────────────────┐
│ METHOD 10: GET /admin.php/all-records                          │
│ Lines: 207-225                                                  │
│ UC7: VIEW ALL SYSTEM RECORDS (ADMIN)                          │
│ 🟢 PRODUCTION READY                                            │
└────────────────────────────────────────────────────────────────┘

  Line 208-217:   Query: Complex join
                  attendance_records
                  JOIN sessions, courses, students, users
  
  Line 219:       Order by start_time DESC
  Line 222:       Return: Records array

  DATABASE: 1 query with 4 joins

═══════════════════════════════════════════════════════════════════

TOTAL LINES: 225
- 20 lines for GET users
- 59 lines for POST users (create)
- 11 lines for DELETE users
- 11 lines for POST reinstate
- 11 lines for POST suspend
- 22 lines for POST assign-courses
- 9 lines for GET courses [NEW]
- 14 lines for GET assignments [NEW]
- 12 lines for POST remove-assignment [NEW]
- 19 lines for GET all-records

```

---

## 📁 CONFIG.PHP - Configuration

```
╔════════════════════════════════════════════════════════════════╗
║ FILE: backend/config.php                                       ║
║ SIZE: ~30 lines                                                ║
║ PURPOSE: Database connection & CORS setup                     ║
╚════════════════════════════════════════════════════════════════╝

CODE STRUCTURE:

Line 1-2:       Open PHP tag
Line 3-6:       Database credentials
Line 7-9:        Connect to database
Line 10-12:     Check connection
Line 13-14:     Set charset to UTF-8
Line 15-18:     CORS headers configuration
Line 19:        Set JSON content type
Line 20:        Include helpers
Line 21:        Close PHP tag

INCLUDES ALL NECESSARY:
  ✓ Database connection
  ✓ CORS headers
  ✓ Helper functions
  ✓ Charset configuration
```

---

## 📁 HELPERS.PHP - Utility Functions

```
╔════════════════════════════════════════════════════════════════╗
║ FILE: backend/helpers.php                                      ║
║ SIZE: ~400 lines                                               ║
║ FUNCTIONS: 20+                                                 ║
║ PURPOSE: Reusable utilities for all APIs                      ║
╚════════════════════════════════════════════════════════════════╝

FUNCTION CATEGORIES:

INPUT VALIDATION:
  ✓ sanitize()              - SQL injection prevention
  ✓ validateRequired()      - Required fields check
  ✓ validateRole()          - Role validation
  ✓ validateEmail()         - Email format check
  ✓ validateUsername()      - Username validation
  ✓ validateCodeFormat()    - Attendance code validation

DATA GENERATION:
  ✓ generateId()            - Unique ID generation (prefixed)
  ✓ generateAttendanceCode() - Random 6-char code

DATABASE OPERATIONS:
  ✓ executeSelect()         - SELECT multiple records
  ✓ executeSelectOne()      - SELECT single record
  ✓ executeInsertUpdateDelete() - INSERT/UPDATE/DELETE
  ✓ recordExists()          - Check record existence

BUSINESS LOGIC:
  ✓ isCodeExpired()         - Check code expiration
  ✓ studentEnrolledInCourse() - Enrollment validation
  ✓ teacherTeachesCourse()  - Assignment validation
  ✓ isStudentExcluded()     - Exclusion check
  ✓ hasStudentAlreadySubmitted() - Duplicate check
  ✓ recalculateStudentStatus() - Warning/exclusion trigger

RESPONSE FORMATTING:
  ✓ success()               - Success JSON response
  ✓ error()                 - Error JSON response
  ✓ warning()               - Warning JSON response

USAGE:
  - All backend files include helpers.php via config.php
  - Called from every method for validation & database ops
```

---

## 📊 Code Statistics

```
FILE              LINES   METHODS   USE CASES   STATUS
────────────────────────────────────────────────────────
auth.php          135     1         1           ✅
student.php       509     3         3           ✅
teacher.php       383     6         4           ✅
admin.php         225     10        3           ✅
config.php        ~30     -         -           ✅
helpers.php       ~400    20+       -           ✅
────────────────────────────────────────────────────────
TOTAL             ~1682   40+       11          ✅

ENDPOINTS: 21
USE CASES: 10
FUNCTIONS: 20+ helpers
STATUS: PRODUCTION READY
```

---

## 🔍 Quick Reference - Find Method By Use Case

```
LOGIN:
  → auth.php lines 18-127 (POST /auth.php/login)

STUDENT - ENTER CODE:
  → student.php lines 20-103 (POST /student.php/enter-code)

STUDENT - VIEW HISTORY:
  → student.php lines 104-195 (GET /student.php/history)

STUDENT - VIEW PROFILE:
  → student.php lines 196-220 (GET /student.php/profile)

TEACHER - GENERATE SESSION:
  → teacher.php lines 20-67 (POST /teacher.php/generate-session)

TEACHER - MARK ABSENCE:
  → teacher.php lines 69-145 (POST /teacher.php/mark-absence)

TEACHER - UPDATE ATTENDANCE:
  → teacher.php lines 147-200 (PUT /teacher.php/update-attendance)

TEACHER - VIEW RECORDS:
  → teacher.php lines 202-250 (GET /teacher.php/records)

TEACHER - GET COURSES:
  → teacher.php lines 252-270 (GET /teacher.php/courses)

TEACHER - NON-SUBMITTERS:
  → teacher.php lines 272-290 (GET /teacher.php/non-submitters)

ADMIN - GET USERS:
  → admin.php lines 20-40 (GET /admin.php/users)

ADMIN - CREATE USER:
  → admin.php lines 42-100 (POST /admin.php/users)

ADMIN - DELETE USER:
  → admin.php lines 102-112 (DELETE /admin.php/users)

ADMIN - REINSTATE USER:
  → admin.php lines 114-124 (POST /admin.php/reinstate)

ADMIN - SUSPEND USER:
  → admin.php lines 126-136 (POST /admin.php/suspend)

ADMIN - ASSIGN COURSES:
  → admin.php lines 146-167 (POST /admin.php/assign-courses)

ADMIN - GET COURSES:
  → admin.php lines 169-177 (GET /admin.php/courses) [NEW]

ADMIN - GET ASSIGNMENTS:
  → admin.php lines 179-192 (GET /admin.php/assignments) [NEW]

ADMIN - REMOVE ASSIGNMENT:
  → admin.php lines 194-205 (POST /admin.php/remove-assignment) [NEW]

ADMIN - VIEW ALL RECORDS:
  → admin.php lines 207-225 (GET /admin.php/all-records)
```

---

**Last Updated:** January 2, 2026  
**Total Backend Code:** ~1682 lines  
**All Methods:** Documented & Organized  
**Status:** ✅ PRODUCTION READY

