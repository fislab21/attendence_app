# Simplified Backend API Guide for Beginners

**Status:** ✅ Simple, Beginner-Friendly Code Style

---

## What You Have

Simple PHP files with easy-to-understand code:
- `config.php` - Connect to database
- `auth_simple.php` - Login
- `teacher_simple.php` - Teacher operations
- `student_simple.php` - Student operations
- `attendance_simple.php` - Attendance operations
- `admin_simple.php` - Admin operations

---

## How It Works (Simple Explanation)

### config.php
This file connects to your database. It's like the "gateway" to your database.

```php
$host = "localhost";
$user = "root";
$password = "";
$database = "student_attendence_db";

$conn = mysqli_connect($host, $user, $password, $database);
```

Every other file includes this to get database access.

---

### auth_simple.php - Login

**URL:** `http://localhost:8000/auth_simple.php?action=login`

**How to use from Flutter:**

```dart
var response = await http.post(
  Uri.parse('http://localhost:8000/auth_simple.php?action=login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'brahimi',
    'password': 'password',
    'role': 'teacher'
  }),
);

var data = jsonDecode(response.body);
if (data['success']) {
  print('Login successful: ${data['name']}');
}
```

---

### teacher_simple.php - Teacher Operations

**1. Get Teacher's Sessions**

```
URL: http://localhost:8000/teacher_simple.php?action=get_sessions&teacher_id=1

Response:
[
  {
    "session_id": 1,
    "teacher_id": 1,
    "course_id": 1,
    "course_code": "CRS002",
    "course_name": "Database Systems"
  }
]
```

**Flutter Code:**

```dart
var response = await http.get(
  Uri.parse('http://localhost:8000/teacher_simple.php?action=get_sessions&teacher_id=1'),
);

var sessions = jsonDecode(response.body);
```

---

**2. Get Students in a Session**

```
URL: http://localhost:8000/teacher_simple.php?action=get_students&session_id=1
```

---

**3. Start Session**

```
URL: http://localhost:8000/teacher_simple.php?action=start_session

Body (JSON):
{
  "session_id": 1,
  "code": "ABC123"
}
```

---

**4. Close Session**

```
URL: http://localhost:8000/teacher_simple.php?action=close_session

Body (JSON):
{
  "session_id": 1
}
```

---

### student_simple.php - Student Operations

**1. Get Student's Courses**

```
URL: http://localhost:8000/student_simple.php?action=get_courses&student_id=2
```

---

**2. Get Student's Attendance History**

```
URL: http://localhost:8000/student_simple.php?action=get_attendance&student_id=2
```

---

**3. Mark Attendance**

```
URL: http://localhost:8000/student_simple.php?action=mark_attendance

Body (JSON):
{
  "session_id": 1,
  "student_id": 2,
  "status": "present",
  "justified": 0
}
```

---

### attendance_simple.php - Attendance Operations

**1. Get Attendance for a Session**

```
URL: http://localhost:8000/attendance_simple.php?action=get_session_attendance&session_id=1
```

---

**2. Get Attendance Report for a Course**

```
URL: http://localhost:8000/attendance_simple.php?action=get_report&course_id=1
```

---

**3. Update Attendance**

```
URL: http://localhost:8000/attendance_simple.php?action=update_attendance

Body (JSON):
{
  "session_id": 1,
  "student_id": 2,
  "status": "absent",
  "justified": 1
}
```

---

### admin_simple.php - Admin Operations

**1. Get All Users**

```
URL: http://localhost:8000/admin_simple.php?action=get_users
URL: http://localhost:8000/admin_simple.php?action=get_users&role=teacher
URL: http://localhost:8000/admin_simple.php?action=get_users&role=student
```

---

**2. Get All Courses**

```
URL: http://localhost:8000/admin_simple.php?action=get_courses
```

---

**3. Create a New User**

```
URL: http://localhost:8000/admin_simple.php?action=create_user

Body (JSON):
{
  "username": "newstudent",
  "password": "password123",
  "first_name": "Ahmed",
  "last_name": "Ali",
  "email": "ahmed@example.com",
  "role": "student"
}
```

---

**4. Create a New Course**

```
URL: http://localhost:8000/admin_simple.php?action=create_course

Body (JSON):
{
  "course_code": "CRS003",
  "course_name": "Web Development"
}
```

---

**5. Assign Course to Teacher**

```
URL: http://localhost:8000/admin_simple.php?action=assign_course

Body (JSON):
{
  "teacher_id": 1,
  "course_id": 1
}
```

---

**6. Enroll Student in Course**

```
URL: http://localhost:8000/admin_simple.php?action=enroll_student

Body (JSON):
{
  "student_id": 2,
  "course_id": 1
}
```

---

**7. Delete User**

```
URL: http://localhost:8000/admin_simple.php?action=delete_user&user_id=10
```

---

**8. Delete Course**

```
URL: http://localhost:8000/admin_simple.php?action=delete_course&course_id=2
```

---

## How the Code Works (Beginner Explanation)

### Simple Query Example

```php
// This is from teacher_simple.php
$sql = "SELECT s.session_id, s.start_time, c.course_name
        FROM sessions s
        JOIN courses c ON s.course_id = c.course_id
        WHERE s.teacher_id = $teacher_id";

// Send query to database
$result = mysqli_query($conn, $sql);

// Make array to store results
$sessions = array();

// Loop through each row
while ($row = mysqli_fetch_assoc($result)) {
    $sessions[] = $row;
}

// Send back as JSON to Flutter
echo json_encode($sessions);
```

**What it does:**
1. Write a SQL query
2. Execute it with `mysqli_query()`
3. Loop through results with `while` loop
4. Put each row in an array
5. Send array as JSON

---

## Simple Insert Example

```php
// From admin_simple.php
$sql = "INSERT INTO users (username, password, first_name, last_name, email, role)
        VALUES ('$username', '$password', '$first_name', '$last_name', '$email', '$role')";

if (mysqli_query($conn, $sql)) {
    $id = mysqli_insert_id($conn);
    echo json_encode(['success' => true, 'id' => $id]);
} else {
    echo json_encode(['error' => 'Failed to create user']);
}
```

**What it does:**
1. Write INSERT query
2. Use `mysqli_query()` to run it
3. If successful, get the new ID with `mysqli_insert_id()`
4. Send back success or error message as JSON

---

## Testing with cURL (Terminal)

```bash
# Login
curl -X POST http://localhost:8000/auth_simple.php?action=login \
  -H "Content-Type: application/json" \
  -d '{"username":"brahimi","password":"password","role":"teacher"}'

# Get teacher sessions
curl http://localhost:8000/teacher_simple.php?action=get_sessions&teacher_id=1

# Mark attendance
curl -X POST http://localhost:8000/student_simple.php?action=mark_attendance \
  -H "Content-Type: application/json" \
  -d '{"session_id":1,"student_id":2,"status":"present","justified":0}'
```

---

## Summary

- **config.php** = Database connection (include in every file)
- **auth_simple.php** = Login (simple WHERE query)
- **teacher_simple.php** = Teacher stuff (SELECT with JOIN, UPDATE)
- **student_simple.php** = Student stuff (SELECT with JOIN, INSERT)
- **attendance_simple.php** = Attendance (SELECT, INSERT, UPDATE)
- **admin_simple.php** = Admin operations (INSERT, DELETE for CRUD)

**All use simple SQL queries and `mysqli_query()` - Easy to understand and learn from!**
