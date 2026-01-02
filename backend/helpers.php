<?php
/**
 * ATTENDANCE SYSTEM - HELPER FUNCTIONS
 * All utility functions for database operations, validation, and error handling
 */

global $conn;

// ===========================
// DATABASE QUERY HELPERS
// ===========================

/**
 * Execute SELECT query and return all rows
 */
function executeSelect($sql) {
    global $conn;
    $result = mysqli_query($conn, $sql);
    if (!$result) {
        error('Database error: ' . mysqli_error($conn), 500);
    }
    $rows = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $rows[] = $row;
    }
    return $rows;
}

/**
 * Execute SELECT query and return single row
 */
function executeSelectOne($sql) {
    $rows = executeSelect($sql);
    return count($rows) > 0 ? $rows[0] : null;
}

/**
 * Execute INSERT/UPDATE/DELETE and return affected rows
 */
function executeInsertUpdateDelete($sql) {
    global $conn;
    $result = mysqli_query($conn, $sql);
    if (!$result) {
        error('Database error: ' . mysqli_error($conn), 500);
    }
    return mysqli_affected_rows($conn);
}

/**
 * Execute INSERT and return insert ID
 */
function executeInsertGetId($sql) {
    global $conn;
    $result = mysqli_query($conn, $sql);
    if (!$result) {
        error('Database error: ' . mysqli_error($conn), 500);
    }
    return mysqli_insert_id($conn);
}

/**
 * Check if record exists
 */
function recordExists($table, $column, $value) {
    $sql = "SELECT 1 FROM $table WHERE $column = '" . sanitize($value) . "' LIMIT 1";
    return executeSelectOne($sql) !== null;
}

// ===========================
// INPUT VALIDATION & SANITIZATION
// ===========================

/**
 * Sanitize input to prevent SQL injection
 */
function sanitize($input) {
    global $conn;
    return mysqli_real_escape_string($conn, $input);
}

/**
 * Validate required fields in data array
 */
function validateRequired($data, $requiredFields) {
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || trim($data[$field]) === '') {
            error("Missing required field: $field", 400);
        }
    }
}

/**
 * Validate email format
 */
function validateEmail($email) {
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        error('Invalid email format', 400);
    }
}

/**
 * Validate username format (alphanumeric, underscore, dash, 3-50 chars)
 */
function validateUsername($username) {
    if (!preg_match('/^[a-zA-Z0-9_-]{3,50}$/', $username)) {
        error('Username must be 3-50 characters, alphanumeric with underscore/dash only', 400);
    }
}

/**
 * Validate role is valid
 */
function validateRole($role) {
    $valid_roles = ['Student', 'Teacher', 'Admin'];
    if (!in_array($role, $valid_roles)) {
        error('Invalid role. Must be one of: Student, Teacher, Admin', 400);
    }
}

/**
 * Validate attendance code format (6 char alphanumeric)
 */
function validateCodeFormat($code) {
    if (!preg_match('/^[A-Z0-9]{6}$/', strtoupper($code))) {
        error('Invalid code format. Code must be 6 alphanumeric characters', 400);
    }
}

/**
 * Generate unique attendance code (6 random alphanumeric uppercase)
 */
function generateAttendanceCode() {
    $characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    $code = '';
    for ($i = 0; $i < 6; $i++) {
        $code .= $characters[rand(0, strlen($characters) - 1)];
    }
    
    // Verify uniqueness
    while (recordExists('sessions', 'attendance_code', $code)) {
        $code = generateAttendanceCode();
    }
    
    return $code;
}

/**
 * Generate unique ID with prefix
 */
function generateId($prefix) {
    return $prefix . '_' . time() . '_' . rand(1000, 9999);
}

// ===========================
// RESPONSE HELPERS
// ===========================

/**
 * Return success response
 */
function success($message, $data = []) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit();
}

/**
 * Return warning response (200 but with warning flag)
 */
function warning($message, $data = []) {
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'warning' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit();
}

/**
 * Return error response
 */
