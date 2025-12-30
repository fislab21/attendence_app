# Attendance Expulsion & Warning System

**Status:** ✅ Complete with Warnings and Expulsion Logic

---

## What Is This System?

This system automatically:
1. **Tracks** student absences (justified and unjustified)
2. **Warns** students when approaching limits
3. **Expels** students when exceeding limits

---

## Limits & Thresholds

| Type | Warning Level | Expulsion Limit |
|------|---------------|-----------------|
| **Unjustified Absences** | 2 | 3 |
| **Justified Absences** | 4 | 5 |

**Explanation:**
- When student reaches **2 unjustified absences** → Warning issued
- When student reaches **3 unjustified absences** → Expelled
- When student reaches **4 justified absences** → Warning issued
- When student reaches **5 justified absences** → Expelled

---

## How It Works

### File Structure

```
backend/
├── config.php                 - Main connection + helper functions
├── attendance_check.php      - NEW! Expulsion & warning logic
├── attendance.php            - Updated with new actions
└── ...other files
```

---

## Functions in attendance_check.php

### 1. getStudentAttendanceStats()

Get student's attendance counts.

```php
$stats = getStudentAttendanceStats($student_id, $course_id);

// Returns:
// [
//   'present_count' => 8,
//   'unjustified_absent' => 1,
//   'justified_absent' => 2,
//   'total_sessions' => 11
// ]
```

---

### 2. isStudentExpelled()

Check if student should be expelled.

```php
$result = isStudentExpelled($student_id, $course_id);

// If expelled:
// [
//   'expelled' => true,
//   'reason' => 'Exceeded unjustified absences limit',
//   'unjustified_count' => 3,
//   'limit' => 3
// ]

// If not expelled:
// ['expelled' => false]
```

---

### 3. getStudentWarningStatus()

Get all warnings for a student.

```php
$warnings = getStudentWarningStatus($student_id, $course_id);

// Returns array:
// [
//   [
//     'type' => 'unjustified_absence_warning',
//     'message' => 'Warning: You have 2 unjustified absences. Limit is 3.',
//     'current' => 2,
//     'limit' => 3,
//     'remaining' => 1
//   ]
// ]
```

---

### 4. checkStudentStatus()

Get complete student status (normal, warning, or expelled).

```php
$status = checkStudentStatus($student_id, $course_id);

// Response 1 - Normal:
// [
//   'status' => 'normal',
//   'stats' => {...stats...}
// ]

// Response 2 - Warning:
// [
//   'status' => 'warning',
//   'warnings' => [{...warning info...}]
// ]

// Response 3 - Expelled:
// [
//   'status' => 'expelled',
//   'reason' => 'Exceeded unjustified absences limit',
//   'details' => {...details...}
// ]
```

---

### 5. getExpelledStudents()

Get all expelled students.

```php
$expelled = getExpelledStudents($course_id);

// Returns array of expelled students with reasons
```

---

### 6. getAttendanceReportWithStatus()

Get course report with each student's status.

```php
$report = getAttendanceReportWithStatus($course_id);

// Returns all students with:
// - Attendance counts
// - Current status (normal/warning/expelled)
// - Warning messages (if any)
// - Expulsion details (if expelled)
```

---

## API Endpoints

### Check Student Status

**URL:** `http://localhost:8000/attendance.php?action=check_status&student_id=2&course_id=1`

**Response (Warning):**
```json
{
  "success": true,
  "message": "Student status retrieved",
  "data": {
    "status": "warning",
    "warnings": [
      {
        "type": "unjustified_absence_warning",
        "message": "Warning: You have 2 unjustified absences. Limit is 3.",
        "current": 2,
        "limit": 3,
        "remaining": 1
      }
    ]
  }
}
```

---

### Get Expelled Students

**URL:** `http://localhost:8000/attendance.php?action=get_expelled&course_id=1`

**Response:**
```json
{
  "success": true,
  "message": "Expelled students retrieved",
  "data": [
    {
      "user_id": 3,
      "first_name": "Ahmed",
      "last_name": "Ali",
      "email": "ahmed@example.com",
      "expulsion_reason": "Exceeded unjustified absences limit",
      "expulsion_details": {
        "expelled": true,
        "reason": "Exceeded unjustified absences limit",
        "unjustified_count": 3,
        "limit": 3
      }
    }
  ]
}
```

