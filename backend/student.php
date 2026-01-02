<?php
/**
 * STUDENT API
 * UC2: Enter Code - Student inputs code → validate format → check not expired → check no duplicate → mark present
 * UC3: View History - Student sees total sessions, justified/unjustified absences, warnings, exclusions
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
// UC2: ENTER ATTENDANCE CODE
// ===========================
if ($action === 'enter-code' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    validateRequired($data, ['student_id', 'code']);
    
    $student_id = sanitize($data['student_id']);
    $code_input = strtoupper(sanitize($data['code']));
    
    // VALIDATION: Check code format (6 alphanumeric)
    validateCodeFormat($code_input);
    
    // MAIN FLOW: Find session with this code
    $session = executeSelectOne("SELECT s.session_id, s.course_id, s.expiration_time, s.status 
                                FROM sessions s
                                WHERE UPPER(s.attendance_code) = '" . sanitize($code_input) . "'");
    
    // EXCEPTION: Invalid code
    if (!$session) {
        error('Invalid attendance code', 400);
    }
    
    // EXCEPTION: Session not active
    if ($session['status'] !== 'Active') {
        error('This attendance session is not currently active', 400);
    }
    
    // EXCEPTION: Code expired
    if (isCodeExpired($session['expiration_time'])) {
        error('This attendance code has expired', 400);
    }
    
    $session_id = $session['session_id'];
    $course_id = $session['course_id'];
    
    // VALIDATION: Check student is enrolled in this course
    if (!studentEnrolledInCourse($student_id, $course_id)) {
        error('You are not enrolled in this course', 403);
    }
    
    // EXCEPTION: Check if student already submitted for this session
    if (hasStudentAlreadySubmitted($student_id, $session_id)) {
        error('You have already marked attendance for this session', 400);
    }
    
    // EXCEPTION: Check if student is excluded from course
    if (isStudentExcluded($student_id, $course_id)) {
        error('You have been excluded from this course and cannot submit attendance', 403);
    }
    
    // MAIN FLOW: Mark attendance as present
    $record_id = generateId('AR');
    $sql = "INSERT INTO attendance_records (record_id, session_id, student_id, attendance_status, submission_time)
            VALUES (
                '" . sanitize($record_id) . "',
                '" . sanitize($session_id) . "',
                '" . sanitize($student_id) . "',
                'Present',
                NOW()
            )";
    
    executeInsertUpdateDelete($sql);
    
    // MAIN FLOW: Confirm success
    success('Attendance marked successfully', [
        'status' => 'Present',
        'session_id' => $session_id,
        'message' => 'Your attendance has been recorded'
    ]);
}

// ===========================
// UC3: VIEW ATTENDANCE HISTORY
// ===========================
else if ($action === 'history' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $student_id = isset($_GET['student_id']) ? sanitize($_GET['student_id']) : '';
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : null;
    
    // Validate student ID
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    // Build course filter
    $course_filter = '';
    if ($course_id) {
        $course_filter = "AND s.course_id = '" . sanitize($course_id) . "'";
    }
    
    // MAIN FLOW: Get attendance records
    $sql = "SELECT 
                ar.record_id,
                ar.attendance_status,
                ar.submission_time,
                s.session_id,
                s.course_id,
                c.course_name,
                c.course_code,
                s.start_time
            FROM attendance_records ar
            JOIN sessions s ON ar.session_id = s.session_id
            JOIN courses c ON s.course_id = c.course_id
            WHERE ar.student_id = '" . sanitize($student_id) . "' $course_filter
            ORDER BY s.start_time DESC";
    
    $attendance_records = executeSelect($sql);
    
    // Get stats (total sessions, absences, etc.)
    if ($course_id) {
        $stats = getStudentAttendanceStats($student_id, $course_id);
    } else {
        // Get overall stats (all courses)
        $stats_sql = "SELECT 
                        COUNT(*) as total_sessions,
                        SUM(CASE WHEN ar.attendance_status = 'Present' THEN 1 ELSE 0 END) as present,
                        SUM(CASE WHEN ar.attendance_status IN ('Absent', 'Unjustified') THEN 1 ELSE 0 END) as unjustified,
                        SUM(CASE WHEN ar.attendance_status = 'Justified' THEN 1 ELSE 0 END) as justified
                    FROM attendance_records ar
                    WHERE ar.student_id = '" . sanitize($student_id) . "'";
        
        $stats_result = executeSelectOne($stats_sql);
        $stats = [
            'total_sessions' => (int)($stats_result['total_sessions'] ?? 0),
            'present' => (int)($stats_result['present'] ?? 0),
            'unjustified_absences' => (int)($stats_result['unjustified'] ?? 0),
            'justified_absences' => (int)($stats_result['justified'] ?? 0),
        ];
    }
    
    // Get active warnings
    $warnings_sql = "SELECT w.warning_id, w.course_id, c.course_name, w.issue_date, w.warning_message
                    FROM warnings w
                    JOIN courses c ON w.course_id = c.course_id
                    WHERE w.student_id = '" . sanitize($student_id) . "' AND w.is_active = TRUE";
    
    $warnings = executeSelect($warnings_sql);
    
    // Get active exclusions
    $exclusions_sql = "SELECT e.exclusion_id, e.course_id, c.course_name, e.issue_date, e.exclusion_reason
                      FROM exclusions e
                      JOIN courses c ON e.course_id = c.course_id
                      WHERE e.student_id = '" . sanitize($student_id) . "' AND e.is_active = TRUE";
    
    $exclusions = executeSelect($exclusions_sql);
    
    // MAIN FLOW: Return history
    success('Attendance history retrieved', [
        'stats' => $stats,
        'attendance_records' => $attendance_records,
        'warnings' => $warnings,
        'exclusions' => $exclusions
    ]);
}

// ===========================
// UC8: VIEW PROFILE
// ===========================
else if ($action === 'profile' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $student_id = isset($_GET['student_id']) ? sanitize($_GET['student_id']) : '';
    
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    // Get student profile
    $sql = "SELECT u.user_id, u.username, u.email, u.full_name, u.user_type, u.account_status, u.created_at,
                   s.student_id
            FROM users u
            JOIN students s ON u.user_id = s.user_id
            WHERE s.student_id = '" . sanitize($student_id) . "'";
    
    $profile = executeSelectOne($sql);
    
    if (!$profile) {
        error('Student profile not found', 404);
    }
    
    success('Profile retrieved', $profile);
}

// ===========================
// UC8 ALTERNATIVE: UPDATE PROFILE
// ===========================
else if ($action === 'profile' && $_SERVER['REQUEST_METHOD'] === 'PUT') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    validateRequired($data, ['student_id']);
    
    $student_id = sanitize($data['student_id']);
    
    // Get user_id from student_id
    $student = executeSelectOne("SELECT user_id FROM students WHERE student_id = '" . sanitize($student_id) . "'");
    
    if (!$student) {
        error('Student not found', 404);
    }
    
    $user_id = $student['user_id'];
    
    // Update email if provided
    if (isset($data['email'])) {
        $email = sanitize($data['email']);
        validateEmail($email);
        
        // Check if email already exists for another user
        $existing = executeSelectOne("SELECT user_id FROM users WHERE email = '" . sanitize($email) . "' AND user_id != '" . sanitize($user_id) . "'");
        
        if ($existing) {
            error('This email is already in use', 400);
        }
        
        $sql_email = "UPDATE users SET email = '" . sanitize($email) . "' WHERE user_id = '" . sanitize($user_id) . "'";
        executeInsertUpdateDelete($sql_email);
    }
    
    // Update password if provided
    if (isset($data['password']) && isset($data['old_password'])) {
        // Verify old password first
        $user = executeSelectOne("SELECT password FROM users WHERE user_id = '" . sanitize($user_id) . "'");
        
        if ($user['password'] !== sanitize($data['old_password'])) {
            error('Current password is incorrect', 400);
        }
        
        $new_password = sanitize($data['password']);
        $sql_password = "UPDATE users SET password = '" . sanitize($new_password) . "' WHERE user_id = '" . sanitize($user_id) . "'";
        executeInsertUpdateDelete($sql_password);
    }
    
    success('Profile updated successfully', []);
}

// EXCEPTION: Invalid action
else {
    error('Invalid action. Use GET /student.php/history or POST /student.php/enter-code', 400);
}

?>

// ===========================
// UC2: ENTER ATTENDANCE CODE
// ===========================
if ($action === 'enter-code' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    validateRequired($data, ['student_id', 'code']);
    
    $student_id = sanitize($data['student_id']);
    $code_input = strtoupper(sanitize($data['code']));
    
    // VALIDATION: Check code format (6 alphanumeric)
    validateCodeFormat($code_input);
    
    // MAIN FLOW: Find session with this code
    $session = executeSelectOne("SELECT s.session_id, s.course_id, s.expiration_time, s.status 
                                FROM sessions s
                                WHERE UPPER(s.attendance_code) = '" . sanitize($code_input) . "'");
    
    // EXCEPTION: Invalid code
    if (!$session) {
        error('Invalid attendance code', 400);
    }
    
    // EXCEPTION: Session not active
    if ($session['status'] !== 'Active') {
        error('This attendance session is not currently active', 400);
    }
    
    // EXCEPTION: Code expired
    if (isCodeExpired($session['expiration_time'])) {
        error('This attendance code has expired', 400);
    }
    
    $session_id = $session['session_id'];
    $course_id = $session['course_id'];
    
    // VALIDATION: Check student is enrolled in this course
    if (!studentEnrolledInCourse($student_id, $course_id)) {
        error('You are not enrolled in this course', 403);
    }
    
    // EXCEPTION: Check if student already submitted for this session
    if (hasStudentAlreadySubmitted($student_id, $session_id)) {
        error('You have already marked attendance for this session', 400);
    }
    
    // EXCEPTION: Check if student is excluded from course
    if (isStudentExcluded($student_id, $course_id)) {
        error('You have been excluded from this course and cannot submit attendance', 403);
    }
    
    // MAIN FLOW: Mark attendance as present
    $record_id = generateId('AR');
    $sql = "INSERT INTO attendance_records (record_id, session_id, student_id, attendance_status, submission_time)
            VALUES (
                '" . sanitize($record_id) . "',
                '" . sanitize($session_id) . "',
                '" . sanitize($student_id) . "',
                'Present',
                NOW()
            )";
    
    executeInsertUpdateDelete($sql);
    
    // MAIN FLOW: Confirm success
    success('Attendance marked successfully', [
        'status' => 'Present',
        'session_id' => $session_id,
        'message' => 'Your attendance has been recorded'
    ]);
}

// ===========================
// UC3: VIEW ATTENDANCE HISTORY
// ===========================
else if ($action === 'history' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $student_id = isset($_GET['student_id']) ? sanitize($_GET['student_id']) : '';
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : null;
    
    // Validate student ID
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    // Build course filter
    $course_filter = '';
    if ($course_id) {
        $course_filter = "AND s.course_id = '" . sanitize($course_id) . "'";
    }
    
    // MAIN FLOW: Get attendance records
    $sql = "SELECT 
                ar.record_id,
                ar.attendance_status,
                ar.submission_time,
                s.session_id,
                s.course_id,
                c.course_name,
                c.course_code,
                s.start_time
            FROM attendance_records ar
            JOIN sessions s ON ar.session_id = s.session_id
            JOIN courses c ON s.course_id = c.course_id
            WHERE ar.student_id = '" . sanitize($student_id) . "' $course_filter
            ORDER BY s.start_time DESC";
    
    $attendance_records = executeSelect($sql);
    
    // Get stats (total sessions, absences, etc.)
    if ($course_id) {
        $stats = getStudentAttendanceStats($student_id, $course_id);
    } else {
        // Get overall stats (all courses)
        $stats_sql = "SELECT 
                        COUNT(*) as total_sessions,
                        SUM(CASE WHEN ar.attendance_status = 'Present' THEN 1 ELSE 0 END) as present,
                        SUM(CASE WHEN ar.attendance_status IN ('Absent', 'Unjustified') THEN 1 ELSE 0 END) as unjustified,
                        SUM(CASE WHEN ar.attendance_status = 'Justified' THEN 1 ELSE 0 END) as justified
                    FROM attendance_records ar
                    WHERE ar.student_id = '" . sanitize($student_id) . "'";
        
        $stats_result = executeSelectOne($stats_sql);
        $stats = [
            'total_sessions' => (int)($stats_result['total_sessions'] ?? 0),
            'present' => (int)($stats_result['present'] ?? 0),
            'unjustified_absences' => (int)($stats_result['unjustified'] ?? 0),
            'justified_absences' => (int)($stats_result['justified'] ?? 0),
        ];
    }
    
    // Get active warnings
    $warnings_sql = "SELECT w.warning_id, w.course_id, c.course_name, w.issue_date, w.warning_message
                    FROM warnings w
                    JOIN courses c ON w.course_id = c.course_id
                    WHERE w.student_id = '" . sanitize($student_id) . "' AND w.is_active = TRUE";
    
    $warnings = executeSelect($warnings_sql);
    
    // Get active exclusions
    $exclusions_sql = "SELECT e.exclusion_id, e.course_id, c.course_name, e.issue_date, e.exclusion_reason
                      FROM exclusions e
                      JOIN courses c ON e.course_id = c.course_id
                      WHERE e.student_id = '" . sanitize($student_id) . "' AND e.is_active = TRUE";
    
    $exclusions = executeSelect($exclusions_sql);
    
    // MAIN FLOW: Return history
    success('Attendance history retrieved', [
        'stats' => $stats,
        'attendance_records' => $attendance_records,
        'warnings' => $warnings,
        'exclusions' => $exclusions
    ]);
}

// ===========================
// UC8: VIEW PROFILE
// ===========================
else if ($action === 'profile' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    
    $student_id = isset($_GET['student_id']) ? sanitize($_GET['student_id']) : '';
    
    if (!$student_id) {
        error('Student ID is required', 400);
    }
    
    // Get student profile
    $sql = "SELECT u.user_id, u.username, u.email, u.full_name, u.user_type, u.account_status, u.created_at,
                   s.student_id
            FROM users u
            JOIN students s ON u.user_id = s.user_id
            WHERE s.student_id = '" . sanitize($student_id) . "'";
    
    $profile = executeSelectOne($sql);
    
    if (!$profile) {
        error('Student profile not found', 404);
    }
    
    success('Profile retrieved', $profile);
}

// ===========================
// UC8 ALTERNATIVE: UPDATE PROFILE
// ===========================
else if ($action === 'profile' && $_SERVER['REQUEST_METHOD'] === 'PUT') {
    
    $data = json_decode(file_get_contents("php://input"), true);
    validateRequired($data, ['student_id']);
    
    $student_id = sanitize($data['student_id']);
    
    // Get user_id from student_id
    $student = executeSelectOne("SELECT user_id FROM students WHERE student_id = '" . sanitize($student_id) . "'");
    
    if (!$student) {
        error('Student not found', 404);
    }
    
    $user_id = $student['user_id'];
    
    // Update email if provided
    if (isset($data['email'])) {
        $email = sanitize($data['email']);
        validateEmail($email);
        
        // Check if email already exists for another user
        $existing = executeSelectOne("SELECT user_id FROM users WHERE email = '" . sanitize($email) . "' AND user_id != '" . sanitize($user_id) . "'");
        
        if ($existing) {
            error('This email is already in use', 400);
        }
        
        $sql_email = "UPDATE users SET email = '" . sanitize($email) . "' WHERE user_id = '" . sanitize($user_id) . "'";
        executeInsertUpdateDelete($sql_email);
    }
    
    // Update password if provided
    if (isset($data['password']) && isset($data['old_password'])) {
        // Verify old password first
        $user = executeSelectOne("SELECT password FROM users WHERE user_id = '" . sanitize($user_id) . "'");
        
        if ($user['password'] !== sanitize($data['old_password'])) {
            error('Current password is incorrect', 400);
        }
        
        $new_password = sanitize($data['password']);
        $sql_password = "UPDATE users SET password = '" . sanitize($new_password) . "' WHERE user_id = '" . sanitize($user_id) . "'";
        executeInsertUpdateDelete($sql_password);
    }
    
    success('Profile updated successfully', []);
}

// EXCEPTION: Invalid action
else {
    error('Invalid action. Use GET /student.php/history or POST /student.php/enter-code', 400);
}

?>
