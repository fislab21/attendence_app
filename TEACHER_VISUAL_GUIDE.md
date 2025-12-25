# Teacher Dashboard Feature - Visual Guide

## UI Layout

```
┌──────────────────────────────────────────────────────┐
│  TEACHER DASHBOARD                          [Logout] │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Good Morning!                                       │
│  Here is an overview of your teaching day.          │
│                                                      │
│  ┌─────────────┐ ┌─────────────┐                    │
│  │👥 Present   │ │📋 Sessions  │                    │
│  │ 0/0         │ │ 0           │                    │
│  └─────────────┘ └─────────────┘                    │
│                                                      │
├──────────────────────────────────────────────────────┤
│  YOUR ASSIGNED COURSES         ← NEW FEATURE       │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🎓 Data Structures (CSC-201)       [SCHEDULED]│ │
│  │ [▶️  Create Session]                           │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🎓 Web Development (WEB-101)       [SCHEDULED]│ │
│  │ [▶️  Create Session]                           │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
├──────────────────────────────────────────────────────┤
│  TODAY'S SESSIONS                                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🎓 Data Structures • Room 101    [SCHEDULED]  │ │
│  │     10:00 AM                                   │ │
│  │ [▶️ Start] [👁️ View Attendance] [✕ Close]    │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🎓 Web Development • Room 205    [SCHEDULED]  │ │
│  │     2:00 PM                                    │ │
│  │ [▶️ Start] [👁️ View Attendance] [✕ Close]    │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## Feature Workflow

### Step 1: Admin Assigns Courses

```
ADMIN DASHBOARD
├── Assignments
├── Select Teacher
├── Select Courses
│   ├── Data Structures ✓
│   ├── Web Development ✓
│   └── Database Design
└── Save
```

### Step 2: Teacher Logs In

```
TEACHER LOGS IN
↓
initState() runs automatically
↓
Fetches all assigned courses
↓
Displays in "Your Assigned Courses" section
```

### Step 3: Teacher Creates Session

```
TEACHER DASHBOARD
│
Your Assigned Courses
├── Data Structures (CSC-201)
│   └── [Create Session] ← CLICK HERE
│       ↓
│       Creates session in backend
│       ↓
│       Shows success message
│       ↓
│       Reloads courses
│
Today's Sessions (updated automatically)
├── Data Structures (NEW SESSION)
│   └── [Start] [View Attendance] [Close]
```

### Step 4: Teacher Starts Session

```
CREATE SESSION → START SESSION → GENERATE CODE → SHARE WITH STUDENTS
                                      ↓
                              Attendance Code: ABC123
                              Valid until 12:00 PM
```

## States & Indicators

### Course Status Badges

```
┌──────────────┐
│  [SCHEDULED] │  Blue badge - Session can be created/started
└──────────────┘

┌────────────┐
│  [ACTIVE]  │  Green badge - Session is running
└────────────┘

┌──────────────┐
│  [COMPLETED] │ Gray badge - Session has ended
└──────────────┘
```

### Session States

```
SCHEDULED → START → ACTIVE → CLOSE → COMPLETED

Scheduled: Ready to start
Active:    Running, students can mark attendance
Completed: Closed, no more marking allowed
```

## User Actions

### From Course Card

```
Course Card
├── Course Name & Code (displayed)
├── Status Badge (displayed)
└── Create Session Button (clickable)
    ├── Success → Shows message, reloads
    └── Error → Shows error, allows retry
```

### From Session Card

```
Session Card (after creation)
├── Course Name & Details (displayed)
├── Status Badge (displayed)
├── Start Button
│   └── Opens dialog with attendance code
├── View Attendance Button
│   └── Shows list of students
└── Close Button
    └── Confirms and closes session
```

## Data Flow Diagram

```
┌─────────────────────────────────────┐
│     Teacher Logs In                 │
└──────────┬──────────────────────────┘
           │
           ↓
┌─────────────────────────────────────┐
│  initState() Triggered              │
│  ↓ _loadAssignedCourses()           │
└──────────┬──────────────────────────┘
           │
           ↓
┌─────────────────────────────────────┐
│  API: GET /teacher/sessions/{id}   │
│  ← Returns all sessions             │
└──────────┬──────────────────────────┘
           │
           ↓
┌─────────────────────────────────────┐
│  Extract Unique Courses             │
│  Create courseMap                   │
│  Deduplicate by course_id           │
└──────────┬──────────────────────────┘
           │
           ↓
┌─────────────────────────────────────┐
│  Build Assigned Courses UI          │
│  Display each course card           │
│  Show "Create Session" button       │
└──────────┬──────────────────────────┘
           │
    ┌──────┴──────┐
    ↓             ↓
WAIT         CLICK BUTTON
    │             │
    │             ↓
    │     ┌────────────────────────┐
    │     │ _createSession()       │
    │     │ ↓ POST /sessions       │
    │     │ ← Session created      │
    │     │ ↓ Show success         │
    │     │ ↓ Reload courses       │
    │     └────────┬───────────────┘
    │             │
    └──────┬──────┘
           ↓
┌─────────────────────────────────────┐
│  UI Updated                         │
│  • New session in Today's Sessions  │
│  • Course still visible above       │
│  • Can click "Start" on new session │
└─────────────────────────────────────┘
```

## Color Scheme

```
Assigned Courses Section:
┌─────────────┐
│  Blue Theme │  #1976D2 (primary blue)
│  Light Blue │  #E3F2FD (background)
│  Dark Gray  │  (text)
└─────────────┘

Today's Sessions Section:
┌─────────────┐
│  Green      │  Active sessions  (#4CAF50)
│  Blue       │  Scheduled        (#2196F3)
│  Gray       │  Completed        (#9E9E9E)
└─────────────┘

Buttons:
├── Blue button → Create Session, Start Session
├── Red button  → Close Session
└── Text link   → View Attendance
```

## Responsive Design

### Desktop View (Wide Screen)
```
┌──────────────────────────────────────┐
│ Assigned Courses | Today's Sessions  │
│ (2 columns)                          │
└──────────────────────────────────────┘
```

### Mobile View (Narrow Screen)
```
┌──────────────────────────────────────┐
│ Assigned Courses                     │
├──────────────────────────────────────┤
│ Today's Sessions                     │
├──────────────────────────────────────┤
(stacked vertically)
```

## Accessibility Features

- Clear icons (📚 for courses, 📋 for sessions)
- High contrast colors
- Large touch targets for buttons
- Clear text labels
- Error messages in red
- Success messages in green

## Performance Indicators

✅ Courses load on screen open (fast, cached in state)
✅ Session creation shows immediate feedback
✅ No loading spinner needed (quick API response)
✅ Smooth animations between states

## Error Scenarios

```
❌ No courses assigned
   ↓
   Display: "No courses assigned yet"

❌ API fails to load courses
   ↓
   Display: "Error loading courses" (printed to console)
   ↓
   User can navigate away and back to retry

❌ Session creation fails
   ↓
   Display: Red snackbar with error message
   ↓
   User can retry

❌ No courses returned (empty list)
   ↓
   Display: Empty state message
```

---

**Visual Guide Status:** ✅ Complete
**Last Updated:** December 25, 2025
