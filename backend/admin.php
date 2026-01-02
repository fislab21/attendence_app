<?php
/**
 * ADMIN API
 * UC9: Manage Accounts
 * UC10: Assign Courses
 * UC7: View Records
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
// UC9: GET ALL USERS
// ===========================
if ($action === 'users' && $_SERVER['REQUEST_METHOD'] === 'GET') {

    $role = isset($_GET['role']) ? sanitize($_GET['role']) : null;
    $status = isset($_GET['status']) ? sanitize($_GET['status']) : null;

    $where = [];
    if ($role) $where[] = "user_type = '$role'";
    if ($status) $where[] = "account_status = '$status'";

    $where_clause = count($where) ? 'WHERE ' . implode(' AND ', $where) : '';

    $sql = "SELECT u.user_id, u.username, u.email, u.full_name, u.user_type, u.account_status, u.created_at, u.last_login,
                   t.teacher_id, s.student_id, a.admin_id
            FROM users u
            LEFT JOIN teachers t ON u.user_id = t.user_id
            LEFT JOIN students s ON u.user_id = s.user_id
            LEFT JOIN admins a ON u.user_id = a.user_id
            $where_clause ORDER BY u.created_at DESC";

    $users = executeSelect($sql);
    success('Users retrieved', $users);
}

// ===========================
// UC9: ADD NEW USER
// ===========================
else if ($action === 'users' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);

    validateRequired($data, ['username', 'email', 'full_name', 'user_type', 'password']);

    $username = sanitize($data['username']);
    $email = sanitize($data['email']);
    $full_name = sanitize($data['full_name']);
    $user_type = sanitize($data['user_type']);
    $password = $data['password'];

    validateUsername($username);
    validateEmail($email);
    validateRole($user_type);

    if (recordExists('users', 'username', $username)) {
        error('Username already exists', 400);
    }

    if (recordExists('users', 'email', $email)) {
        error('Email already in use', 400);
    }

    // 🔐 HASH PASSWORD
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    $user_id = generateId('USR');

    $sql = "INSERT INTO users (user_id, username, password, email, full_name, user_type, account_status)
            VALUES (
                '" . sanitize($user_id) . "',
                '" . sanitize($username) . "',
                '" . sanitize($hashed_password) . "',
                '" . sanitize($email) . "',
                '" . sanitize($full_name) . "',
                '" . sanitize($user_type) . "',
                'Active'
            )";

    executeInsertUpdateDelete($sql);

    // Create role-specific record
    if ($user_type === 'Student') {
        executeInsertUpdateDelete("INSERT INTO students (student_id, user_id) VALUES ('" . generateId('STU') . "', '$user_id')");
    } elseif ($user_type === 'Teacher') {
        executeInsertUpdateDelete("INSERT INTO teachers (teacher_id, user_id) VALUES ('" . generateId('TCH') . "', '$user_id')");
    } elseif ($user_type === 'Admin') {
        executeInsertUpdateDelete("INSERT INTO admins (admin_id, user_id) VALUES ('" . generateId('ADM') . "', '$user_id')");
    }

    success('User created successfully', [
        'user_id' => $user_id,
        'username' => $username,
        'email' => $email
    ]);
}

// ===========================
// UC9: DELETE USER
// ===========================
else if ($action === 'users' && $_SERVER['REQUEST_METHOD'] === 'DELETE') {

    $user_id = sanitize($_GET['user_id'] ?? '');

    if (!$user_id) error('User ID required', 400);

    executeInsertUpdateDelete("UPDATE users SET account_status = 'Deleted' WHERE user_id = '$user_id'");
    success('User deleted successfully', []);
}

// ===========================
// UC9: REINSTATE USER
// ===========================
else if ($action === 'reinstate' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);
    validateRequired($data, ['user_id']);

    $user_id = sanitize($data['user_id']);

    executeInsertUpdateDelete("UPDATE users SET account_status = 'Active' WHERE user_id = '$user_id'");
    success('User reinstated successfully', []);
}

// ===========================
// UC9: SUSPEND USER
// ===========================
else if ($action === 'suspend' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);
    validateRequired($data, ['user_id']);

    $user_id = sanitize($data['user_id']);
    executeInsertUpdateDelete("UPDATE users SET account_status = 'Suspended' WHERE user_id = '$user_id'");
    success('User suspended successfully', []);
}

// ===========================
// UC10: ASSIGN COURSES
// ===========================
else if ($action === 'assign-courses' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);
    
    // Accept either teacher_id or user_id
    if (!isset($data['teacher_id']) && !isset($data['user_id'])) {
        error('teacher_id or user_id is required', 400);
    }
    
    if (!isset($data['course_ids'])) {
        error('course_ids is required', 400);
    }

    $course_ids = $data['course_ids'];
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

    executeInsertUpdateDelete("DELETE FROM teacher_courses WHERE teacher_id = '$teacher_id'");

    $assigned_count = 0;
    foreach ($course_ids as $course_id) {
        if (!recordExists('courses', 'course_id', $course_id)) continue;

        executeInsertUpdateDelete(
            "INSERT INTO teacher_courses (assignment_id, teacher_id, course_id)
             VALUES ('" . generateId('TASN') . "', '$teacher_id', '$course_id')"
        );
        $assigned_count++;
    }

    success('Courses assigned successfully', ['assigned_count' => $assigned_count, 'teacher_id' => $teacher_id]);
}

// ===========================
// GET ALL COURSES
// ===========================
else if ($action === 'courses' && $_SERVER['REQUEST_METHOD'] === 'GET') {

    $sql = "SELECT course_id, course_code, course_name, created_at 
            FROM courses 
            ORDER BY course_name ASC";

    $courses = executeSelect($sql);
    
    // Ensure we return a valid response even if empty
    if (is_array($courses)) {
        success('Courses retrieved', $courses);
    } else {
        success('Courses retrieved', []);
    }
}

// ===========================
// GET ALL ASSIGNMENTS
// ===========================
else if ($action === 'assignments' && $_SERVER['REQUEST_METHOD'] === 'GET') {

    $sql = "SELECT ta.assignment_id, ta.teacher_id, t.user_id as teacher_user_id, u.full_name as teacher_name, ta.course_id, c.course_name, c.course_code
            FROM teacher_courses ta
            JOIN teachers t ON ta.teacher_id = t.teacher_id
            JOIN users u ON t.user_id = u.user_id
            JOIN courses c ON ta.course_id = c.course_id
            ORDER BY u.full_name, c.course_name ASC";

    $assignments = executeSelect($sql);
    
    // Ensure we return a valid response even if empty
    if (is_array($assignments)) {
        success('Assignments retrieved', $assignments);
    } else {
        success('Assignments retrieved', []);
    }
}

// ===========================
// REMOVE ASSIGNMENT
// ===========================
else if ($action === 'remove-assignment' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);
    validateRequired($data, ['teacher_id', 'course_id']);

    $teacher_id = sanitize($data['teacher_id']);
    $course_id = sanitize($data['course_id']);

    executeInsertUpdateDelete("DELETE FROM teacher_courses WHERE teacher_id = '$teacher_id' AND course_id = '$course_id'");
    success('Assignment removed successfully', []);
}

// ===========================
// UC7: VIEW RECORDS
// ===========================
else if ($action === 'all-records' && $_SERVER['REQUEST_METHOD'] === 'GET') {

    $sql = "SELECT ar.record_id, s.course_id, c.course_name, ar.student_id,
                   u.full_name, ar.attendance_status, ar.submission_time, s.start_time
            FROM attendance_records ar
            JOIN sessions s ON ar.session_id = s.session_id
            JOIN courses c ON s.course_id = c.course_id
            LEFT JOIN students st ON ar.student_id = st.student_id
            LEFT JOIN users u ON st.user_id = u.user_id
            ORDER BY s.start_time DESC";

    $records = executeSelect($sql);
    success('Records retrieved', $records);
}

// ===========================
// INVALID ROUTE
// ===========================
else {
    error('Invalid action', 400);
}
