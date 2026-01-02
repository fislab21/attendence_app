<?php
/**
 * AUTHENTICATION API
 * UC1: Login
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

// ===========================
// UC1: LOGIN
// ===========================
if ($action === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);
    validateRequired($data, ['username', 'password', 'role']);

    $username = sanitize($data['username']);
    $password = $data['password'];
    $role = ucfirst(strtolower($data['role']));

    validateRole($role);

    // Fetch user including password hash
    $sql = "SELECT user_id, username, password, email, full_name, user_type, account_status
            FROM users
            WHERE username = '" . sanitize($username) . "'
              AND user_type = '" . sanitize($role) . "'";

    $user = executeSelectOne($sql);

    // ❌ Invalid credentials
    if (!$user) {
        error('Invalid username, password, or role', 401);
    }

    // ❌ Account suspended
    if ($user['account_status'] === 'Suspended') {
        error('Your account has been suspended. Contact administrator.', 403);
    }

    // ❌ Account deleted
    if ($user['account_status'] === 'Deleted') {
        error('Your account has been deleted.', 403);
    }

    // ✅ VERIFY PASSWORD
    if (!password_verify($password, $user['password'])) {
        error('Invalid username, password, or role', 401);
    }

    // ✅ SUCCESS → update last login
    executeInsertUpdateDelete("
        UPDATE users 
        SET last_login = NOW()
        WHERE user_id = '{$user['user_id']}'
    ");

    // Fetch role-specific ID
    $role_table = '';
    $id_field = '';

    if ($role === 'Student') {
        $role_table = 'students';
        $id_field = 'student_id';
    } elseif ($role === 'Teacher') {
        $role_table = 'teachers';
        $id_field = 'teacher_id';
    } elseif ($role === 'Admin') {
        $role_table = 'admins';
        $id_field = 'admin_id';
    }

    $role_id = null;
    if ($role_table) {
        $r = executeSelectOne("SELECT $id_field FROM $role_table WHERE user_id = '{$user['user_id']}'");
        $role_id = $r[$id_field] ?? null;
    }

    success('Login successful', [
        'id' => $role_id ?? $user['user_id'],
        'user_id' => $user['user_id'],
        'username' => $user['username'],
        'name' => $user['full_name'],
        'email' => $user['email'],
        'role' => strtolower($role)
    ]);
}

// ===========================
// INVALID ROUTE
// ===========================
else {
    error('Invalid action. Use POST /auth.php/login', 400);
}
?>