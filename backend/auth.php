<?php
include 'config.php';

// Get action from URL
$action = isset($_GET['action']) ? $_GET['action'] : '';

// LOGIN
if ($action == 'login') {
    // Get data from app
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    validateRequired($data, ['username', 'password', 'role']);
    
    $username = sanitize($data['username']);
    $password = sanitize($data['password']);
    $role = sanitize($data['role']);
    
    // Normalize role to match database enum
    $role = ucfirst(strtolower($role)); // Convert to 'Student', 'Teacher', 'Admin'
    if (!in_array($role, ['Student', 'Teacher', 'Admin'])) {
        error('Invalid role. Must be Student, Teacher, or Admin', 400);
    }
    
    // Check if user exists with this username and type
    $sql = "SELECT user_id, username, email, full_name, user_type, account_status 
            FROM users 
            WHERE username = '$username' AND user_type = '$role' AND account_status = 'Active'";
    
    $user = executeSelectOne($sql);
    
    if (!$user) {
        error('Invalid username, password, or role', 401);
    }
    
    // Check password (in production, use password_verify())
    if ($user['password'] !== $password) {
        error('Invalid username, password, or role', 401);
    }
    
    // Get role-specific ID (student_id, teacher_id, or admin_id)
    $role_id = null;
    $role_table = '';
    
    if ($role === 'Student') {
        $role_table = 'students';
        $id_field = 'student_id';
    } else if ($role === 'Teacher') {
        $role_table = 'teachers';
        $id_field = 'teacher_id';
    } else if ($role === 'Admin') {
        $role_table = 'admins';
        $id_field = 'admin_id';
    }
    
    $role_sql = "SELECT $id_field FROM $role_table WHERE user_id = '{$user['user_id']}'";
    $role_record = executeSelectOne($role_sql);
    
    if ($role_record) {
        $role_id = $role_record[$id_field];
    }
    
    // Update last login
    $update_sql = "UPDATE users SET last_login = NOW() WHERE user_id = '{$user['user_id']}'";
    executeInsertUpdateDelete($update_sql);
    
    // Return success with user data
    success('Login successful', [
        'id' => $role_id ?? $user['user_id'],
        'user_id' => $user['user_id'],
        'username' => $user['username'],
        'name' => $user['full_name'],
        'email' => $user['email'],
        'role' => strtolower($role)
    ]);
} else {
    error('Invalid action', 400);
}
?>