function error($message, $code = 400) {
    http_response_code($code);
    echo json_encode([
        'success' => false,
        'message' => $message,
        'code' => $code
    ]);
    exit();
}

// ===========================
// ATTENDANCE & WARNING/EXCLUSION LOGIC
// ===========================

/**
 * Get student attendance statistics for a course
 */
function getStudentAttendanceStats($student_id, $course_id = null) {
    if ($course_id) {
        $course_filter = "AND s.course_id = '" . sanitize($course_id) . "'";
    } else {
        $course_filter = "";
    }
    
    $sql = "SELECT 
                COUNT(*) as total_sessions,
                SUM(CASE WHEN ar.attendance_status IN ('Present') THEN 1 ELSE 0 END) as present,
                SUM(CASE WHEN ar.attendance_status IN ('Absent', 'Unjustified') THEN 1 ELSE 0 END) as unjustified,
                SUM(CASE WHEN ar.attendance_status = 'Justified' THEN 1 ELSE 0 END) as justified
            FROM attendance_records ar
            JOIN sessions s ON ar.session_id = s.session_id
            WHERE ar.student_id = '" . sanitize($student_id) . "' $course_filter";
    
    $stats = executeSelectOne($sql);
    return [
        'total_sessions' => (int)($stats['total_sessions'] ?? 0),
        'present' => (int)($stats['present'] ?? 0),
        'unjustified_absences' => (int)($stats['unjustified'] ?? 0),
        'justified_absences' => (int)($stats['justified'] ?? 0),
    ];
}

/**
 * Check if student should be warned (2 unjustified OR 3 total absences)
 */
function shouldWarnStudent($student_id, $course_id) {
    $stats = getStudentAttendanceStats($student_id, $course_id);
    
    $unjustified = $stats['unjustified_absences'];
    $total_absences = $stats['unjustified_absences'] + $stats['justified_absences'];
    
    return ($unjustified >= 2) || ($total_absences >= 3);
}

/**
 * Check if student should be excluded (3 unjustified OR 5 justified absences)
 */
function shouldExcludeStudent($student_id, $course_id) {
    $stats = getStudentAttendanceStats($student_id, $course_id);
    
    $unjustified = $stats['unjustified_absences'];
    $justified = $stats['justified_absences'];
    
    return ($unjustified >= 3) || ($justified >= 5);
}

/**
 * Issue warning to student for a course
 */
