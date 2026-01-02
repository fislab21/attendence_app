<?php
/**
 * TEACHER API
 * UC4: Generate Session - Teacher selects course → creates session → generate unique code → set expiration
 * UC5: Mark Absence - Teacher views non-submitters → mark justified/unjustified → auto-trigger warning/exclusion
 * UC6: Update History - Find student+session → change status → recalculate → reapply/remove warnings/exclusions
 * UC7: View Records - See assigned courses, sessions, attendance stats, warnings, exclusions. Filter & export
 */

include 'config.php';

// Handle OPTIONS request for CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Get action from URL path
$request_uri = trim($_SERVER['PATH_INFO'] ?? '', '/');
$parts = explode('/', $request_uri);
$action = $parts[0] ?? '';
$resource_id = $parts[1] ?? '';

// ===========================
// UC4: GENERATE ATTENDANCE SESSION
// ===========================
if ($action === 'generate-session' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Accept either teacher_id or user_id
    if (!isset($data['teacher_id']) && !isset($data['user_id'])) {
        error('teacher_id or user_id is required', 400);
    }
    
    if (!isset($data['course_id'])) {
        error('course_id is required', 400);
    }
    
    $course_id = sanitize($data['course_id']);
    $duration_minutes = isset($data['duration_minutes']) ? (int)$data['duration_minutes'] : 15;
    $room = isset($data['room']) ? sanitize($data['room']) : 'TBD';
    $teacher_id = null;
    
    // If user_id is provided, get teacher_id from it
    if (isset($data['user_id'])) {
        $user_id = sanitize($data['user_id']);
        $teacher = executeSelectOne("SELECT teacher_id FROM teachers WHERE user_id = '$user_id'");
        if (!$teacher) {
            error('User is not a teacher', 400);
        }
        $teacher_id = $teacher['teacher_id'];
    } else {
        $teacher_id = sanitize($data['teacher_id']);
    }
    
    // VALIDATION: Check teacher teaches this course
    if (!teacherTeachesCourse($teacher_id, $course_id)) {
        error('You are not assigned to teach this course', 403);
    }
    
    // MAIN FLOW: Generate unique code
    $code = generateAttendanceCode();
    
    // Calculate expiration time
    $expiration_time = date('Y-m-d H:i:s', time() + ($duration_minutes * 60));
    
    // Create session
    $session_id = generateId('SES');
    $sql = "INSERT INTO sessions (session_id, course_id, teacher_id, attendance_code, start_time, expiration_time, status, room)
            VALUES (
                '" . sanitize($session_id) . "',
                '" . sanitize($course_id) . "',
                '" . sanitize($teacher_id) . "',
                '" . sanitize($code) . "',
                NOW(),
                '" . sanitize($expiration_time) . "',
                'Active',
                '" . sanitize($room) . "'
            )";
    
    executeInsertUpdateDelete($sql);
    
    // MAIN FLOW: Return code and session info
    success('Session generated successfully', [
        'session_id' => $session_id,
        'code' => $code,
        'expiration_time' => $expiration_time,
        'duration_minutes' => $duration_minutes,
        'message' => 'Share code with students. It will expire in ' . $duration_minutes . ' minutes.'
    ]);
}

