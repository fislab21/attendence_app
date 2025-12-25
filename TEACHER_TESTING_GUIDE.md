# Teacher Dashboard Feature - Testing Guide

## Quick Start Testing

### Prerequisites
- Backend running: `cd app_backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000`
- Flutter app running: `cd student_attendence_app_UI && flutter run`
- MySQL database running with test data

## Test Scenarios

### Test 1: View Assigned Courses (Basic)

**Goal:** Verify teacher can see assigned courses on dashboard

**Steps:**
1. Open the app
2. Log in as a teacher (username: `teacher1`, password: your test password)
3. Navigate to Teacher Dashboard

**Expected Results:**
- ✅ "Your Assigned Courses" section appears
- ✅ Each assigned course displays:
  - Course name
  - Course code
  - Status badge (SCHEDULED)
  - Create Session button
- ✅ If no courses assigned: "No courses assigned yet" message

**Evidence:**
- Screenshot showing course cards
- Verify course names match admin assignments

---

### Test 2: Create Session from Course (Core Feature)

**Goal:** Verify teacher can create a session with one click

**Prerequisites:**
- Test 1 passed
- At least one course is assigned to the teacher

**Steps:**
1. View the Assigned Courses section
2. Click "Create Session" button on any course
3. Observe the screen

**Expected Results:**
- ✅ Success message appears: "Session created successfully!"
- ✅ New session appears in "Today's Sessions" section
- ✅ New session shows:
  - Course name
  - Course code
  - SCHEDULED status
  - Start, View Attendance, Close buttons

**Evidence:**
- Screenshot showing success message
- Screenshot showing new session in Today's Sessions

---

### Test 3: Multiple Courses

**Goal:** Verify teacher with multiple courses can manage each separately

**Prerequisites:**
- Teacher assigned to at least 3 courses

**Steps:**
1. View Assigned Courses section
2. Verify all 3 courses are displayed
3. Create session for course 1
4. Verify in Today's Sessions
5. Create session for course 2
6. Verify both sessions in Today's Sessions
7. Create session for course 3
8. Verify all 3 sessions in Today's Sessions

**Expected Results:**
- ✅ All courses visible in Assigned Courses
- ✅ Each course card is independent
- ✅ Each Create Session button works
- ✅ All 3 sessions appear in Today's Sessions
- ✅ Each session has unique course information

**Evidence:**
- Screenshot showing multiple course cards
- Screenshot showing all created sessions

---

### Test 4: Start Session After Creation

**Goal:** Verify created session can be started

**Prerequisites:**
- Test 2 passed (session created)

**Steps:**
1. In Today's Sessions, locate the newly created session
2. Click "Start Session" button
3. Verify the dialog that appears

**Expected Results:**
- ✅ Session status changes to ACTIVE (green badge)
- ✅ Dialog appears with:
  - "Session Started" title
  - Attendance code (6 characters, uppercase letters/numbers)
  - Expiration time (2 hours from now)
  - "Close" and "Copy Code" buttons
- ✅ Dialog shows the code prominently

**Evidence:**
- Screenshot of Session Started dialog
- Screenshot showing ACTIVE status badge

---

### Test 5: Student Marks Attendance with Code

**Goal:** Verify students can use the generated code to mark attendance

**Prerequisites:**
- Test 4 passed (session started with attendance code)
- A student user exists and is enrolled in the course

**Steps:**
1. Note the attendance code from Test 4
2. Open another instance of the app or another device
3. Log in as a student
4. Navigate to Student Dashboard
5. Enter the attendance code
6. Click "Mark Attendance"

**Expected Results:**
- ✅ Success message: "Attendance recorded successfully!"
- ✅ Student's session count increases
- ✅ Attendance appears in attendance records
- ✅ Database shows the attendance record

**Evidence:**
- Screenshot of success message
- Screenshot of updated attendance records
- Database query showing attendance_records entry

---

### Test 6: Close Session

**Goal:** Verify teacher can close a session

**Prerequisites:**
- Session is active from Test 4

**Steps:**
1. Click the close button (X) on the active session
2. Confirm the dialog
3. Verify session is closed

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ Warning message shown
- ✅ Session status changes to COMPLETED (gray badge)
- ✅ Code is no longer valid
- ✅ Students cannot mark attendance anymore

**Evidence:**
- Screenshot showing confirmation dialog
- Screenshot showing COMPLETED status
- Attempt to mark attendance with old code (should fail)

---

### Test 7: View Attendance List

**Goal:** Verify teacher can see who marked attendance

**Prerequisites:**
- Session has at least one student who marked attendance (from Test 5)

**Steps:**
1. Click "View Attendance" on a session
2. Verify the attendance list screen

**Expected Results:**
- ✅ Attendance List screen opens
- ✅ Shows session information (course name, code)
- ✅ Shows summary (Present count, Absent count)
- ✅ Shows student list with:
  - Student name
  - Email
  - Status (Present/Absent)
- ✅ Student who marked attendance shows as Present

**Evidence:**
- Screenshot of attendance list
- Verify student names and status match

---

### Test 8: Refresh/Reload Courses

**Goal:** Verify courses reload correctly on app restart

**Prerequisites:**
- Sessions created from Tests 1-3

**Steps:**
1. Note the courses visible
2. Close the app completely
3. Reopen the app
4. Log in as teacher
5. Navigate to Teacher Dashboard

**Expected Results:**
- ✅ All previous courses still visible in Assigned Courses
- ✅ All previous sessions still visible in Today's Sessions
- ✅ Data persisted correctly

