# Implementation Checklist & Testing Guide

## Backend Implementation Status

### ✅ COMPLETED

#### Helper Functions (helpers.php)
- [x] Database query helpers (executeSelect, executeSelectOne, etc.)
- [x] Input validation functions (sanitize, validateRequired, validateEmail, etc.)
- [x] Attendance/Warning/Exclusion logic
- [x] Permission checks (teacherTeachesCourse, studentEnrolledInCourse, etc.)
- [x] Unique code generation with duplicate check
- [x] ID generation with prefix
- [x] Response helpers (success, warning, error)

#### Authentication (auth.php)
- [x] Login with role identification
- [x] Account status validation (Suspended, Deleted)
- [x] Failed login attempt tracking (lock after 5 attempts)
- [x] Forgot password endpoint
- [x] Session support with role-specific IDs

#### Student API (student.php)
- [x] UC2: Enter attendance code with validations
- [x] UC3: View attendance history with stats
- [x] UC8: View/edit profile

#### Teacher API (teacher.php)
- [x] UC4: Generate attendance session with unique code
- [x] UC5: Mark student absent (Justified/Unjustified)
- [x] UC6: Update attendance record with recalculation
- [x] UC7: View records with filtering (course, date range)
- [x] UC7 Alternative: Get courses and non-submitters

#### Admin API (admin.php)
- [x] UC9: Create user with temp password
- [x] UC9: Delete/Suspend/Reinstate users
- [x] UC10: Assign courses to teachers
- [x] UC10: Remove course assignments
- [x] UC7: View all records
- [x] UC7: Export records to CSV

#### Warning & Exclusion System
- [x] Auto-warning (2 unjustified OR 3 total absences)
- [x] Auto-exclusion (3 unjustified OR 5 justified absences)
- [x] Recalculation on status update
- [x] Reapply/remove warnings and exclusions dynamically

---

## Testing Guide

### Test Setup

Before testing, ensure:
1. Database is created: `student_attendence_db`
2. Schema is imported: `schema1.sql`
3. PHP server running: `php -S localhost:8000`
4. Helper file exists: `helpers.php`

### Sample Test Data

```sql
-- Insert sample users
INSERT INTO users (user_id, username, password, email, full_name, user_type, account_status)
VALUES 
('USR_001', 'brahimi', 'password', 'brahimi@example.com', 'Brahimi Ahmed', 'Teacher', 'Active'),
('USR_002', 'student1', 'password', 'student1@example.com', 'John Doe', 'Student', 'Active'),
('USR_003', 'admin1', 'password', 'admin1@example.com', 'Admin User', 'Admin', 'Active');

-- Insert role-specific records
INSERT INTO teachers (teacher_id, user_id) VALUES ('TCH_001', 'USR_001');
INSERT INTO students (student_id, user_id) VALUES ('STU_001', 'USR_002');
INSERT INTO admins (admin_id, user_id) VALUES ('ADM_001', 'USR_003');

-- Insert courses
INSERT INTO courses (course_id, course_code, course_name)
VALUES ('COURSE_001', 'CS101', 'Database Systems');

-- Assign teacher to course
INSERT INTO teacher_courses (assignment_id, teacher_id, course_id)
VALUES ('TASN_001', 'TCH_001', 'COURSE_001');

-- Enroll student in course
INSERT INTO course_students (enrollment_id, student_id, course_id)
VALUES ('ENRL_001', 'STU_001', 'COURSE_001');
```

---

### Test Cases

#### UC1: LOGIN TESTS

**Test 1.1: Successful Login**
```bash
curl -X POST http://localhost:8000/auth.php/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "brahimi",
    "password": "password",
    "role": "teacher"
  }'
```
Expected: 200, returns user data with role

**Test 1.2: Invalid Credentials**
```bash
curl -X POST http://localhost:8000/auth.php/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "brahimi",
    "password": "wrongpassword",
    "role": "teacher"
  }'
```
Expected: 401, "Invalid username, password, or role"

**Test 1.3: Suspended Account**
```sql
UPDATE users SET account_status = 'Suspended' WHERE user_id = 'USR_001';
```
Then login attempt should return 403 error

**Test 1.4: Account Lockout (5 failed attempts)**
```bash
# Run login with wrong password 5 times
# After 5th attempt, should lock for 30 minutes
```
Expected: 429, "Account locked for 30 minutes"

---

#### UC2: ENTER CODE TESTS

**Test 2.1: Valid Code Submission**
```bash
# First, generate a session
curl -X POST http://localhost:8000/teacher.php/generate-session \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "course_id": "COURSE_001"
  }'
# Note the returned code (e.g., ABC123)

# Then student submits code
curl -X POST http://localhost:8000/student.php/enter-code \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "code": "ABC123"
  }'
```
Expected: 200, "Attendance marked successfully"

**Test 2.2: Expired Code**
```bash
# Wait for code to expire (default 15 min) or manually update session
UPDATE sessions SET expiration_time = DATE_SUB(NOW(), INTERVAL 1 MINUTE) 
WHERE session_id = 'SES_001';

# Try to submit
curl -X POST http://localhost:8000/student.php/enter-code \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "code": "ABC123"
  }'
```
Expected: 400, "This attendance code has expired"

