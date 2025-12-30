<?php
include 'config.php';

// Get action from URL
$action = isset($_GET['action']) ? $_GET['action'] : '';

// GET ALL USERS
if ($action == 'get_users') {
    $role = isset($_GET['role']) ? sanitize($_GET['role']) : '';
    
    if ($role) {
        $sql = "SELECT user_id, username, first_name, last_name, email, role FROM users WHERE role = '$role'";
    } else {
        $sql = "SELECT user_id, username, first_name, last_name, email, role FROM users";
    }
    
    $users = executeSelect($sql);
    
    if (count($users) > 0) {
        success('Users retrieved', $users);
    } else {
        warning('No users found', []);
    }
}

// GET ALL COURSES
else if ($action == 'get_courses') {
    $sql = "SELECT course_id, course_code, course_name FROM courses";
    $courses = executeSelect($sql);
    
    if (count($courses) > 0) {
        success('Courses retrieved', $courses);
    } else {
        warning('No courses found', []);
    }
}

// CREATE USER
else if ($action == 'create_user') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['username', 'password', 'first_name', 'last_name', 'email', 'role']);
    
    $username = sanitize($data['username']);
    $password = sanitize($data['password']);
    $first_name = sanitize($data['first_name']);
    $last_name = sanitize($data['last_name']);
    $email = sanitize($data['email']);
    $role = sanitize($data['role']);
    
    // Check if username already exists
    if (recordExists('users', 'username', $username)) {
        error('Username already exists', 400);
    }
    
    $sql = "INSERT INTO users (username, password, first_name, last_name, email, role)
            VALUES ('$username', '$password', '$first_name', '$last_name', '$email', '$role')";
    
    $id = executeInsertGetId($sql);
    
    success('User created successfully', ['id' => $id]);
}

// CREATE COURSE
else if ($action == 'create_course') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['course_code', 'course_name']);
    
    $course_code = sanitize($data['course_code']);
    $course_name = sanitize($data['course_name']);
    
    // Check if course code already exists
    if (recordExists('courses', 'course_code', $course_code)) {
        error('Course code already exists', 400);
    }
    
    $sql = "INSERT INTO courses (course_code, course_name)
            VALUES ('$course_code', '$course_name')";
    
    $id = executeInsertGetId($sql);
    
    success('Course created successfully', ['id' => $id]);
}

// ASSIGN COURSE TO TEACHER
else if ($action == 'assign_course') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['teacher_id', 'course_id']);
    
    $teacher_id = sanitize($data['teacher_id']);
    $course_id = sanitize($data['course_id']);
    
    $sql = "INSERT INTO teacher_courses (teacher_id, course_id) VALUES ('$teacher_id', '$course_id')";
    
    executeInsertUpdateDelete($sql);
    
    success('Course assigned to teacher successfully');
}

// ENROLL STUDENT IN COURSE
else if ($action == 'enroll_student') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['student_id', 'course_id']);
    
    $student_id = sanitize($data['student_id']);
    $course_id = sanitize($data['course_id']);
    
    $sql = "INSERT INTO enrollments (student_id, course_id) VALUES ('$student_id', '$course_id')";
    
    executeInsertUpdateDelete($sql);
    
    success('Student enrolled in course successfully');
}

// DELETE USER
else if ($action == 'delete_user') {
    $user_id = isset($_GET['user_id']) ? sanitize($_GET['user_id']) : '';
    
    if (!$user_id) {
        error('User ID is required', 400);
    }
    
    $sql = "DELETE FROM users WHERE user_id = '$user_id'";
    
    executeInsertUpdateDelete($sql);
    
    success('User deleted successfully');
}

// DELETE COURSE
else if ($action == 'delete_course') {
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : '';
    
    if (!$course_id) {
        error('Course ID is required', 400);
    }
    
    $sql = "DELETE FROM courses WHERE course_id = '$course_id'";
    
    executeInsertUpdateDelete($sql);
    
    success('Course deleted successfully');
}

// GET ALL ASSIGNMENTS (Teacher-Course Mappings)
else if ($action == 'get_assignments') {
    $sql = "SELECT tc.teacher_course_id, tc.teacher_id, tc.course_id, 
            u.first_name, u.last_name, c.course_code, c.course_name
            FROM teacher_courses tc
            JOIN users u ON tc.teacher_id = u.user_id
            JOIN courses c ON tc.course_id = c.course_id
            ORDER BY u.last_name, c.course_name";
    
    $assignments = executeSelect($sql);
    
    if (count($assignments) > 0) {
        success('Assignments retrieved', $assignments);
    } else {
        warning('No teacher-course assignments found', []);
    }
}

// GET ASSIGNMENTS FOR A SPECIFIC TEACHER
else if ($action == 'get_teacher_assignments') {
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    
    if (!$teacher_id) {
        error('Teacher ID is required', 400);
    }
    
    $sql = "SELECT tc.teacher_course_id, tc.teacher_id, tc.course_id, c.course_code, c.course_name
            FROM teacher_courses tc
            JOIN courses c ON tc.course_id = c.course_id
            WHERE tc.teacher_id = '$teacher_id'
            ORDER BY c.course_name";
    
    $assignments = executeSelect($sql);
    
    if (count($assignments) > 0) {
        success('Teacher assignments retrieved', $assignments);
    } else {
        warning('Teacher has no course assignments', []);
    }
}

// ASSIGN MULTIPLE COURSES TO TEACHER
else if ($action == 'assign_courses') {
    $data = json_decode(file_get_contents("php://input"), true);
    
    validateRequired($data, ['teacher_id', 'course_ids']);
    
    $teacher_id = sanitize($data['teacher_id']);
    $course_ids = $data['course_ids'];
    
    if (!is_array($course_ids) || count($course_ids) === 0) {
        error('At least one course ID is required', 400);
    }
    
    // Delete existing assignments for this teacher
    $delete_sql = "DELETE FROM teacher_courses WHERE teacher_id = '$teacher_id'";
    executeInsertUpdateDelete($delete_sql);
    
    // Add new assignments
    $success_count = 0;
    foreach ($course_ids as $course_id) {
        $course_id = sanitize($course_id);
        $insert_sql = "INSERT INTO teacher_courses (teacher_id, course_id) 
                       VALUES ('$teacher_id', '$course_id')";
        try {
            executeInsertUpdateDelete($insert_sql);
            $success_count++;
        } catch (Exception $e) {
            // Continue with next course if one fails
        }
    }
    
    if ($success_count > 0) {
        success('Courses assigned to teacher successfully', ['assigned_count' => $success_count]);
    } else {
        error('Failed to assign any courses', 400);
    }
}

// REMOVE TEACHER-COURSE ASSIGNMENT
else if ($action == 'remove_assignment') {
    $teacher_id = isset($_GET['teacher_id']) ? sanitize($_GET['teacher_id']) : '';
    $course_id = isset($_GET['course_id']) ? sanitize($_GET['course_id']) : '';
    
    if (!$teacher_id || !$course_id) {
        error('Teacher ID and Course ID are required', 400);
    }
    
    $sql = "DELETE FROM teacher_courses WHERE teacher_id = '$teacher_id' AND course_id = '$course_id'";
    
    executeInsertUpdateDelete($sql);
    
    success('Assignment removed successfully');
} else {
    error('Invalid action', 400);
}

?>
