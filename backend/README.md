# Student Attendance System - Complete PHP Backend API

**Status:** ✅ Complete with Separated APIs

---

## Quick Setup

### 1. Run Database Setup
```bash
php setup.php
```

### 2. Start PHP Server
```bash
php -S localhost:8000
```

### 3. Test Auth
```bash
curl -X POST http://localhost:8000/auth.php/login \
  -H "Content-Type: application/json" \
  -d '{"username":"brahimi","password":"password","role":"teacher"}'
```

---

## API Structure

✅ **Separated APIs by Role:**
- `auth.php` - Login for all roles
- `teacher.php` - Teacher endpoints
- `student.php` - Student endpoints
- `admin.php` - Admin endpoints
- `attendance.php` - Attendance management

---

## 1. AUTH API (`auth.php`)

### Login
```
POST /auth.php/login
Body: { "username": "brahimi", "password": "password", "role": "teacher" }
Response: { "success": true, "id": 1, "name": "Brahimi Ahmed", "role": "teacher" }
```

---

## 2. TEACHER API (`teacher.php`)

### Get Teacher Sessions
```
GET /teacher.php/sessions/{teacher_id}
Response: Array of sessions
```

Example:
```bash
curl http://localhost:8000/teacher.php/sessions/1
```

### Get Teacher Courses
```
GET /teacher.php/courses/{teacher_id}
Response: Array of assigned courses
```

### Start Session
```
POST /teacher.php/sessions/start
Body: { "session_id": 1, "code": "ABC123" }
Response: { "success": true, "code": "ABC123" }
```

### Close Session
```
POST /teacher.php/sessions/close
Body: { "session_id": 1 }
Response: { "success": true, "message": "Session closed" }
```

---

## 3. STUDENT API (`student.php`)

### Get Student Enrollments
```
GET /student.php/enrollments/{student_id}
Response: Array of enrolled courses with sessions
```

Example:
```bash
curl http://localhost:8000/student.php/enrollments/2
```

### Get Student Attendance Records
```
GET /student.php/attendance/{student_id}
Response: Array of attendance records
```

### Get Student Profile
```
GET /student.php/profile/{student_id}
Response: Student info
```

### Mark Attendance (Using Code)
```
POST /student.php/attendance/mark
Body: { "session_id": 1, "student_id": 2, "code": "ABC123" }
Response: { "success": true, "message": "Attendance marked as present" }
```

---

## 4. ADMIN API (`admin.php`)

### Get All Users
```
GET /admin.php/users?role=teacher
GET /admin.php/users?role=student
GET /admin.php/users
Response: Array of users filtered by role
```

### Get All Courses
```
GET /admin.php/courses
Response: Array of all courses
```

### Get All Assignments
```
GET /admin.php/assignments
Response: Array of teacher-course assignments
```

### Get All Sessions
```
GET /admin.php/sessions
Response: Array of all sessions with teacher/course info
```

### Create User
```
POST /admin.php/users
Body: { "username": "newuser", "password": "pass", "first_name": "John", "last_name": "Doe", "email": "john@example.com", "role": "student" }
Response: { "success": true, "id": 10 }
```

### Create Course
```
POST /admin.php/courses
Body: { "course_code": "CRS003", "course_name": "Web Development" }
Response: { "success": true, "id": 2 }
```

### Assign Course to Teacher
```
POST /admin.php/assignments
Body: { "teacher_id": 1, "course_id": 1 }
Response: { "success": true, "message": "Course assigned to teacher" }
```

### Enroll Student in Course
```
POST /admin.php/enrollments
Body: { "student_id": 2, "course_id": 1 }
Response: { "success": true, "message": "Student enrolled in course" }
```

### Update User
```
PUT /admin.php/users/{user_id}
Body: { "first_name": "Updated", "email": "new@example.com" }
Response: { "success": true }
```

### Update Course
```
PUT /admin.php/courses/{course_id}
Body: { "course_name": "New Name" }
Response: { "success": true }
```

### Delete User
```
DELETE /admin.php/users/{user_id}
Response: { "success": true }
```

### Delete Course
```
DELETE /admin.php/courses/{course_id}
Response: { "success": true }
```

---

## 5. ATTENDANCE API (`attendance.php`)

### Get Session Attendance
```
GET /attendance.php/session/{session_id}
Response: Array of attendance records for session
```

### Get Student Attendance History
```
GET /attendance.php/student/{student_id}
Response: Array of all student attendance records
```

### Get Course Attendance Report
```
GET /attendance.php/report/{course_id}
Response: Attendance statistics by student
```

Example:
```bash
curl http://localhost:8000/attendance.php/report/1
```

### Update Attendance Status
```
PUT /attendance.php/update
Body: { "session_id": 1, "student_id": 2, "status": "present", "justified": false }
Response: { "success": true, "message": "Attendance updated" }
```

---

## Sample Data

**Teacher:**
- ID: 1, Username: brahimi, Name: Brahimi Ahmed

**Students:**
- ID: 2 - Ahmed Ali
- ID: 3 - Fatima Ben
- ID: 4 - Mohamed Hassan
- ID: 5 - Layla Zara

**Course:**
- ID: 1, Code: CRS002, Name: Database Systems

**Session:**
- ID: 1, Teacher: 1, Course: 1, Room: Room 101, Time: 2025-01-02 09:00:00

---

## Testing with cURL

```bash
# Login as teacher
curl -X POST http://localhost:8000/auth.php/login \
  -H "Content-Type: application/json" \
  -d '{"username":"brahimi","password":"password","role":"teacher"}'

# Get teacher sessions
curl http://localhost:8000/teacher.php/sessions/1

# Start session
curl -X POST http://localhost:8000/teacher.php/sessions/start \
  -H "Content-Type: application/json" \
  -d '{"session_id":1,"code":"ABC123"}'

# Update attendance
curl -X PUT http://localhost:8000/attendance.php/update \
  -H "Content-Type: application/json" \
  -d '{"session_id":1,"student_id":2,"status":"present","justified":false}'

# Get all teachers
curl 'http://localhost:8000/admin.php/users?role=teacher'
```

---

## Files Structure

```
backend/
├── config.php          - Database connection
├── setup.php           - Database initialization
├── auth.php            - Authentication
├── teacher.php         - Teacher endpoints
├── student.php         - Student endpoints
├── admin.php           - Admin endpoints
├── attendance.php      - Attendance endpoints
├── .htaccess          - URL routing
└── README.md          - This file
```

---

## Separated by Role

✅ **Teacher API** - Sessions, course management, attendance marking
✅ **Student API** - Enrollments, attendance marking, history
✅ **Admin API** - User management, course management, assignments
✅ **Attendance API** - Attendance records, reports
✅ **Auth API** - Login for all roles

---

**Status:** ✅ Complete and Ready for Flutter Integration