function issueWarning($student_id, $course_id) {
    $existing = executeSelectOne("SELECT warning_id FROM warnings 
                                 WHERE student_id = '" . sanitize($student_id) . "' 
                                 AND course_id = '" . sanitize($course_id) . "' 
                                 AND is_active = TRUE");
    
    if ($existing) {
        return; // Already warned
    }
    
    $stats = getStudentAttendanceStats($student_id, $course_id);
    $warning_id = generateId('WARN');
    
    $sql = "INSERT INTO warnings (warning_id, student_id, course_id, absence_count, is_active, warning_message)
            VALUES (
                '" . sanitize($warning_id) . "',
                '" . sanitize($student_id) . "',
                '" . sanitize($course_id) . "',
                " . ($stats['unjustified_absences'] + $stats['justified_absences']) . ",
                TRUE,
                'Student has reached warning threshold'
            )";
    
    executeInsertUpdateDelete($sql);
}

/**
 * Issue exclusion to student for a course
 */
function issueExclusion($student_id, $course_id) {
    $existing = executeSelectOne("SELECT exclusion_id FROM exclusions 
                                 WHERE student_id = '" . sanitize($student_id) . "' 
                                 AND course_id = '" . sanitize($course_id) . "' 
                                 AND is_active = TRUE");
    
    if ($existing) {
        return; // Already excluded
    }
    
    $stats = getStudentAttendanceStats($student_id, $course_id);
    $exclusion_id = generateId('EXCL');
    
    $sql = "INSERT INTO exclusions (exclusion_id, student_id, course_id, absence_count, is_active, exclusion_reason)
            VALUES (
                '" . sanitize($exclusion_id) . "',
                '" . sanitize($student_id) . "',
                '" . sanitize($course_id) . "',
                " . ($stats['unjustified_absences'] + $stats['justified_absences']) . ",
                TRUE,
                'Student has reached exclusion threshold'
            )";
    
    executeInsertUpdateDelete($sql);
}

/**
 * Remove warning from student for a course
 */
function removeWarning($student_id, $course_id) {
    $sql = "UPDATE warnings SET is_active = FALSE 
            WHERE student_id = '" . sanitize($student_id) . "' 
            AND course_id = '" . sanitize($course_id) . "'";
    executeInsertUpdateDelete($sql);
}

/**
 * Remove exclusion from student for a course
 */
function removeExclusion($student_id, $course_id) {
    $sql = "UPDATE exclusions SET is_active = FALSE 
            WHERE student_id = '" . sanitize($student_id) . "' 
            AND course_id = '" . sanitize($course_id) . "'";
    executeInsertUpdateDelete($sql);
}

/**
 * Check if student is excluded from course
 */
function isStudentExcluded($student_id, $course_id) {
    $sql = "SELECT exclusion_id FROM exclusions 
            WHERE student_id = '" . sanitize($student_id) . "' 
            AND course_id = '" . sanitize($course_id) . "' 
            AND is_active = TRUE";
    return executeSelectOne($sql) !== null;
}

/**
 * Get student status (Normal, Warning, or Excluded) for a course
 */
function getStudentStatus($student_id, $course_id) {
    $is_excluded = isStudentExcluded($student_id, $course_id);
    
    if ($is_excluded) {
        return 'Excluded';
    }
    
    // Check warning
    $warning = executeSelectOne("SELECT warning_id FROM warnings 
                               WHERE student_id = '" . sanitize($student_id) . "' 
                               AND course_id = '" . sanitize($course_id) . "' 
                               AND is_active = TRUE");
    
    if ($warning) {
        return 'Warning';
    }
    
    return 'Normal';
}

/**
 * Recalculate and update warnings/exclusions for a student in a course
 * Called when attendance status is changed
 */
function recalculateStudentStatus($student_id, $course_id) {
    // First check if should be excluded
    if (shouldExcludeStudent($student_id, $course_id)) {
        issueExclusion($student_id, $course_id);
        removeWarning($student_id, $course_id); // Remove warning if excluded
        return 'Excluded';
    }
    
    // Remove exclusion if it was issued but conditions no longer met
    removeExclusion($student_id, $course_id);
    
    // Check if should be warned
    if (shouldWarnStudent($student_id, $course_id)) {
        issueWarning($student_id, $course_id);
        return 'Warning';
    }
    
    // Remove warning if it was issued but conditions no longer met
    removeWarning($student_id, $course_id);
    return 'Normal';
}

/**
 * Check if code is expired
 */
function isCodeExpired($expiration_time) {
    if (!$expiration_time) {
        return false; // No expiration set
    }
    return strtotime($expiration_time) < time();
}

/**
 * Check if attendance code has already been submitted by this student
 */
function hasStudentAlreadySubmitted($student_id, $session_id) {
    $sql = "SELECT record_id FROM attendance_records 
            WHERE student_id = '" . sanitize($student_id) . "' 
            AND session_id = '" . sanitize($session_id) . "'";
    return executeSelectOne($sql) !== null;
}

// ===========================
// PERMISSION CHECKS
// ===========================

/**
 * Check if teacher teaches this course
 */
function teacherTeachesCourse($teacher_id, $course_id) {
    $sql = "SELECT assignment_id FROM teacher_courses 
            WHERE teacher_id = '" . sanitize($teacher_id) . "' 
            AND course_id = '" . sanitize($course_id) . "'";
    return executeSelectOne($sql) !== null;
}

/**
 * Check if student is enrolled in this course
 */
function studentEnrolledInCourse($student_id, $course_id) {
    $sql = "SELECT enrollment_id FROM course_students 
            WHERE student_id = '" . sanitize($student_id) . "' 
            AND course_id = '" . sanitize($course_id) . "'";
    return executeSelectOne($sql) !== null;
}

?>
