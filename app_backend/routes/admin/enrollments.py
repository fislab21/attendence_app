from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import List

router = APIRouter(tags=["admin"])

class EnrollStudentRequest(BaseModel):
    student_id: str
    course_ids: List[str]

@router.post("/admin/enrollments")
async def enroll_student_in_courses(request: EnrollStudentRequest):
    """Enroll a student in courses"""
    # Get student_id from user_id
    student_query = "SELECT student_id FROM students WHERE user_id = %s"
    student = execute_query(student_query, (request.student_id,), fetch_one=True)
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    actual_student_id = student["student_id"]
    
    # Enroll in each course
    enrolled_count = 0
    for course_id in request.course_ids:
        # Check if already enrolled
        check_query = """
            SELECT enrollment_id FROM course_students
            WHERE student_id = %s AND course_id = %s
        """
        existing = execute_query(check_query, (actual_student_id, course_id), fetch_one=True)
        
        if not existing:
            enrollment_id = generate_id()
            insert_query = """
                INSERT INTO course_students (enrollment_id, student_id, course_id, enrolled_at)
                VALUES (%s, %s, %s, NOW())
            """
            result = execute_query(insert_query, (enrollment_id, actual_student_id, course_id))
            if result is not None:
                enrolled_count += 1
    
    return {
        "success": True,
        "message": f"Student enrolled in {enrolled_count} course(s)"
    }

@router.get("/admin/enrollments/{student_id}")
async def get_student_enrollments(student_id: str):
    """Get all courses a student is enrolled in"""
    # Get student_id from user_id
    student_query = "SELECT student_id FROM students WHERE user_id = %s"
    student = execute_query(student_query, (student_id,), fetch_one=True)
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    actual_student_id = student["student_id"]
    
    query = """
        SELECT 
            cs.enrollment_id,
            cs.course_id,
            c.course_name,
            c.course_code,
            cs.enrolled_at
        FROM course_students cs
        JOIN courses c ON cs.course_id = c.course_id
        WHERE cs.student_id = %s
        ORDER BY cs.enrolled_at DESC
    """
    
    enrollments = execute_query(query, (actual_student_id,), fetch_all=True)
    
    if enrollments is None:
        return []
    
    result = []
    for enrollment in enrollments:
        result.append({
            "enrollment_id": enrollment["enrollment_id"],
            "course_id": enrollment["course_id"],
            "course_name": enrollment["course_name"],
            "course_code": enrollment["course_code"],
            "enrolled_at": enrollment["enrolled_at"].isoformat() if enrollment["enrolled_at"] else None
        })
    
    return result

@router.delete("/admin/enrollments/{enrollment_id}")
async def remove_enrollment(enrollment_id: str):
    """Remove a student enrollment"""
    delete_query = "DELETE FROM course_students WHERE enrollment_id = %s"
    result = execute_query(delete_query, (enrollment_id,))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to remove enrollment")
    
    return {"success": True, "message": "Enrollment removed successfully"}

