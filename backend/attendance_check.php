<?php
// ============================================
// ATTENDANCE CHECKING & EXPULSION SYSTEM
// ============================================
// This file handles:
// - Checking student attendance records
// - Issuing warnings when close to limits
// - Expelling students who exceed limits

// LIMITS
define('UNJUSTIFIED_ABSENCE_LIMIT', 3);      // Expulsion at 3 unjustified absences
define('JUSTIFIED_ABSENCE_LIMIT', 5);        // Expulsion at 5 justified absences
define('UNJUSTIFIED_WARNING_LEVEL', 2);      // Warning at 2 unjustified absences
define('JUSTIFIED_WARNING_LEVEL', 4);        // Warning at 4 justified absences

// ============================================
// GET STUDENT ATTENDANCE STATISTICS
// ============================================

function getStudentAttendanceStats($student_id, $course_id = null) {
    global $conn;
    
    $student_id = sanitize($student_id);
    
    // Build SQL query
    if ($course_id) {
        $course_id = sanitize($course_id);
        $sql = "SELECT 
                COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present_count,
                COUNT(CASE WHEN a.status = 'absent' AND a.justified = 0 THEN 1 END) as unjustified_absent,
                COUNT(CASE WHEN a.status = 'absent' AND a.justified = 1 THEN 1 END) as justified_absent,
                COUNT(a.attendance_id) as total_sessions
                FROM attendance a
                JOIN sessions s ON a.session_id = s.session_id
                WHERE a.student_id = '$student_id' AND s.course_id = '$course_id'";
    } else {
        $sql = "SELECT 
                COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present_count,
                COUNT(CASE WHEN a.status = 'absent' AND a.justified = 0 THEN 1 END) as unjustified_absent,
                COUNT(CASE WHEN a.status = 'absent' AND a.justified = 1 THEN 1 END) as justified_absent,
                COUNT(a.attendance_id) as total_sessions
                FROM attendance a
                WHERE a.student_id = '$student_id'";
    }
    
    $result = mysqli_query($conn, $sql);
    
    if (!$result) {
        error('Database error: ' . mysqli_error($conn), 500);
    }
    
    $stats = mysqli_fetch_assoc($result);
    
    return [
        'present_count' => $stats['present_count'],
        'unjustified_absent' => $stats['unjustified_absent'],
        'justified_absent' => $stats['justified_absent'],
        'total_sessions' => $stats['total_sessions']
    ];
}

// ============================================
// CHECK IF STUDENT IS EXPELLED
// ============================================

function isStudentExpelled($student_id, $course_id = null) {
    $stats = getStudentAttendanceStats($student_id, $course_id);
    
    // Check if exceeded limits
    if ($stats['unjustified_absent'] >= UNJUSTIFIED_ABSENCE_LIMIT) {
        return [
            'expelled' => true,
            'reason' => 'Exceeded unjustified absences limit',
            'unjustified_count' => $stats['unjustified_absent'],
            'limit' => UNJUSTIFIED_ABSENCE_LIMIT
        ];
    }
    
    if ($stats['justified_absent'] >= JUSTIFIED_ABSENCE_LIMIT) {
        return [
            'expelled' => true,
            'reason' => 'Exceeded justified absences limit',
            'justified_count' => $stats['justified_absent'],
            'limit' => JUSTIFIED_ABSENCE_LIMIT
        ];
    }
    
    return ['expelled' => false];
}

// ============================================
// CHECK IF STUDENT NEEDS WARNING
// ============================================

function getStudentWarningStatus($student_id, $course_id = null) {
    $stats = getStudentAttendanceStats($student_id, $course_id);
    
    $warnings = [];
    
    // Check unjustified absence warning
    if ($stats['unjustified_absent'] >= UNJUSTIFIED_WARNING_LEVEL && 
        $stats['unjustified_absent'] < UNJUSTIFIED_ABSENCE_LIMIT) {
        $warnings[] = [
            'type' => 'unjustified_absence_warning',
            'message' => 'Warning: You have ' . $stats['unjustified_absent'] . ' unjustified absences. Limit is ' . UNJUSTIFIED_ABSENCE_LIMIT . '.',
            'current' => $stats['unjustified_absent'],
            'limit' => UNJUSTIFIED_ABSENCE_LIMIT,
            'remaining' => UNJUSTIFIED_ABSENCE_LIMIT - $stats['unjustified_absent']
        ];
    }
    
    // Check justified absence warning
    if ($stats['justified_absent'] >= JUSTIFIED_WARNING_LEVEL && 
        $stats['justified_absent'] < JUSTIFIED_ABSENCE_LIMIT) {
        $warnings[] = [
            'type' => 'justified_absence_warning',
            'message' => 'Warning: You have ' . $stats['justified_absent'] . ' justified absences. Limit is ' . JUSTIFIED_ABSENCE_LIMIT . '.',
            'current' => $stats['justified_absent'],
            'limit' => JUSTIFIED_ABSENCE_LIMIT,
            'remaining' => JUSTIFIED_ABSENCE_LIMIT - $stats['justified_absent']
        ];
    }
    
    return $warnings;
}

