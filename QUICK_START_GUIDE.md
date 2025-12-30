# Quick Setup & Testing Guide

## ⚡ Quick Start (5 minutes)

### Step 1: Setup Database
```bash
cd /home/abdou/student_attendence_app/backend
php setup.php
```
✅ Creates all tables with sample data

### Step 2: Start PHP Server
```bash
cd /home/abdou/student_attendence_app/backend
php -S localhost:8000
```
✅ Server runs on http://localhost:8000

### Step 3: Run Flutter App
```bash
cd /home/abdou/student_attendence_app/student_attendence_app_UI
flutter run -d linux
# or: flutter run (if you have a device/emulator)
```
✅ App connects to backend

---

## 📱 Test Logins

```
TEACHER:
  Username: brahimi
  Password: password
  
STUDENT:
  Username: ahmed (or fatima, hassan, layla)
  Password: password
  
ADMIN:
  Username: admin
  Password: password
```

---

## ✅ Test Workflows

### Workflow 1: Teacher Session (5 min)
```
1. Login as brahimi
2. See "Assigned Courses" list
3. Click "Start Session" on a course
4. Enter attendance code (e.g., "ABC123")
5. Click "Mark Attendance"
6. See list of enrolled students
7. Check boxes for Present/Absent/Justified
8. Click "Close Session"
9. Verify all attendance saved
```

### Workflow 2: Student Attendance (3 min)
```
1. Login as ahmed
2. See "Attendance History"
3. Click "Mark Attendance" tab
4. Enter code from teacher (e.g., "ABC123")
5. Click "Submit"
6. Get "Attendance recorded successfully!"
7. Check updated in history
```

### Workflow 3: Admin Management (5 min)
```
1. Login as admin
2. See "Users" tab with all users
3. See "Courses" tab with all courses
4. See "Assignments" tab
5. Click "Add Account" → fill form → create
6. Click "Add Course" → fill form → create
7. Click "Assign Courses to Teacher" → select teacher/courses → save
```

### Workflow 4: Warning System (5 min)
```
1. Find a student with 1-2 absences (check database)
2. Login as teacher
3. Mark that student absent multiple times
4. After 3rd unjustified absence: student expelled
5. Student tries to enter code: gets "Student is expelled" error
6. Check database: student has expelled = 1
```

---

## 🔧 If Something Doesn't Work

### PHP Server won't start
```bash
# Check if port 8000 is in use
sudo lsof -i :8000
# Kill process if needed
sudo kill -9 <PID>
# Then restart
php -S localhost:8000
```

### Database errors
```bash
# Delete and recreate database
php setup.php
# This wipes everything and creates fresh tables
```

### Flutter can't connect
```bash
# Check backend URL in api_service.dart
# Line should be:
static const String baseUrl = 'http://localhost:8000';

# For Android emulator, change to:
static const String baseUrl = 'http://10.0.2.2:8000';
```

### Attendance code not working
```
1. Make sure code is UPPERCASE
2. Make sure session is still ACTIVE (not closed)
3. Make sure student is ENROLLED in the course
4. Make sure student is not EXPELLED
```

---

## 📊 Database Verification

### Check if tables exist
```bash
mysql -u root -p
USE attendance_db;
SHOW TABLES;
```

### Check sample data
```sql
SELECT * FROM users LIMIT 5;
SELECT * FROM courses;
SELECT * FROM sessions;
SELECT * FROM attendance;
```

### Check warnings (if any)
```sql
SELECT * FROM attendance 
WHERE status = 'absent' 
GROUP BY student_id, course_id 
HAVING COUNT(*) >= 2;
```

### Check expelled students
```sql
SELECT user_id, first_name, last_name FROM users 
WHERE expelled = 1;
```

---

## 📝 Key Files

| File | Purpose |
|------|---------|
| `/backend/setup.php` | Creates database & tables |
| `/backend/config.php` | Database & error functions |
| `/backend/auth.php` | Login authentication |
| `/backend/teacher.php` | Teacher endpoints |
| `/backend/student.php` | Student endpoints |
| `/backend/attendance.php` | Attendance marking & checking |
| `/backend/admin.php` | Admin management |
| `/backend/attendance_check.php` | Warning/expulsion logic |
| `/lib/services/api_service.dart` | 50+ API methods |
| `/lib/screens/login_screen.dart` | Login UI |
| `/lib/screens/teacher_screen.dart` | Teacher dashboard |
| `/lib/screens/student_screen.dart` | Student dashboard |
| `/lib/screens/admin_screen.dart` | Admin panel |

---

## 🔌 API Endpoints Summary

### Authentication
- `POST /auth.php?action=login` → Login user

### Teacher
- `GET /teacher.php?action=get_sessions&teacher_id=X` → List sessions
- `GET /teacher.php?action=get_students&session_id=X` → List students
- `POST /teacher.php?action=start_session` → Start session
- `POST /teacher.php?action=close_session` → Close session

### Student
- `GET /student.php?action=get_courses&student_id=X` → List courses
- `GET /student.php?action=get_attendance&student_id=X` → Attendance history

### Attendance
- `POST /attendance.php?action=mark_by_code` → Mark by code (STUDENT)
- `GET /attendance.php?action=check_status&student_id=X` → Check warnings
- `PUT /attendance.php?action=update_attendance` → Update attendance (TEACHER)

### Admin
- `GET /admin.php?action=get_users` → List users
- `GET /admin.php?action=get_courses` → List courses
- `GET /admin.php?action=get_assignments` → List teacher-course mappings
- `POST /admin.php?action=create_user` → Create user
- `POST /admin.php?action=create_course` → Create course
- `POST /admin.php?action=assign_courses` → Assign courses to teacher

---

## ✨ What's Fully Working

✅ Multi-role authentication (teacher, student, admin)
✅ Teacher session management with codes
✅ Student attendance by entering code
✅ Automatic warning system (2+ absences = warning, 3+ = expelled)
✅ Attendance history tracking
✅ User management (create, delete)
✅ Course management (create, delete)
✅ Teacher-course assignment
✅ Role-based dashboard access
✅ Real database persistence
✅ Proper error handling

---

## 🚀 You're Ready!

The entire system is configured and ready to test. Just:
1. Run `php setup.php`
2. Run `php -S localhost:8000`
3. Run `flutter run`
4. Login and test!

---

## 📞 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Can't login | Check credentials (brahimi/password), verify DB setup |
| Can't mark attendance | Check code is uppercase, session is active |
| Student expelled error | Check if 3+ unjustified absences, database shows expelled=1 |
| Can't see courses | Check student enrolled in courses, teacher assigned to courses |
| Can't start session | Check teacher has courses assigned, sessions exist |
| Code not found | Verify session is active (not closed), code is exact match |

---

**All systems ready! Start testing now! 🎉**