**Test 2.3: Duplicate Submission**
```bash
# Submit same code twice
curl -X POST http://localhost:8000/student.php/enter-code \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "code": "ABC123"
  }'
# Second submission
curl -X POST http://localhost:8000/student.php/enter-code \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "code": "ABC123"
  }'
```
Expected: Second returns 400, "You have already marked attendance"

**Test 2.4: Student Not Enrolled**
```bash
# Use a session for a different course
curl -X POST http://localhost:8000/student.php/enter-code \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "code": "XYZ789"
  }'
```
Expected: 403, "You are not enrolled in this course"

---

#### UC3: VIEW HISTORY TESTS

**Test 3.1: View Complete History**
```bash
curl -X GET "http://localhost:8000/student.php/history?student_id=STU_001"
```
Expected: 200, returns stats, records, warnings, exclusions

**Test 3.2: View Course-Specific History**
```bash
curl -X GET "http://localhost:8000/student.php/history?student_id=STU_001&course_id=COURSE_001"
```
Expected: 200, filtered to course only

---

#### UC4: GENERATE SESSION TESTS

**Test 4.1: Successful Session Generation**
```bash
curl -X POST http://localhost:8000/teacher.php/generate-session \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "course_id": "COURSE_001",
    "duration_minutes": 15,
    "room": "Room 101"
  }'
```
Expected: 200, returns unique code and session_id

**Test 4.2: Verify Code Uniqueness**
```bash
# Generate 10 sessions and verify all codes are different
for i in {1..10}; do
  curl -X POST http://localhost:8000/teacher.php/generate-session \
    -H "Content-Type: application/json" \
    -d '{
      "teacher_id": "TCH_001",
      "course_id": "COURSE_001"
    }' | jq '.data.code'
done
```
Expected: All 10 codes should be unique

**Test 4.3: Teacher Not Assigned to Course**
```bash
# Create another teacher without this course assignment
INSERT INTO teachers (teacher_id, user_id) VALUES ('TCH_002', 'USR_004');
INSERT INTO users (user_id, username, password, email, full_name, user_type, account_status)
VALUES ('USR_004', 'teacher2', 'password', 'teacher2@example.com', 'Teacher 2', 'Teacher', 'Active');

curl -X POST http://localhost:8000/teacher.php/generate-session \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_002",
    "course_id": "COURSE_001"
  }'
```
Expected: 403, "You are not assigned to teach this course"

---

#### UC5: MARK ABSENCE TESTS

**Test 5.1: Mark Unjustified Absence**
```bash
# First mark attendance for 2 unjustified absences
curl -X POST http://localhost:8000/teacher.php/mark-absence \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "session_id": "SES_001",
    "student_id": "STU_001",
    "absence_type": "Unjustified"
  }'
```
Expected: 200, normal status

**Test 5.2: Auto-Warning Trigger (2 unjustified)**
```bash
# Mark 2nd unjustified absence
curl -X POST http://localhost:8000/teacher.php/mark-absence \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "session_id": "SES_002",
    "student_id": "STU_001",
    "absence_type": "Unjustified"
  }'
```
Expected: 200 with warning flag, "Student now has a WARNING"

**Test 5.3: Auto-Exclusion Trigger (3 unjustified)**
```bash
# Mark 3rd unjustified absence
curl -X POST http://localhost:8000/teacher.php/mark-absence \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "session_id": "SES_003",
    "student_id": "STU_001",
    "absence_type": "Unjustified"
  }'
```
Expected: 400, "Student has been automatically EXCLUDED"

**Test 5.4: Cannot Mark Excluded Student Absent**
```bash
# Try to mark another absence for excluded student
curl -X POST http://localhost:8000/teacher.php/mark-absence \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "session_id": "SES_004",
    "student_id": "STU_001",
    "absence_type": "Unjustified"
  }'
```
Expected: 403, "Cannot mark absent for excluded student"

---

#### UC6: UPDATE ATTENDANCE TESTS

**Test 6.1: Change Unjustified to Justified**
```bash
# First mark as unjustified
curl -X POST http://localhost:8000/teacher.php/mark-absence \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "session_id": "SES_005",
    "student_id": "STU_002",
    "absence_type": "Unjustified"
  }'

# Then update to justified
curl -X PUT http://localhost:8000/teacher.php/update-attendance \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "session_id": "SES_005",
    "student_id": "STU_002",
    "new_status": "Justified"
  }'
```
Expected: 200, old_status: Unjustified, new_status: Justified

**Test 6.2: Recalculation Removes Warning**
```bash
# Mark 2 unjustified (triggers warning)
# Then change one to justified
# Check that warning is removed
curl -X GET "http://localhost:8000/student.php/history?student_id=STU_002"
```
Expected: warnings array should be empty

---

#### UC7: VIEW RECORDS TESTS

