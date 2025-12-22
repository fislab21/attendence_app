from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from datetime import datetime

router = APIRouter(prefix="/student", tags=["student"])

class MarkAttendanceRequest(BaseModel):
    code: str
    student_id: str

@router.post("/mark-attendance")
async def mark_attendance(request: MarkAttendanceRequest):
    """Mark attendance using attendance code"""
    code = request.code.upper().strip()
    
    # Find active session with this code
    query = """
        SELECT s.session_id, s.course_id, s.teacher_id, s.expiration_time, s.status
        FROM sessions s
        WHERE s.attendance_code = %s 
        AND s.status = 'Active'
        AND s.expiration_time > NOW()
    """
    
    session = execute_query(query, (code,), fetch_one=True)
    
    if not session:
        raise HTTPException(status_code=404, detail="Invalid or expired attendance code")
    
    # Get student_id from user_id
    student_query = "SELECT student_id FROM students WHERE user_id = %s"
    student = execute_query(student_query, (request.student_id,), fetch_one=True)
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    actual_student_id = student["student_id"]
    
    # Check if student is enrolled in the course
    check_enrollment = """
        SELECT student_id 
        FROM course_students
        WHERE student_id = %s AND course_id = %s
    """
    
    enrollment = execute_query(check_enrollment, (actual_student_id, session["course_id"]), fetch_one=True)
    
    if not enrollment:
        raise HTTPException(status_code=403, detail="Student not enrolled in this course")
    
    # Check if student is excluded from this course
    check_exclusion = """
        SELECT exclusion_id 
        FROM exclusions
        WHERE student_id = %s AND course_id = %s AND is_active = TRUE
    """
    
    exclusion = execute_query(check_exclusion, (actual_student_id, session["course_id"]), fetch_one=True)
    
    if exclusion:
        raise HTTPException(status_code=403, detail="Student is excluded from this course and cannot mark attendance")
    
    # Check if attendance already recorded
    check_existing = """
        SELECT record_id FROM attendance_records
        WHERE session_id = %s AND student_id = %s
    """
    
    existing = execute_query(check_existing, (session["session_id"], actual_student_id), fetch_one=True)
    
    if existing:
        raise HTTPException(status_code=400, detail="Attendance already marked for this session")
    
    # Insert attendance record
    record_id = generate_id()
    insert_query = """
        INSERT INTO attendance_records 
        (record_id, session_id, student_id, attendance_status, submission_time, absence_type)
        VALUES (%s, %s, %s, 'Present', NOW(), NULL)
    """
    
    result = execute_query(insert_query, (record_id, session["session_id"], actual_student_id))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to mark attendance")
    
    return {
        "success": True,
        "message": "Attendance marked successfully",
        "record_id": record_id
    }