---

### Get Course Report with Status

**URL:** `http://localhost:8000/attendance.php?action=get_report&course_id=1`

**Response:**
```json
{
  "success": true,
  "message": "Attendance report with status retrieved",
  "data": [
    {
      "user_id": 2,
      "first_name": "Ahmed",
      "last_name": "Ali",
      "present_count": 8,
      "unjustified_absent": 2,
      "justified_absent": 0,
      "total_sessions": 10,
      "attendance_status": "warning",
      "warnings": [
        {
          "type": "unjustified_absence_warning",
          "message": "Warning: You have 2 unjustified absences. Limit is 3.",
          "current": 2,
          "limit": 3,
          "remaining": 1
        }
      ]
    },
    {
      "user_id": 3,
      "first_name": "Fatima",
      "last_name": "Ben",
      "present_count": 10,
      "unjustified_absent": 3,
      "justified_absent": 0,
      "total_sessions": 13,
      "attendance_status": "expelled",
      "expulsion_details": {
        "expelled": true,
        "reason": "Exceeded unjustified absences limit",
        "unjustified_count": 3,
        "limit": 3
      }
    }
  ]
}
```

---

### Update Attendance (with Auto-Check)

**URL:** `http://localhost:8000/attendance.php?action=update_attendance`

**Body:**
```json
{
  "session_id": 1,
  "student_id": 2,
  "status": "absent",
  "justified": 0,
  "course_id": 1
}
```

**Response (Normal):**
```json
{
  "success": true,
  "message": "Attendance updated successfully",
  "data": {
    "status": "absent",
    "student_status": {
      "status": "normal",
      "stats": {...}
    }
  }
}
```

**Response (Warning Triggered):**
```json
{
  "success": true,
  "warning": "Attendance updated. Student has warnings",
  "data": {
    "status": "warning",
    "warnings": [{...warning...}]
  }
}
```

**Response (Expulsion Triggered):**
```json
{
  "success": false,
  "error": "Student has been EXPELLED: Exceeded unjustified absences limit"
}
```

---

## Testing with cURL

### Test 1: Check student with warning

```bash
curl http://localhost:8000/attendance.php?action=check_status&student_id=2&course_id=1
```

---

### Test 2: Get all expelled students

```bash
curl http://localhost:8000/attendance.php?action=get_expelled&course_id=1
```

---

### Test 3: Get course report with status

```bash
curl http://localhost:8000/attendance.php?action=get_report&course_id=1
```

---

### Test 4: Mark attendance (with auto-expulsion check)

```bash
curl -X POST http://localhost:8000/attendance.php?action=update_attendance \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": 1,
    "student_id": 2,
    "status": "absent",
    "justified": 0,
    "course_id": 1
  }'
```

---

## Example Scenarios

### Scenario 1: Student Gets Warning

**Initial State:**
- Student has 1 unjustified absence

**Action:**
- Mark 1 more unjustified absence

**Result:**
- Student now has 2 unjustified absences
- System detects >= 2 (WARNING_LEVEL)
- **Response:** Warning issued with message: "You have 2 unjustified absences. Limit is 3. (1 remaining)"

---

### Scenario 2: Student Gets Expelled

**Initial State:**
- Student has 2 unjustified absences

**Action:**
- Mark 1 more unjustified absence

**Result:**
- Student now has 3 unjustified absences
- System detects >= 3 (EXPULSION_LIMIT)
- **Response:** Error - Student EXPELLED
- Student removed from course

---

## Configuration

To change limits, edit `attendance_check.php` line 9-12:

```php
define('UNJUSTIFIED_ABSENCE_LIMIT', 3);      // Change this
define('JUSTIFIED_ABSENCE_LIMIT', 5);        // Or this
define('UNJUSTIFIED_WARNING_LEVEL', 2);      // Or this
define('JUSTIFIED_WARNING_LEVEL', 4);        // Or this
```

---

## Summary

✅ **Automatic Warnings** - Issued before limits reached
✅ **Automatic Expulsion** - Applied when limits exceeded
✅ **Course-specific** - Can track per course or overall
✅ **Detailed Reports** - See student status at a glance
✅ **API Ready** - All functions accessible via HTTP
✅ **Easy Testing** - Use cURL to test any scenario
