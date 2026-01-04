# Attendance List Display - Debugging Guide

## Problem
Students list is not showing up in the "Manage Session Attendance" dialog, displaying "No students enrolled" instead.

## Root Cause Analysis
The issue could be one of:
1. Course has no students enrolled in the database
2. API endpoint `session-attendance` is returning empty list
3. Session ID being passed doesn't match any session in the database
4. Student data fields mismatch between backend and frontend

## How to Debug

### Step 1: Run the Flutter App with Debug Output
```bash
cd /home/abdou/student_attendence_app/student_attendence_app_UI
flutter run -d linux
```

Watch the terminal where you ran `flutter run` (this is where debugPrint output appears).

### Step 2: Navigate to Active Session
1. Log in as a teacher
2. Go to Teacher screen
3. Find an active session (should have "ACTIVE" status badge and green border)
4. Click the "View List" button

### Step 3: Check Console Output
In the `flutter run` terminal, look for these debug messages:

```
=== LOADING STUDENTS ===
Session ID: <session_id_here>
User ID: <user_id_here>
API RESPONSE: Students received: <number>
Raw students list: [...]
```

### Step 4: Interpret Results

**If you see:**
```
Students received: 0
Raw students list: []
```
→ The API returned no students. Go to Step 5 (Backend Check).

**If you see:**
```
Students received: 2
Student: STU001 - Alice - Present
Student: STU002 - Bob - absent
```
→ Students are being fetched correctly. The problem is likely in the dialog rendering. Go to Step 6.

**If you see:**
```
ERROR: No user logged in
```
→ Authentication issue. The user object isn't set. Check AuthService.

**If you see an exception like:**
```
Error loading students: ApiException(...)
```
→ API call failed. Note the error message and go to Step 5.

---

## Step 5: Backend Check

Test the API endpoint directly:

```bash
# Replace these with actual values:
# BASE_URL: http://localhost:8000 (or your server)
# SESSION_ID: actual session ID from database
# USER_ID: teacher's user ID

curl "http://localhost:8000/backend/teacher.php/session-attendance?session_id=SES001&user_id=USR001"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Session attendance retrieved",
  "data": [
    {
      "student_id": "STU001",
      "name": "Alice",
      "user_id": "USR002",
      "attendance_status": "absent",
      "record_id": null,
      "submission_time": null
    }
  ]
}
```

**If you see:**
```json
{"data": []}
```
→ Course has no students. Add students to the course in the database:
```sql
INSERT INTO course_students (enrollment_id, student_id, course_id, enrolled_at)
VALUES ('ENRL001', 'STU001', 'CRS001', NOW());
```

**If you see:**
```json
{"success": false, "message": "Session not found"}
```
→ Session ID doesn't exist. Check that you're using the correct session_id.

**If you see:**
```json
{"success": false, "message": "Not authorized"}
```
→ Teacher doesn't teach the course. Verify teacher_courses table.

---

## Step 6: If Students ARE Returned

If the API is returning students but the dialog still shows "No students enrolled", the issue is in Flutter state management.

Check the debug output in `_buildAttendanceDialog`:

```
=== BUILDING DIALOG ===
SessionId: SES001
Students count: 0
Attendance map keys: [...]
Session data: {...}
```

**If Students count is 0 but API returned 2:**
→ `setState()` didn't work properly. This could be a timing issue where the dialog is built before setState completes.

### Fix for Timing Issue

The problem might be that the dialog builder is synchronous but the data loading is async. The solution: Make the dialog wait for data or add a check.

Current code flow:
```
await _loadStudentsForSession()  // async, calls setState
if (!mounted) return;
showDialog(...)  // but dialog might render before setState
_buildAttendanceDialog()  // accesses _students (might still be empty)
```

---

## Complete Data Flow Verification

### Verify Session Exists:
```sql
SELECT session_id, course_id, status FROM sessions WHERE session_id = 'SES001';
```

### Verify Course Exists:
```sql
SELECT course_id, course_name FROM courses WHERE course_id = (
  SELECT course_id FROM sessions WHERE session_id = 'SES001'
);
```

### Verify Students Enrolled:
```sql
SELECT cs.student_id, u.full_name, u.username 
FROM course_students cs
JOIN students s ON cs.student_id = s.student_id
JOIN users u ON s.user_id = u.user_id
WHERE cs.course_id = (SELECT course_id FROM sessions WHERE session_id = 'SES001');
```

### Verify Teacher Teaches Course:
```sql
SELECT tc.teacher_id FROM teacher_courses tc
WHERE tc.course_id = (SELECT course_id FROM sessions WHERE session_id = 'SES001')
AND tc.teacher_id = (SELECT teacher_id FROM teachers WHERE user_id = 'USR001');
```

---

## Quick Test: Add Manual Test Data

If no courses/students exist:

```sql
-- Create a test course
INSERT INTO courses (course_id, course_name, course_code)
VALUES ('CRS_TEST', 'Test Course', 'TC101');

-- Assign teacher to course
INSERT INTO teacher_courses (assignment_id, teacher_id, course_id)
VALUES ('ASSIGN1', 'TCH001', 'CRS_TEST');

-- Create test students
INSERT INTO students (student_id, user_id)
VALUES ('STU_TEST1', 'USR_TEST1'),
       ('STU_TEST2', 'USR_TEST2');

INSERT INTO users (user_id, username, password, email, full_name, user_type)
VALUES ('USR_TEST1', 'student1', 'hashed_pass', 'stu1@test.com', 'Alice', 'Student'),
       ('USR_TEST2', 'student2', 'hashed_pass', 'stu2@test.com', 'Bob', 'Student');

-- Enroll students in course
INSERT INTO course_students (enrollment_id, student_id, course_id)
VALUES ('ENRL1', 'STU_TEST1', 'CRS_TEST'),
       ('ENRL2', 'STU_TEST2', 'CRS_TEST');

-- Create an active session
INSERT INTO sessions (session_id, course_id, teacher_id, attendance_code, start_time, expiration_time, status, room)
VALUES ('SES_TEST', 'CRS_TEST', 'TCH001', 'ABC123', NOW(), DATE_ADD(NOW(), INTERVAL 1 HOUR), 'Active', 'Room 101');
```

---

## Expected Behavior After Fix

1. Click "View List" on an active session
2. Dialog opens and shows list of enrolled students
3. Each student has:
   - Name and ID displayed
   - Color-coded status badge (green for present, red for absent)
   - Present/Absent buttons to mark attendance
   - If marked absent: Justified/Unjustified selector appears
4. "Save & Close Session" button persists all changes to database

---

## Logs to Collect

When reporting the issue, please provide:

1. **Flutter console output** when clicking "View List"
2. **Database query result** from the verification queries above
3. **Curl response** from the API endpoint
4. **What appears on screen** (screenshot if possible)
