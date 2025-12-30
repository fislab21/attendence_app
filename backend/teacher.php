<?php
include 'config.php';

// Get action from URL
$action = isset($_GET['action']) ? $_GET['action'] : '';
$teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';

// GET TEACHER COURSES (from teacher_courses table)
if ($action == 'get_courses') {
    if (!$teacher_id) {
        error('Teacher ID is required', 400);
    }
    
    $sql = "SELECT c.course_id, c.course_name, c.course_code
            FROM courses c
            JOIN teacher_courses tc ON c.course_id = tc.course_id
            WHERE tc.teacher_id = '$teacher_id'
            ORDER BY c.course_name";
    
    $courses = executeSelect($sql);
    
    if (count($courses) > 0) {
        success('Courses retrieved', $courses);
    } else {
        warning('No courses assigned to this teacher', []);
    }
}

// GET TEACHER SESSIONS (all sessions for teacher's courses)
else if ($action == 'get_sessions') {
    if (!$teacher_id) {
        error('Teacher ID is required', 400);
    }
    
    $sql = "SELECT s.session_id, s.course_id, s.teacher_id, s.attendance_code, s.start_time, s.status, s.room, s.time_slot,
            c.course_code, c.course_name
            FROM sessions s
            JOIN courses c ON s.course_id = c.course_id
            WHERE s.teacher_id = '$teacher_id'
            ORDER BY s.start_time DESC";
    
    $sessions = executeSelect($sql);
    
    if (count($sessions) > 0) {
        success('Sessions retrieved', $sessions);
    } else {
        warning('No sessions found for this teacher', []);
    }
}

// GET STUDENTS IN A COURSE (for a specific session)
else if ($action == 'get_students') {
    $session_id = isset($_GET['session_id']) ? sanitize($_GET['session_id']) : '';
    
    if (!$session_id) {
        error('Session ID is required', 400);
    }
    
    // First get the course_id from the session
    $session_sql = "SELECT course_id FROM sessions WHERE session_id = '$session_id'";
    $session = executeSelectOne($session_sql);
    
    if (!$session) {
        error('Session not found', 404);
    }
    
    $course_id = $session['course_id'];
    
    // Get all students enrolled in this course
    $sql = "SELECT cs.student_id, u.user_id, u.full_name, u.email, s.total_absences, s.unjustified_absences, s.justified_absences
            FROM course_students cs
            JOIN students s ON cs.student_id = s.student_id
            JOIN users u ON s.user_id = u.user_id
            WHERE cs.course_id = '$course_id'
            ORDER BY u.full_name";
    
    $students = executeSelect($sql);
    
    if (count($students) > 0) {
        success('Students retrieved', $students);
    } else {
        warning('No students enrolled in this course', []);
    }
}

// START SESSION (set status to Active and code)
else if ($action == 'start_session') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['session_id', 'attendance_code']);
    
    $session_id = sanitize($data['session_id']);
    $code = sanitize($data['attendance_code']);
    
    // Update session to active with code
    $sql = "UPDATE sessions SET status = 'Active', attendance_code = '$code', start_time = NOW() 
            WHERE session_id = '$session_id'";
    
    $affected = executeInsertUpdateDelete($sql);
    
    if ($affected > 0) {
        success('Session started successfully', ['session_id' => $session_id, 'code' => $code]);
    } else {
        error('Failed to start session', 500);
    }
}

// CLOSE SESSION (set status to Completed)
else if ($action == 'close_session') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['session_id']);
    
    $session_id = sanitize($data['session_id']);
    
    $sql = "UPDATE sessions SET status = 'Completed' WHERE session_id = '$session_id'";
    
    $affected = executeInsertUpdateDelete($sql);
    
    if ($affected > 0) {
        success('Session closed successfully', ['session_id' => $session_id]);
    } else {
        error('Failed to close session', 500);
    }
} else {
    error('Invalid action', 400);
}

?>
