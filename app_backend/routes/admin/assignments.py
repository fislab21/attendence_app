from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import List
from datetime import datetime, timedelta
import random
import string

router = APIRouter(prefix="/admin", tags=["admin"])

class AssignCourseRequest(BaseModel):
    teacher_id: str
    course_ids: List[str]

def generate_attendance_code():
    """Generate a 6-character attendance code"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choice(chars) for _ in range(6))

@router.post("/assignments")
async def assign_courses_to_teacher(request: AssignCourseRequest):
    """Assign courses to a teacher and auto-create sessions"""
    # Get teacher_id from user_id
    teacher_query = "SELECT teacher_id FROM teachers WHERE user_id = %s"
    teacher = execute_query(teacher_query, (request.teacher_id,), fetch_one=True)
    
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    teacher_id = teacher["teacher_id"]
    
    # Delete existing assignments
    delete_query = "DELETE FROM teacher_courses WHERE teacher_id = %s"
    execute_query(delete_query, (teacher_id,))
    
    # Insert new assignments and create sessions
    for course_id in request.course_ids:
        assignment_id = generate_id()
        insert_query = """
            INSERT INTO teacher_courses (assignment_id, teacher_id, course_id, assigned_at)
            VALUES (%s, %s, %s, NOW())
        """
        execute_query(insert_query, (assignment_id, teacher_id, course_id))
        
        # Auto-create sessions for this course
        # Get all teachers to assign different time slots
        all_teachers_query = "SELECT COUNT(*) as count FROM teachers"
        result = execute_query(all_teachers_query, fetch_one=True)
        total_teachers = result["count"] if result else 1
        
        # Calculate teacher index for time slot assignment
        teachers_query = "SELECT teacher_id FROM teachers ORDER BY teacher_id"
        all_teachers = execute_query(teachers_query, fetch_all=True)
        teacher_index = 0
        for i, t in enumerate(all_teachers):
            if t["teacher_id"] == teacher_id:
                teacher_index = i
                break
        
        # Define time slots for different teachers to avoid conflicts
        # Each teacher gets a unique time slot
        time_slots = [
            (9, 0, "9:00 AM - 10:30 AM"),      # Teacher 0
            (11, 0, "11:00 AM - 12:30 PM"),    # Teacher 1
            (14, 0, "2:00 PM - 3:30 PM"),      # Teacher 2
            (16, 0, "4:00 PM - 5:30 PM"),      # Teacher 3
            (10, 0, "10:00 AM - 11:30 AM"),    # Teacher 4
            (12, 0, "12:00 PM - 1:30 PM"),     # Teacher 5
            (15, 0, "3:00 PM - 4:30 PM"),      # Teacher 6
            (17, 0, "5:00 PM - 6:30 PM"),      # Teacher 7
        ]
        
        # Get the time slot for this teacher
        teacher_slot = time_slots[teacher_index % len(time_slots)]
        base_hour, base_minute, _ = teacher_slot
        
        # Create one session per week for the next 4 weeks
        for week_offset in range(4):
            session_id = generate_id()
            # Schedule sessions on different weekdays (Mon, Wed, Fri, Mon)
            weekdays = [0, 2, 4, 0]  # 0=Monday, 2=Wednesday, 4=Friday
            days_to_add = (week_offset * 7) + weekdays[week_offset]
            session_date = datetime.now() + timedelta(days=days_to_add)
            
            # Create session at the teacher's assigned time
            session_datetime = datetime(
                session_date.year,
                session_date.month,
                session_date.day,
                base_hour, base_minute, 0
            )
            
            expiration_time = session_datetime + timedelta(hours=2)
            
            session_query = """
                INSERT INTO sessions (
                    session_id, teacher_id, course_id, start_time, 
                    expiration_time, status, room, time_slot
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            execute_query(session_query, (
                session_id,
                teacher_id,
                course_id,
                session_datetime,
                expiration_time,
                "scheduled",
                f"Room {week_offset + 1}",
                teacher_slot[2]
            ))
    
    return {
        "success": True,
        "message": f"{len(request.course_ids)} course(s) assigned successfully"
    }

@router.get("/assignments")
async def get_all_assignments():
    """Get all course assignments"""
    query = """
        SELECT 
            tc.assignment_id as id,
            tc.teacher_id,
            u.user_id as teacher_user_id,
            u.full_name as teacher_name,
            tc.course_id,
            c.course_name,
            c.course_code,
            tc.assigned_at
        FROM teacher_courses tc
        JOIN teachers t ON tc.teacher_id = t.teacher_id
        JOIN users u ON t.user_id = u.user_id
        JOIN courses c ON tc.course_id = c.course_id
        ORDER BY tc.assigned_at DESC
    """
    
    assignments = execute_query(query, fetch_all=True)
    
    if assignments is None:
        return []
    
    result = []
    for assignment in assignments:
        result.append({
            "id": assignment["id"],
            "teacherId": assignment["teacher_user_id"],
            "courseId": assignment["course_id"],
            "teacher_name": assignment["teacher_name"],
            "course_name": assignment["course_name"],
            "course_code": assignment["course_code"],
            "assigned_at": assignment["assigned_at"].isoformat() if assignment["assigned_at"] else None
        })
    
    return result

@router.get("/assignments/teacher/{teacher_id}")
async def get_teacher_assignments(teacher_id: str):
    """Get all assignments for a specific teacher"""
    # Get teacher_id from user_id
    teacher_query = "SELECT teacher_id FROM teachers WHERE user_id = %s"
    teacher = execute_query(teacher_query, (teacher_id,), fetch_one=True)
    
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    actual_teacher_id = teacher["teacher_id"]
    
    query = """
        SELECT 
            tc.assignment_id as id,
            tc.course_id,
            c.course_name,
            c.course_code,
            tc.assigned_at
        FROM teacher_courses tc
        JOIN courses c ON tc.course_id = c.course_id
        WHERE tc.teacher_id = %s
        ORDER BY tc.assigned_at DESC
    """
    
    assignments = execute_query(query, (actual_teacher_id,), fetch_all=True)
    
    if assignments is None:
        return []
    
    result = []
    for assignment in assignments:
        result.append({
            "id": assignment["id"],
            "course_id": assignment["course_id"],
            "course_name": assignment["course_name"],
            "course_code": assignment["course_code"],
            "assigned_at": assignment["assigned_at"].isoformat() if assignment["assigned_at"] else None
        })
    
    return result

@router.delete("/assignments/{assignment_id}")
async def delete_assignment(assignment_id: str):
    """Delete a course assignment and its sessions"""
    # First, get the course_id and teacher_id for this assignment
    get_assignment_query = "SELECT course_id, teacher_id FROM teacher_courses WHERE assignment_id = %s"
    assignment = execute_query(get_assignment_query, (assignment_id,), fetch_one=True)
    
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    
    # Delete all sessions for this teacher-course combination
    delete_sessions_query = """
        DELETE FROM sessions 
        WHERE teacher_id = %s AND course_id = %s
    """
    execute_query(delete_sessions_query, (assignment["teacher_id"], assignment["course_id"]))
    
    # Delete the assignment itself
    delete_query = "DELETE FROM teacher_courses WHERE assignment_id = %s"
    result = execute_query(delete_query, (assignment_id,))
    
    if not result or result <= 0:
        raise HTTPException(status_code=500, detail="Failed to delete assignment")
    
    return {"success": True, "message": "Assignment and sessions deleted successfully"}
