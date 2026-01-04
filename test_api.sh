#!/bin/bash
# Quick test script for session-attendance API

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./test_api.sh <session_id> <user_id>"
    echo ""
    echo "Example: ./test_api.sh SES001 USR001"
    exit 1
fi

SESSION_ID=$1
USER_ID=$2
BASE_URL="http://localhost:8000"  # Change this to your backend URL

echo "Testing session-attendance API..."
echo "=================================="
echo "Session ID: $SESSION_ID"
echo "User ID: $USER_ID"
echo "Endpoint: $BASE_URL/backend/teacher.php/session-attendance"
echo ""

curl -s "$BASE_URL/backend/teacher.php/session-attendance?session_id=$SESSION_ID&user_id=$USER_ID" | python3 -m json.tool

echo ""
echo ""
echo "Database verification queries:"
echo "=============================="
echo ""
echo "1. Check if session exists:"
echo "   SELECT session_id, course_id, status FROM sessions WHERE session_id = '$SESSION_ID';"
echo ""
echo "2. Check if course has students:"
echo "   SELECT COUNT(*) as student_count FROM course_students WHERE course_id = (SELECT course_id FROM sessions WHERE session_id = '$SESSION_ID');"
echo ""
echo "3. Check if teacher teaches the course:"
echo "   SELECT tc.teacher_id FROM teacher_courses tc WHERE tc.course_id = (SELECT course_id FROM sessions WHERE session_id = '$SESSION_ID') AND tc.teacher_id = (SELECT teacher_id FROM teachers WHERE user_id = '$USER_ID');"