**Evidence:**
- Screenshot after reload showing same data

---

### Test 9: Error Handling - API Failure

**Goal:** Verify graceful handling when API is down

**Prerequisites:**
- Backend is stopped

**Steps:**
1. Stop the backend server
2. Open/reload the app
3. Log in as teacher
4. Navigate to Teacher Dashboard

**Expected Results:**
- ✅ App loads without crashing
- ✅ No courses displayed (or empty message)
- ✅ Error is logged to console
- ✅ No error dialog shown to user

**Evidence:**
- App doesn't crash
- Console shows error message

---

### Test 10: Performance - Load Time

**Goal:** Verify dashboard loads in reasonable time

**Prerequisites:**
- Teacher assigned to 10+ courses

**Steps:**
1. Log in as teacher with many courses
2. Navigate to Teacher Dashboard
3. Time how long courses take to load
4. Note UI responsiveness

**Expected Results:**
- ✅ Dashboard loads within 2 seconds
- ✅ Course list is usable immediately after load
- ✅ No stuttering or lag when scrolling
- ✅ Buttons are responsive

**Evidence:**
- Stopwatch measurement
- Screen recording showing smooth interaction

---

## Integration Tests

### Test 11: Full Workflow

**Goal:** Complete end-to-end workflow

**Steps:**
1. Admin creates a course
2. Admin assigns course to teacher
3. Teacher logs in
4. Teacher sees course in Assigned Courses
5. Teacher creates session
6. Session appears in Today's Sessions
7. Teacher starts session
8. Teacher gets attendance code
9. Student logs in
10. Student marks attendance with code
11. Teacher views attendance list
12. Attendance record shows student as present
13. Teacher closes session
14. Session shows as completed

**Expected Results:**
- ✅ All steps complete without errors
- ✅ Data correctly flows through system
- ✅ Final state matches expectations

**Evidence:**
- Complete screenshot sequence
- Database verification of final state

---

## UI/UX Tests

### Test 12: Layout & Design

**Goal:** Verify UI looks good and is usable

**Checks:**
- ✅ Course cards are clearly visible
- ✅ Buttons are easy to find and click
- ✅ Text is readable
- ✅ Colors are appropriate
- ✅ Icons make sense
- ✅ Spacing is consistent
- ✅ No overlapping elements
- ✅ Works on different screen sizes

**Evidence:**
- Screenshots from different devices
- Mobile and desktop views

---

### Test 13: Messages & Feedback

**Goal:** Verify user gets appropriate feedback

**Scenarios:**
1. Create session → Success message
2. Create session fails → Error message with reason
3. Close session → Confirmation required
4. No courses → Helpful message shown
5. Long operation → Clear what's happening

**Expected Results:**
- ✅ Messages are clear and helpful
- ✅ Errors explain what went wrong
- ✅ Success confirmed visually
- ✅ All messages are appropriate

**Evidence:**
- Screenshots of each message type

---

## Regression Tests

### Test 14: Existing Features Still Work

**Goal:** Verify new feature doesn't break existing functionality

**Test:**
1. Student marking attendance works ✅
2. Viewing attendance records works ✅
3. Session management works ✅
4. Admin functions work ✅
5. Login/logout works ✅

**Expected Results:**
- ✅ All existing features still work as before

---

## Test Summary Template

```markdown
## Test Results Summary

Date: [Test Date]
Tester: [Your Name]
Device: [Phone/Tablet/Desktop]
OS: [Android/iOS/Linux/Windows]

### Passed Tests
- [x] Test 1: View Assigned Courses
- [x] Test 2: Create Session
- [x] Test 3: Multiple Courses
- [x] Test 4: Start Session
- [x] Test 5: Student Marks Attendance
- [x] Test 6: Close Session
- [x] Test 7: View Attendance List
- [x] Test 8: Refresh Courses
- [x] Test 11: Full Workflow

### Failed Tests
- [ ] Test [X]: [Description]
  - Issue: [Describe issue]
  - Steps to reproduce: [Steps]
  - Expected: [Expected result]
  - Actual: [Actual result]

### Recommendations
- [List any improvements needed]

### Overall Status
✅ READY FOR PRODUCTION / ⚠️ NEEDS FIXES / ❌ CRITICAL ISSUES
```

---

## Quick Checklist

```
TEACHER DASHBOARD FEATURE - TESTING CHECKLIST

Setup
□ Backend running on correct port
□ Database has test data
□ API URL correct in config
□ Flutter app compiles without errors

Basic Functionality
□ Teacher can log in
□ Assigned Courses section visible
□ Create Session button works
□ Success message shown
□ Session appears in Today's Sessions

Advanced Functionality
□ Multiple sessions can be created
□ Each session has unique code
□ Students can mark attendance
□ Attendance list shows correct data
□ Closing session works

Error Handling
□ No courses → shows message
□ API down → graceful failure
□ Network error → shows error
□ Invalid data → handled

Performance
□ Load time < 2 seconds
□ No UI freezing
□ Smooth scrolling
□ Responsive buttons

UI/UX
□ Design looks good
□ Text readable
□ Icons clear
□ Layout consistent
□ Mobile friendly

Data Integrity
□ Data persists on reload
□ Database records created
□ Attendance recorded correctly
□ No duplicate sessions
□ No data loss

Regression
□ Student features work
□ Admin features work
□ Login/logout work
□ Other screens work
```

---

**Testing Guide Status:** ✅ Complete
**Last Updated:** December 25, 2025
