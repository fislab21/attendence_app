-- Migration script to add login attempt tracking fields to users table
-- Run this if you have an existing database

USE student_attendence_db;

-- Add new columns if they don't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS failed_login_attempts INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS account_locked_until TIMESTAMP NULL;

-- Update existing users to have 0 failed attempts
UPDATE users SET failed_login_attempts = 0 WHERE failed_login_attempts IS NULL;

