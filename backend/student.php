<?php
include 'config.php';

// Get action from URL
$action = isset($_GET['action']) ? $_GET['action'] : '';
$student_id = isset($_GET['student_id']) ? sanitize($_GET['student_id']) : '';

// GET STUDENT COURSES
if ($action == 'get_courses') {
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    $sql = "SELECT c.course_id, c.course_code, c.course_name
            FROM courses c
            JOIN enrollments e ON c.course_id = e.course_id
            WHERE e.student_id = '$student_id'";
    
    $courses = executeSelect($sql);
    
    if (count($courses) > 0) {
        success('Courses retrieved', $courses);
    } else {
        warning('No courses enrolled', []);
    }
}

// GET STUDENT ATTENDANCE HISTORY
else if ($action == 'get_attendance') {
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    $sql = "SELECT a.attendance_id, a.status, a.justified, s.start_time, c.course_name
            FROM attendance a
            JOIN sessions s ON a.session_id = s.session_id
            JOIN courses c ON s.course_id = c.course_id
            WHERE a.student_id = '$student_id'";
    
    $attendance = executeSelect($sql);
    
    if (count($attendance) > 0) {
        success('Attendance history retrieved', $attendance);
    } else {
        warning('No attendance records found', []);
    }
}

// MARK ATTENDANCE
else if ($action == 'mark_attendance') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['session_id', 'student_id', 'status']);
    
    $session_id = sanitize($data['session_id']);
    $student_id = sanitize($data['student_id']);
    $status = sanitize($data['status']);
    $justified = isset($data['justified']) ? sanitize($data['justified']) : 0;
    
    // Check if status is valid
    $valid_status = ['present', 'absent'];
    if (!in_array($status, $valid_status)) {
        error('Invalid attendance status', 400);
    }
    
    // Insert attendance record
    $sql = "INSERT INTO attendance (session_id, student_id, status, justified, marked_at)
            VALUES ('$session_id', '$student_id', '$status', '$justified', NOW())
            ON DUPLICATE KEY UPDATE status = '$status', justified = '$justified'";
    
    executeInsertUpdateDelete($sql);
    
    success('Attendance marked successfully', ['status' => $status]);
} else {
    error('Invalid action', 400);
}

?>