// ===========================
// UC5: MARK STUDENT ABSENCE
// ===========================
else if ($action === 'mark-absence' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    validateRequired($data, ['teacher_id', 'session_id', 'student_id', 'absence_type']);
    
    $teacher_id = sanitize($data['teacher_id']);
    $session_id = sanitize($data['session_id']);
    $student_id = sanitize($data['student_id']);
    $absence_type = sanitize($data['absence_type']); // 'Justified' or 'Unjustified'
    
    // VALIDATION: Check absence_type is valid
    if (!in_array($absence_type, ['Justified', 'Unjustified'])) {
        error('Absence type must be "Justified" or "Unjustified"', 400);
    }
    
    // Get session and verify teacher authorization
    $session = executeSelectOne("SELECT session_id, course_id FROM sessions WHERE session_id = '" . sanitize($session_id) . "'");
    
    if (!$session) {
        error('Session not found', 404);
    }
    
    // VALIDATION: Check teacher teaches this course
    if (!teacherTeachesCourse($teacher_id, $session['course_id'])) {
        error('You are not authorized to mark attendance for this session', 403);
    }
    
    $course_id = $session['course_id'];
    
    // EXCEPTION: Check if student is already marked present
    $existing = executeSelectOne("SELECT record_id, attendance_status FROM attendance_records 
                                 WHERE session_id = '" . sanitize($session_id) . "' 
                                 AND student_id = '" . sanitize($student_id) . "'");
    
    if ($existing && $existing['attendance_status'] === 'Present') {
        error('Student has already marked attendance for this session', 400);
    }
    
    // EXCEPTION: Check if student is excluded
    if (isStudentExcluded($student_id, $course_id)) {
        error('Cannot mark absent for excluded student', 403);
    }
    
    // MAIN FLOW: Mark absence
    $record_id = generateId('AR');
    $status = $absence_type === 'Justified' ? 'Justified' : 'Unjustified';
    
    if ($existing) {
        // Update existing record
        $sql = "UPDATE attendance_records SET attendance_status = '" . sanitize($status) . "', marked_by = '" . sanitize($teacher_id) . "', last_modified = NOW()
                WHERE session_id = '" . sanitize($session_id) . "' AND student_id = '" . sanitize($student_id) . "'";
    } else {
        // Create new record
        $sql = "INSERT INTO attendance_records (record_id, session_id, student_id, attendance_status, marked_by, last_modified)
                VALUES (
                    '" . sanitize($record_id) . "',
                    '" . sanitize($session_id) . "',
                    '" . sanitize($student_id) . "',
                    '" . sanitize($status) . "',
                    '" . sanitize($teacher_id) . "',
                    NOW()
                )";
    }
    
    executeInsertUpdateDelete($sql);
    
    // MAIN FLOW: Recalculate student status (check for warning/exclusion)
    $new_status = recalculateStudentStatus($student_id, $course_id);
    
    // EXCEPTION: If excluded, inform teacher
    if ($new_status === 'Excluded') {
        warning('Absence marked. Student has been automatically EXCLUDED from this course', [
            'status' => 'Excluded',
            'message' => 'Student has reached exclusion threshold'
        ]);
    } else if ($new_status === 'Warning') {
        warning('Absence marked. Student now has a WARNING', [
            'status' => 'Warning',
            'message' => 'Student has reached warning threshold'
        ]);
    } else {
        success('Absence marked successfully', [
            'status' => $new_status,
            'absence_type' => $absence_type
        ]);
    }
}

// ===========================
// UC6: UPDATE ATTENDANCE RECORD
// ===========================
else if ($action === 'update-attendance' && $_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    validateRequired($data, ['teacher_id', 'session_id', 'student_id', 'new_status']);
    
    $teacher_id = sanitize($data['teacher_id']);
    $session_id = sanitize($data['session_id']);
    $student_id = sanitize($data['student_id']);
    $new_status = sanitize($data['new_status']);
    
    // VALIDATION: Check new_status is valid
    $valid_statuses = ['Present', 'Absent', 'Justified', 'Unjustified'];
    if (!in_array($new_status, $valid_statuses)) {
        error('Invalid status. Must be one of: Present, Absent, Justified, Unjustified', 400);
    }
    
    // Get session
    $session = executeSelectOne("SELECT course_id FROM sessions WHERE session_id = '" . sanitize($session_id) . "'");
    
    if (!$session) {
        error('Session not found', 404);
    }
    
    $course_id = $session['course_id'];
    
    // VALIDATION: Check teacher authorization
    if (!teacherTeachesCourse($teacher_id, $course_id)) {
        error('You are not authorized to modify attendance for this session', 403);
    }
    
    // Get existing record
    $existing = executeSelectOne("SELECT record_id, attendance_status FROM attendance_records 
                                WHERE session_id = '" . sanitize($session_id) . "' 
                                AND student_id = '" . sanitize($student_id) . "'");
    
    if (!$existing) {
        error('Attendance record not found', 404);
    }
    
    // MAIN FLOW: Update attendance status
    $sql = "UPDATE attendance_records 
            SET attendance_status = '" . sanitize($new_status) . "', marked_by = '" . sanitize($teacher_id) . "', last_modified = NOW()
            WHERE session_id = '" . sanitize($session_id) . "' AND student_id = '" . sanitize($student_id) . "'";
    
    executeInsertUpdateDelete($sql);
    
    // MAIN FLOW: Recalculate student status
    $updated_status = recalculateStudentStatus($student_id, $course_id);
    
    // MAIN FLOW: Return result
    success('Attendance updated successfully', [
        'old_status' => $existing['attendance_status'],
        'new_status' => $new_status,
        'student_status' => $updated_status
    ]);
}

// ===========================
// UC7: VIEW RECORDS (Teacher)
// ===========================
else if ($action === 'records' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    $user_id = isset($_GET['user_id']) ? sanitize($_GET['user_id']) : '';
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : null;
    $date_from = isset($_GET['date_from']) ? sanitize($_GET['date_from']) : null;
    $date_to = isset($_GET['date_to']) ? sanitize($_GET['date_to']) : null;
    
    // If user_id is provided, get teacher_id from it
    if ($user_id && !$teacher_id) {
        $teacher = executeSelectOne("SELECT teacher_id FROM teachers WHERE user_id = '$user_id'");
        if (!$teacher) {
            error('User is not a teacher', 400);
        }
        $teacher_id = $teacher['teacher_id'];
    }
    
    if (!$teacher_id) {
        error('Teacher ID or User ID is required', 400);
    }
    
    // Build filters
    $where_clauses = ["tc.teacher_id = '" . sanitize($teacher_id) . "'"];
    
    if ($course_id) {
        $where_clauses[] = "s.course_id = '" . sanitize($course_id) . "'";
    }
    
    if ($date_from) {
        $where_clauses[] = "s.start_time >= '" . sanitize($date_from) . " 00:00:00'";
    }
    
    if ($date_to) {
        $where_clauses[] = "s.start_time <= '" . sanitize($date_to) . " 23:59:59'";
    }
    
    $where = implode(' AND ', $where_clauses);
    
    // Get sessions
    $sessions_sql = "SELECT s.session_id, s.course_id, c.course_name, c.course_code, 
                            s.attendance_code, s.start_time, s.expiration_time, s.status
                    FROM sessions s
                    JOIN courses c ON s.course_id = c.course_id
                    JOIN teacher_courses tc ON c.course_id = tc.course_id
                    WHERE $where
                    ORDER BY s.start_time DESC";
    
    $sessions = executeSelect($sessions_sql);
    
    $response_data = [];
    
    // For each session, get attendance details
    foreach ($sessions as $session) {
        $attendance_sql = "SELECT ar.record_id, ar.student_id, u.full_name, ar.attendance_status, ar.submission_time
                          FROM attendance_records ar
                          LEFT JOIN students st ON ar.student_id = st.student_id
                          LEFT JOIN users u ON st.user_id = u.user_id
                          WHERE ar.session_id = '" . sanitize($session['session_id']) . "'";
        
        $attendance = executeSelect($attendance_sql);
        
        $session['attendance'] = $attendance;
        $response_data[] = $session;
    }
    
    // Get warnings and exclusions for the teacher's courses
    $courses_filter = "";
    if ($course_id) {
        $courses_filter = "AND w.course_id = '" . sanitize($course_id) . "'";
    }
    
    $warnings_sql = "SELECT w.warning_id, w.student_id, u.full_name, w.course_id, c.course_name, w.issue_date
                    FROM warnings w
                    JOIN students s ON w.student_id = s.student_id
                    JOIN users u ON s.user_id = u.user_id
                    JOIN courses c ON w.course_id = c.course_id
                    WHERE w.is_active = TRUE $courses_filter";
    
    $exclusions_sql = "SELECT e.exclusion_id, e.student_id, u.full_name, e.course_id, c.course_name, e.issue_date
                      FROM exclusions e
                      JOIN students s ON e.student_id = s.student_id
                      JOIN users u ON s.user_id = u.user_id
                      JOIN courses c ON e.course_id = c.course_id
                      WHERE e.is_active = TRUE $courses_filter";
    
    $warnings = executeSelect($warnings_sql);
    $exclusions = executeSelect($exclusions_sql);
    
    success('Records retrieved', [
        'sessions' => $response_data,
        'warnings' => $warnings,
        'exclusions' => $exclusions,
        'count' => count($response_data)
    ]);
}

// UC7 ALTERNATIVE: Get assigned courses for teacher
else if ($action === 'courses' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    $user_id = isset($_GET['user_id']) ? sanitize($_GET['user_id']) : '';
    
    // If user_id is provided, get teacher_id from it
    if ($user_id && !$teacher_id) {
        $teacher = executeSelectOne("SELECT teacher_id FROM teachers WHERE user_id = '$user_id'");
        if (!$teacher) {
            error('User is not a teacher', 400);
        }
        $teacher_id = $teacher['teacher_id'];
    }
    
    if (!$teacher_id) {
        error('Teacher ID or User ID is required', 400);
    }
    
    $sql = "SELECT c.course_id, c.course_name, c.course_code, tc.assigned_at
            FROM courses c
            JOIN teacher_courses tc ON c.course_id = tc.course_id
            WHERE tc.teacher_id = '" . sanitize($teacher_id) . "'
            ORDER BY c.course_name";
    
    $courses = executeSelect($sql);
    
    success('Courses retrieved', $courses);
}

// UC7 ALTERNATIVE: Get session attendance (all students with their status)
else if ($action === 'session-attendance' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $session_id = isset($_GET['session_id']) ? sanitize($_GET['session_id']) : '';
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    $user_id = isset($_GET['user_id']) ? sanitize($_GET['user_id']) : '';
    
    if (!$session_id) {
        error('Session ID is required', 400);
    }
    
    // If user_id is provided, get teacher_id from it
    if ($user_id && !$teacher_id) {
        $teacher = executeSelectOne("SELECT teacher_id FROM teachers WHERE user_id = '$user_id'");
        if (!$teacher) {
            error('User is not a teacher', 400);
        }
        $teacher_id = $teacher['teacher_id'];
    }
    
    if (!$teacher_id) {
        error('Teacher ID or User ID is required', 400);
    }
    
    // Get course from session and verify teacher
    $session = executeSelectOne("SELECT course_id FROM sessions WHERE session_id = '" . sanitize($session_id) . "'");
    
    if (!$session) {
        error('Session not found', 404);
    }
    
    if (!teacherTeachesCourse($teacher_id, $session['course_id'])) {
        error('Not authorized', 403);
    }
    
    $course_id = $session['course_id'];
    
    // Get all enrolled students with their attendance status
    $sql = "SELECT cs.student_id, 
                   COALESCE(u.full_name, u.username) as name,
                   u.user_id,
                   COALESCE(ar.attendance_status, 'absent') as attendance_status,
                   ar.record_id,
                   ar.submission_time
            FROM course_students cs
            JOIN students s ON cs.student_id = s.student_id
            JOIN users u ON s.user_id = u.user_id
            LEFT JOIN attendance_records ar ON cs.student_id = ar.student_id AND ar.session_id = '" . sanitize($session_id) . "'
            WHERE cs.course_id = '" . sanitize($course_id) . "'
            ORDER BY u.full_name";
    
    $students = executeSelect($sql);
    
    success('Session attendance retrieved', $students);
}

// UC7 ALTERNATIVE: Get non-submitters for a session
else if ($action === 'non-submitters' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $session_id = isset($_GET['session_id']) ? sanitize($_GET['session_id']) : '';
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    $user_id = isset($_GET['user_id']) ? sanitize($_GET['user_id']) : '';
    
    if (!$session_id) {
        error('Session ID is required', 400);
    }
    
    // If user_id is provided, get teacher_id from it
    if ($user_id && !$teacher_id) {
        $teacher = executeSelectOne("SELECT teacher_id FROM teachers WHERE user_id = '$user_id'");
        if (!$teacher) {
            error('User is not a teacher', 400);
        }
        $teacher_id = $teacher['teacher_id'];
    }
    
    if (!$teacher_id) {
        error('Teacher ID or User ID is required', 400);
    }
    
    // Get course from session and verify teacher
    $session = executeSelectOne("SELECT course_id FROM sessions WHERE session_id = '" . sanitize($session_id) . "'");
    
    if (!$session) {
        error('Session not found', 404);
    }
    
    if (!teacherTeachesCourse($teacher_id, $session['course_id'])) {
        error('Not authorized', 403);
    }
    
    $course_id = $session['course_id'];
    
    // Get all enrolled students
    $sql = "SELECT cs.student_id, u.user_id, u.full_name, u.email
            FROM course_students cs
            JOIN students s ON cs.student_id = s.student_id
            JOIN users u ON s.user_id = u.user_id
            WHERE cs.course_id = '" . sanitize($course_id) . "'
            AND cs.student_id NOT IN (
                SELECT student_id FROM attendance_records 
                WHERE session_id = '" . sanitize($session_id) . "'
            )
            ORDER BY u.full_name";
    
    $non_submitters = executeSelect($sql);
    
    success('Non-submitters retrieved', $non_submitters);
}

// ===========================
// GET ACTIVE SESSIONS FOR TEACHER
// ===========================
else if ($action === 'active-sessions' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    $user_id = isset($_GET['user_id']) ? sanitize($_GET['user_id']) : '';
    
    if (!$teacher_id && !$user_id) {
        error('teacher_id or user_id is required', 400);
    }
    
    // If user_id is provided, get teacher_id from it
    if ($user_id && !$teacher_id) {
        $teacher = executeSelectOne("SELECT teacher_id FROM teachers WHERE user_id = '$user_id'");
        if (!$teacher) {
            error('User is not a teacher', 400);
        }
        $teacher_id = $teacher['teacher_id'];
    }
    
    $sql = "SELECT s.session_id, s.course_id, c.course_name, c.course_code, 
                   s.attendance_code, s.start_time, s.expiration_time, s.status, s.room
            FROM sessions s
            JOIN courses c ON s.course_id = c.course_id
            WHERE s.teacher_id = '" . sanitize($teacher_id) . "'
            AND s.status IN ('Active', 'Scheduled')
            ORDER BY s.start_time DESC";
    
    $sessions = executeSelect($sql);
    
    success('Active sessions retrieved', $sessions);
}

// ===========================
// CLOSE/COMPLETE SESSION
// ===========================
else if ($action === 'close-session' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['session_id']);
    
    $session_id = sanitize($data['session_id']);
    
    // Update session status to Completed
    executeInsertUpdateDelete("UPDATE sessions SET status = 'Completed' WHERE session_id = '$session_id'");
    
    success('Session closed successfully', ['session_id' => $session_id]);
}

// EXCEPTION: Invalid action
else {
    error('Invalid action. Use POST /teacher.php/generate-session or POST /teacher.php/mark-absence', 400);
}

?>
