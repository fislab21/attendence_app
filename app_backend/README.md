# Student Attendance Backend API

FastAPI backend for the Student Attendance Management System using raw MySQL queries.

## Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Setup MySQL database:**
   - Make sure MySQL is running
   - Update database credentials in `connection.py` if needed
   - Run the schema file to create tables:
   ```bash
   mysql -u root -p < schema1.sql
   ```

3. **Run the server:**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## API Documentation

Once the server is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Authentication
- `POST /auth/login` - Login with username, password, and role

### Student Routes
- `POST /student/mark-attendance` - Mark attendance using attendance code
- `GET /student/attendance-records/{student_id}` - Get attendance history
- `GET /student/stats/{student_id}` - Get attendance statistics

### Teacher Routes
- `POST /teacher/sessions` - Create a new session
- `POST /teacher/sessions/start` - Start a session and generate code
- `POST /teacher/sessions/close` - Close a session
- `GET /teacher/sessions/{teacher_id}` - Get all sessions for a teacher
- `GET /teacher/sessions/{session_id}/attendance` - Get attendance list for a session
- `PUT /teacher/sessions/{session_id}/attendance/{student_id}` - Update absence type

### Admin Routes
- `POST /admin/users` - Create a new user
- `GET /admin/users` - Get all users
- `PUT /admin/users/{user_id}/status` - Update user status
- `DELETE /admin/users/{user_id}` - Delete a user
- `POST /admin/courses` - Create a new course
- `GET /admin/courses` - Get all courses
- `POST /admin/assignments` - Assign courses to teacher
- `GET /admin/assignments` - Get all course assignments
- `DELETE /admin/assignments/{assignment_id}` - Delete an assignment

## Database Schema

The database schema is defined in `schema1.sql`. Key tables:
- `users` - All users (students, teachers, admins)
- `students` - Student-specific data
- `teachers` - Teacher-specific data
- `admins` - Admin-specific data
- `courses` - Course information
- `sessions` - Class sessions with attendance codes
- `attendance_records` - Attendance records
- `teacher_courses` - Teacher-course assignments
- `course_students` - Student-course enrollments
- `warnings` - Student warnings
- `exclusions` - Student exclusions

## Notes

- Passwords are hashed using MD5 (for simplicity). Use bcrypt in production.
- All queries use raw SQL for simplicity as requested.
- CORS is enabled for all origins (configure properly for production).