**Test 7.1: Get Teacher Records**
```bash
curl -X GET "http://localhost:8000/teacher.php/records?teacher_id=TCH_001"
```
Expected: 200, sessions with attendance details

**Test 7.2: Filter by Course**
```bash
curl -X GET "http://localhost:8000/teacher.php/records?teacher_id=TCH_001&course_id=COURSE_001"
```
Expected: 200, filtered to course only

**Test 7.3: Filter by Date Range**
```bash
curl -X GET "http://localhost:8000/teacher.php/records?teacher_id=TCH_001&date_from=2026-01-01&date_to=2026-01-31"
```
Expected: 200, sessions within date range

**Test 7.4: Admin Export to CSV**
```bash
curl -X GET "http://localhost:8000/admin.php/export-records" \
  > attendance_export.csv
```
Expected: CSV file with attendance data

---

#### UC8: PROFILE TESTS

**Test 8.1: View Profile**
```bash
curl -X GET "http://localhost:8000/student.php/profile?student_id=STU_001"
```
Expected: 200, user profile data

**Test 8.2: Update Email**
```bash
curl -X PUT http://localhost:8000/student.php/profile \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "email": "newemail@example.com"
  }'
```
Expected: 200, email updated

**Test 8.3: Update Password (with verification)**
```bash
curl -X PUT http://localhost:8000/student.php/profile \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU_001",
    "old_password": "password",
    "password": "newpassword"
  }'
```
Expected: 200, password updated

---

#### UC9: MANAGE ACCOUNTS TESTS

**Test 9.1: Create User**
```bash
curl -X POST http://localhost:8000/admin.php/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newstudent",
    "email": "newstudent@example.com",
    "full_name": "New Student",
    "user_type": "Student"
  }'
```
Expected: 200, user created with temp password

**Test 9.2: Duplicate Username**
```bash
curl -X POST http://localhost:8000/admin.php/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "brahimi",
    "email": "different@example.com",
    "full_name": "Another User",
    "user_type": "Student"
  }'
```
Expected: 400, "Username already exists"

**Test 9.3: Delete User**
```bash
curl -X DELETE "http://localhost:8000/admin.php/users?user_id=USR_002"
```
Expected: 200, user marked as deleted

**Test 9.4: Suspend User**
```bash
curl -X POST http://localhost:8000/admin.php/suspend \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "USR_002"
  }'
```
Expected: 200, account suspended

**Test 9.5: Reinstate User**
```bash
curl -X POST http://localhost:8000/admin.php/reinstate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "USR_002"
  }'
```
Expected: 200, account reinstated

---

#### UC10: ASSIGN COURSES TESTS

**Test 10.1: Assign Multiple Courses**
```bash
# First create another course
INSERT INTO courses (course_id, course_code, course_name)
VALUES ('COURSE_002', 'CS102', 'Web Development');

# Assign both to teacher
curl -X POST http://localhost:8000/admin.php/assign-courses \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "course_ids": ["COURSE_001", "COURSE_002"]
  }'
```
Expected: 200, "2 courses assigned"

**Test 10.2: Remove Assignment**
```bash
curl -X POST http://localhost:8000/admin.php/remove-assignment \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": "TCH_001",
    "course_id": "COURSE_001"
  }'
```
Expected: 200, assignment removed

---

## Verification Checklist

### Database Verification

```sql
-- Check users created
SELECT * FROM users;

-- Check attendance records
SELECT * FROM attendance_records;

-- Check warnings issued
SELECT * FROM warnings WHERE is_active = TRUE;

-- Check exclusions issued
SELECT * FROM exclusions WHERE is_active = TRUE;

-- Check sessions generated
SELECT session_id, attendance_code, status, expiration_time FROM sessions;

-- Check teacher assignments
SELECT * FROM teacher_courses;

-- Check student enrollments
SELECT * FROM course_students;
```

### API Response Verification

All responses should follow format:
```json
{
  "success": true/false,
  "message": "string",
  "data": {},
  "code": 200|400|401|403|404|429
}
```

### Error Handling Verification

- ✓ All validation errors return 400 with descriptive message
- ✓ All auth errors return 401 with "Invalid credentials"
- ✓ All permission errors return 403 with "Not authorized" or similar
- ✓ All not-found errors return 404 with entity name
- ✓ All rate limits return 429
- ✓ All server errors return 500 with error details

---

## Deployment Checklist

- [ ] Database created and schema imported
- [ ] All PHP files deployed
- [ ] Helpers.php is included in config.php
- [ ] PHP version >= 7.4
- [ ] MySQLi extension enabled
- [ ] CORS headers set correctly
- [ ] File permissions correct (readable by web server)
- [ ] Database credentials configured in config.php
- [ ] Error logging enabled
- [ ] Test data inserted
- [ ] All 10 use cases tested

---

## Performance Notes

- Queries use indexed columns (user_id, session_id, student_id, course_id)
- Limit queries use appropriate WHERE clauses
- Session generation includes duplicate check loop (rare collisions)
- Recalculation logic runs only when needed (on attendance update)
- CSV export recommended for data <10,000 records

