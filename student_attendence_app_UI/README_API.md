# API Integration Guide

## Backend Connection

The Flutter app is now connected to the FastAPI backend. Here's how to configure it:

### 1. Update Base URL

Edit `lib/services/api_service.dart` and update the `baseUrl` constant:

```dart
static const String baseUrl = 'http://localhost:8000';
```

**Important:** Use the correct URL based on your platform:

- **Android Emulator**: `http://10.0.2.2:8000`
- **iOS Simulator**: `http://localhost:8000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:8000` (e.g., `http://192.168.1.100:8000`)

### 2. Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
```
Look for IPv4 Address

**Linux/Mac:**
```bash
ifconfig
# or
ip addr show
```

### 3. Start the Backend

Make sure the FastAPI backend is running:

```bash
cd app_backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The `--host 0.0.0.0` is important to allow connections from other devices.

### 4. Install Dependencies

Make sure you've installed the HTTP package:

```bash
cd student_attendence_app_UI
flutter pub get
```

### 5. Test the Connection

1. Start the backend server
2. Run the Flutter app
3. Try logging in with test credentials

## Available API Endpoints

All endpoints are implemented in `lib/services/api_service.dart`:

### Authentication
- `login(username, password, role)`
- `unlockAccount(userId)`

### Student
- `markAttendance(code, studentId)`
- `getAttendanceRecords(studentId)`
- `getStudentStats(studentId, courseId?)`

### Teacher
- `createSession(courseId, teacherId, date, {room, timeSlot})`
- `startSession(sessionId)`
- `closeSession(sessionId)`
- `getTeacherSessions(teacherId)`
- `getSessionAttendance(sessionId)`
- `updateAttendanceStatus(sessionId, studentId, absenceType)`

### Admin
- User management: `createUser`, `getAllUsers`, `updateUserStatus`, `deleteUser`
- Course management: `createCourse`, `getAllCourses`, `deleteCourse`
- Assignments: `assignCoursesToTeacher`, `getAllAssignments`, `deleteAssignment`
- Enrollments: `enrollStudentInCourses`, `getStudentEnrollments`
- Warnings: `createWarning`, `getWarnings`
- Exclusions: `createExclusion`, `getExclusions`

## Error Handling

All API calls include error handling. Errors are displayed to users with appropriate messages.

## Network Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Troubleshooting

1. **Connection refused**: Check if backend is running and URL is correct
2. **Timeout**: Check firewall settings
3. **CORS errors**: Backend CORS is already configured for all origins
4. **404 errors**: Check endpoint paths match exactly