// ============================================
// UPDATE STUDENT EXPULSION STATUS
// ============================================

function updateStudentExpulsionStatus($student_id, $course_id = null) {
    global $conn;
    
    $student_id = sanitize($student_id);
    
    $expulsion_info = isStudentExpelled($student_id, $course_id);
    
    if ($expulsion_info['expelled']) {
        // Update student status to expelled
        $reason = sanitize($expulsion_info['reason']);
        
        if ($course_id) {
            $course_id = sanitize($course_id);
            // Remove from course enrollment
            $sql = "DELETE FROM enrollments WHERE student_id = '$student_id' AND course_id = '$course_id'";
        } else {
            // Mark as expelled in system
            $sql = "UPDATE users SET status = 'expelled' WHERE user_id = '$student_id'";
        }
        
        mysqli_query($conn, $sql);
        
        return [
            'expelled' => true,
            'reason' => $expulsion_info['reason'],
            'details' => $expulsion_info
        ];
    }
    
    return ['expelled' => false];
}

// ============================================
// CHECK AND PROCESS STUDENT STATUS
// ============================================

function checkStudentStatus($student_id, $course_id = null) {
    // First check if expelled
    $expulsion = isStudentExpelled($student_id, $course_id);
    
    if ($expulsion['expelled']) {
        return [
            'status' => 'expelled',
            'reason' => $expulsion['reason'],
            'details' => $expulsion
        ];
    }
    
    // Check if warnings needed
    $warnings = getStudentWarningStatus($student_id, $course_id);
    
    if (count($warnings) > 0) {
        return [
            'status' => 'warning',
            'warnings' => $warnings
        ];
    }
    
    // Normal status
    return [
        'status' => 'normal',
        'stats' => getStudentAttendanceStats($student_id, $course_id)
    ];
}

// ============================================
// GET ALL EXPELLED STUDENTS
// ============================================

function getExpelledStudents($course_id = null) {
    global $conn;
    
    // Get all students
    if ($course_id) {
        $course_id = sanitize($course_id);
        $sql = "SELECT DISTINCT u.user_id, u.first_name, u.last_name, u.email
                FROM users u
                JOIN enrollments e ON u.user_id = e.student_id
                WHERE u.role = 'student' AND e.course_id = '$course_id'";
    } else {
        $sql = "SELECT user_id, first_name, last_name, email FROM users WHERE role = 'student'";
    }
    
    $result = mysqli_query($conn, $sql);
    $expelled_students = [];
    
    while ($student = mysqli_fetch_assoc($result)) {
        $expulsion = isStudentExpelled($student['user_id'], $course_id);
        
        if ($expulsion['expelled']) {
            $student['expulsion_reason'] = $expulsion['reason'];
            $student['expulsion_details'] = $expulsion;
            $expelled_students[] = $student;
        }
    }
    
    return $expelled_students;
}

// ============================================
// GET ATTENDANCE REPORT WITH STATUS
// ============================================

function getAttendanceReportWithStatus($course_id) {
    global $conn;
    
    $course_id = sanitize($course_id);
    
    $sql = "SELECT u.user_id, u.first_name, u.last_name,
            COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present_count,
            COUNT(CASE WHEN a.status = 'absent' AND a.justified = 0 THEN 1 END) as unjustified_absent,
            COUNT(CASE WHEN a.status = 'absent' AND a.justified = 1 THEN 1 END) as justified_absent,
            COUNT(a.attendance_id) as total_sessions
            FROM users u
            LEFT JOIN enrollments e ON u.user_id = e.student_id
            LEFT JOIN attendance a ON e.student_id = a.student_id
            JOIN sessions s ON a.session_id = s.session_id
            WHERE u.role = 'student' AND e.course_id = '$course_id' AND s.course_id = '$course_id'
            GROUP BY u.user_id";
    
    $result = mysqli_query($conn, $sql);
    $report = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $status = checkStudentStatus($row['user_id'], $course_id);
        
        $row['attendance_status'] = $status['status'];
        if (isset($status['warnings'])) {
            $row['warnings'] = $status['warnings'];
        }
        if (isset($status['details'])) {
            $row['expulsion_details'] = $status['details'];
        }
        
        $report[] = $row;
    }
    
    return $report;
}

?>
