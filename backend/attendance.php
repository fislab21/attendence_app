<?php
include 'config.php';
include 'attendance_check.php';  // Include attendance checking system

// Get action from URL
$action = isset($_GET['action']) ? $_GET['action'] : '';

// GET ATTENDANCE FOR A SESSION
if ($action == 'get_session_attendance') {
    $session_id = isset($_GET['session_id']) ? sanitize($_GET['session_id']) : '';
    
    if (!$session_id) {
        error('Session ID is required', 400);
    }
    
    $sql = "SELECT a.attendance_id, a.student_id, u.first_name, u.last_name, 
            a.status, a.justified, a.marked_at
            FROM attendance a
            JOIN users u ON a.student_id = u.user_id
            WHERE a.session_id = '$session_id'";
    
    $attendance = executeSelect($sql);
    
    if (count($attendance) > 0) {
        success('Session attendance retrieved', $attendance);
    } else {
        warning('No attendance records for this session', []);
    }
}

// GET ATTENDANCE REPORT FOR A COURSE
else if ($action == 'get_report') {
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : '';
    
    if (!$course_id) {
        error('Course ID is required', 400);
    }
    
    // Get report with status and warnings
    $report = getAttendanceReportWithStatus($course_id);
    
    if (count($report) > 0) {
        success('Attendance report with status retrieved', $report);
    } else {
        warning('No students in this course', []);
    }
}

// CHECK STUDENT STATUS (Normal, Warning, or Expelled)
else if ($action == 'check_status') {
    $student_id = isset($_GET['student_id']) ? sanitize($_GET['student_id']) : '';
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : null;
    
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    $status = checkStudentStatus($student_id, $course_id);
    
    success('Student status retrieved', $status);
}

// GET EXPELLED STUDENTS
else if ($action == 'get_expelled') {
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : null;
    
    $expelled = getExpelledStudents($course_id);
    
    if (count($expelled) > 0) {
        success('Expelled students retrieved', $expelled);
    } else {
        warning('No expelled students found', []);
    }
}

// UPDATE ATTENDANCE
else if ($action == 'update_attendance') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['session_id', 'student_id', 'status']);
    
    $session_id = sanitize($data['session_id']);
    $student_id = sanitize($data['student_id']);
    $status = sanitize($data['status']);
    $justified = isset($data['justified']) ? sanitize($data['justified']) : 0;
    $course_id = isset($data['course_id']) ? sanitize($data['course_id']) : null;
    
    // Validate status
    $valid_status = ['present', 'absent'];
    if (!in_array($status, $valid_status)) {
        error('Invalid attendance status. Must be "present" or "absent"', 400);
    }
    
    // Check if student is already expelled
    $expulsion_check = isStudentExpelled($student_id, $course_id);
    if ($expulsion_check['expelled']) {
        error('Student is expelled: ' . $expulsion_check['reason'], 403);
    }
    
    // Update attendance
    $sql = "INSERT INTO attendance (session_id, student_id, status, justified, marked_at)
            VALUES ('$session_id', '$student_id', '$status', '$justified', NOW())
            ON DUPLICATE KEY UPDATE status = '$status', justified = '$justified'";
    
    executeInsertUpdateDelete($sql);
    
    // Check if this update triggers expulsion or warning
    $student_status = checkStudentStatus($student_id, $course_id);
    
    if ($student_status['status'] === 'expelled') {
        // Update expulsion status
        updateStudentExpulsionStatus($student_id, $course_id);
        
        error('Student has been EXPELLED: ' . $student_status['reason'], 403);
    } else if ($student_status['status'] === 'warning') {
        // Send warning
        warning('Attendance updated. Student has warnings', $student_status);
    } else {
        // Normal update
        success('Attendance updated successfully', [
            'status' => $status,
            'student_status' => $student_status
        ]);
    }
}

// MARK ATTENDANCE BY CODE (STUDENT VERSION)
else if ($action == 'mark_by_code') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['code', 'student_id']);
    
    $code = strtoupper(sanitize($data['code']));
    $student_id = sanitize($data['student_id']);
    
    // Find the session with this code
    $sql = "SELECT session_id, course_id, status 
            FROM sessions 
            WHERE UPPER(code) = '$code' AND status = 'active'";
    
    $sessions = executeSelect($sql);
    
    if (count($sessions) === 0) {
        error('Invalid or expired attendance code', 400);
    }
    
    $session = $sessions[0];
    $session_id = $session['session_id'];
    $course_id = $session['course_id'];
    
    // Check if student is enrolled in this course
    $enrollment_sql = "SELECT enrollment_id FROM enrollments 
                       WHERE student_id = '$student_id' AND course_id = '$course_id'";
    
    $enrollment = executeSelect($enrollment_sql);
    
    if (count($enrollment) === 0) {
        error('Student is not enrolled in this course', 403);
    }
    
    // Check if student is expelled
    $expulsion_check = isStudentExpelled($student_id, $course_id);
    if ($expulsion_check['expelled']) {
        error('Student is expelled: ' . $expulsion_check['reason'], 403);
    }
    
    // Mark attendance as present
    $status = 'present';
    $justified = 0;
    $insert_sql = "INSERT INTO attendance (session_id, student_id, status, justified, marked_at)
                   VALUES ('$session_id', '$student_id', '$status', '$justified', NOW())
                   ON DUPLICATE KEY UPDATE status = '$status', justified = '$justified'";
    
    executeInsertUpdateDelete($insert_sql);
    
    // Check if this triggers any warnings
    $student_status = checkStudentStatus($student_id, $course_id);
    
    if ($student_status['status'] === 'expelled') {
        // Update expulsion status
        updateStudentExpulsionStatus($student_id, $course_id);
        error('Attendance marked, but student has been EXPELLED: ' . $student_status['reason'], 403);
    } else if ($student_status['status'] === 'warning') {
        // Send warning
        warning('Attendance marked. WARNING: Student has warnings', [
            'status' => $status,
            'warnings' => $student_status
        ]);
    } else {
        // Normal success
        success('Attendance marked successfully', [
            'session_id' => $session_id,
            'status' => $status,
            'message' => 'Your attendance has been recorded'
        ]);
    }
} else {
    error('Invalid action', 400);
}

?>
