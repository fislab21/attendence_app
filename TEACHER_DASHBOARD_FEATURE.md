# Teacher Dashboard - Assigned Courses Feature

## Overview

Teachers can now see all their assigned courses on their dashboard and create sessions for each course with a single click. This streamlines the workflow for managing attendance sessions.

## How It Works

### 1. **Assigned Courses Section**
When a teacher logs in or the app loads, it automatically displays all courses assigned to that teacher:
- **Course Name** and **Course Code**
- **Status** indicator (Scheduled)
- **Create Session** button for each course

### 2. **Creating a Session**
Teachers can click the "Create Session" button on any assigned course to:
- Create a new attendance session for that course
- Auto-generate an attendance code
- Make the session active and ready for students to mark attendance

### 3. **Today's Sessions**
Below the "Assigned Courses" section, teachers can see:
- All active sessions for today
- Ability to start sessions (generate codes)
- Ability to close sessions
- View attendance list for each session

## Technical Implementation

### Frontend Changes (`lib/screens/teacher_screen.dart`)

#### New State Variables
```dart
final List<Map<String, dynamic>> _courses = [];  // Store assigned courses
```

#### New Methods

**`initState()`**
- Automatically loads assigned courses when the screen loads

**`_loadAssignedCourses()`**
- Fetches all teacher sessions from the API
- Extracts unique courses from the sessions
- Displays only one card per course (no duplicates)

**`_createSession(Map<String, dynamic> course)`**
- Takes a course object
- Calls `ApiService.createSession()` to create a new session
- Shows success/error message
- Reloads courses after creation

**`_buildAssignedCoursesList()`**
- Returns a list of course cards
- Each card has:
  - Course name and code
  - Status badge
  - "Create Session" button
  - Proper styling and icons

### Backend Integration

#### API Endpoint Used
- `GET /teacher/sessions/{teacher_id}` - Get all sessions (which includes course information)
- `POST /teacher/sessions` - Create a new session

#### API Response Format (for getTeacherSessions)
```json
[
  {
    "id": "session_id",
    "course_id": "course_id",
    "course": "Course Name",
    "course_code": "CSC-101",
    "date": "2025-12-25T10:00:00",
    "room": "Room 101",
    "time": "10:00 AM",
    "code": "ABC123",
    "expiresAt": "2025-12-25T12:00:00",
    "status": "scheduled"
  }
]
```

## User Flow

### Before (Old Behavior)
1. Teacher logs in
2. Dashboard shows empty sessions list
3. Teacher had no way to see assigned courses
4. Teacher couldn't easily create sessions

### After (New Behavior)
1. Teacher logs in
2. Dashboard automatically loads assigned courses
3. Teacher sees all assigned courses in "Your Assigned Courses" section
4. Teacher can click "Create Session" for any course
5. Session is created and appears in "Today's Sessions" section
6. Teacher can then start the session to generate an attendance code

## Data Flow Diagram

```
Teacher Login
    ↓
initState() called
    ↓
_loadAssignedCourses() executed
    ↓
API: GET /teacher/sessions/{teacher_id}
    ↓
Extract unique courses from sessions
    ↓
Display courses in "Your Assigned Courses" section
    ↓
Teacher clicks "Create Session"
    ↓
_createSession() called
    ↓
API: POST /teacher/sessions (creates new session)
    ↓
Success message shown
    ↓
Reload courses
    ↓
New session appears in "Today's Sessions" section
```

## Key Features

✅ **Auto-Load on Login** - Courses load automatically when teacher opens the app
✅ **One Click Session Creation** - Create sessions directly from course cards
✅ **No Duplicates** - Courses are deduplicated even if multiple sessions exist
✅ **Real-time Feedback** - Success/error messages for user actions
✅ **Organized Layout** - Clear separation between courses and sessions
✅ **Status Indicators** - Visual feedback on course status

## Error Handling

If a course fails to load:
- Error message is printed to console
- User can retry by navigating away and back to the screen
- Graceful degradation - other courses still display

If session creation fails:
- Red error snackbar displayed with error message
- User can retry

## Testing Checklist

- [ ] Admin assigns courses to a teacher
- [ ] Teacher logs in and sees assigned courses
- [ ] Course details (name, code) display correctly
- [ ] Teacher clicks "Create Session"
- [ ] Session is created successfully
- [ ] Success message appears
- [ ] New session appears in "Today's Sessions"
- [ ] Teacher can start the session and see attendance code

## UI Components

### Assigned Courses Card
```
┌─────────────────────────────────────────┐
│ Your Assigned Courses                    │
├─────────────────────────────────────────┤
│ ☐ Course Name (CODE-101)        [Status]│
│ [Create Session Button]                 │
│                                         │
│ ☐ Another Course (CODE-202)     [Status]│
│ [Create Session Button]                 │
└─────────────────────────────────────────┘
```

## Future Enhancements

- Add date/time picker for creating sessions in the future
- Show session details in course cards
- Quick filters (active courses, completed courses, etc.)
- Bulk session creation
- Session templates
- Copy attendance code to clipboard

## Known Limitations

- Sessions are loaded from the API each time
- No caching of course data
- UI refreshes entire course list after creating session

## Files Modified

- `lib/screens/teacher_screen.dart` - Added course loading and UI
- `lib/services/api_service.dart` - Uses existing endpoints

## Backend Requirements

The following backend routes must be working:
- `GET /teacher/sessions/{teacher_id}` - Returns list of sessions
- `POST /teacher/sessions` - Creates new session

Both routes are already implemented in:
- `app_backend/routes/teacher/sessions.py`

## Support

If courses don't appear:
1. Verify the teacher is assigned to courses in the admin panel
2. Check that the backend is running
3. Check API base URL is correct in `lib/config/api_config.dart`
4. Check console logs for error messages

---

**Last Updated:** December 25, 2025
**Feature Status:** ✅ Complete and tested
