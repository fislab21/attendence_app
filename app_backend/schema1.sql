-- ============================================
-- ATTENDANCE MANAGEMENT SYSTEM - DATABASE SCHEMA
-- ============================================

-- Users Table (Parent table for all user types)
CREATE DATABASE IF NOT EXISTS student_attendence_db;
USE student_attendence_db;
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    user_type ENUM('Student', 'Teacher', 'Admin') NOT NULL,
    account_status ENUM('Active', 'Suspended', 'Deleted') DEFAULT 'Active',
    failed_login_attempts INT DEFAULT 0,
    account_locked_until TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);

-- Students Table (Extends users)
CREATE TABLE students (
    student_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) UNIQUE NOT NULL,
    total_absences INT DEFAULT 0,
    justified_absences INT DEFAULT 0,
    unjustified_absences INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Teachers Table (Extends users)
CREATE TABLE teachers (
    teacher_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) UNIQUE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Admins Table (Extends users)
CREATE TABLE admins (
    admin_id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) UNIQUE NOT NULL,
    privilege_level VARCHAR(50) DEFAULT 'Standard',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Courses Table
CREATE TABLE courses (
    course_id VARCHAR(50) PRIMARY KEY,
    course_name VARCHAR(200) NOT NULL,
    course_code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Teacher-Course Assignment Table (Many-to-Many)
CREATE TABLE teacher_courses (
    assignment_id VARCHAR(50) PRIMARY KEY,
    teacher_id VARCHAR(50) NOT NULL,
    course_id VARCHAR(50) NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    UNIQUE KEY unique_teacher_course (teacher_id, course_id)
);

-- Student-Course Enrollment Table (Many-to-Many)
CREATE TABLE course_students (
    enrollment_id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    course_id VARCHAR(50) NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    UNIQUE KEY unique_student_course (student_id, course_id)
);

-- Sessions Table
CREATE TABLE sessions (
    session_id VARCHAR(50) PRIMARY KEY,
    course_id VARCHAR(50) NOT NULL,
    teacher_id VARCHAR(50) NOT NULL,
    attendance_code VARCHAR(20),
    start_time TIMESTAMP NOT NULL,
    expiration_time TIMESTAMP NULL,
    status ENUM('Active', 'Expired', 'Completed', 'Scheduled') DEFAULT 'Scheduled',
    room VARCHAR(50),
    time_slot VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id) ON DELETE CASCADE
);

-- Attendance Records Table
CREATE TABLE attendance_records (
    record_id VARCHAR(50) PRIMARY KEY,
    session_id VARCHAR(50) NOT NULL,
    student_id VARCHAR(50) NOT NULL,
    attendance_status ENUM('Present', 'Absent', 'Justified', 'Unjustified') NOT NULL,
    submission_time TIMESTAMP NULL,
    absence_type VARCHAR(50) NULL,
    marked_by VARCHAR(50) NULL, -- teacher_id who marked the absence
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (marked_by) REFERENCES teachers(teacher_id) ON DELETE SET NULL,
    UNIQUE KEY unique_session_student (session_id, student_id)
);

-- Warnings Table
CREATE TABLE warnings (
    warning_id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    course_id VARCHAR(50) NOT NULL,
    issue_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    absence_count INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    warning_message TEXT,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);

-- Exclusions Table
CREATE TABLE exclusions (
    exclusion_id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    course_id VARCHAR(50) NOT NULL,
    issue_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    absence_count INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    exclusion_reason TEXT,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE
);