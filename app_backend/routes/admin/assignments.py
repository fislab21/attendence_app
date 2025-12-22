from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import List

router = APIRouter(prefix="/admin", tags=["admin"])

class AssignCourseRequest(BaseModel):
    teacher_id: str
    course_ids: List[str]

@router.post("/assignments")
async def assign_courses_to_teacher(request: AssignCourseRequest):
    """Assign courses to a teacher"""
    # Get teacher_id from user_id
    teacher_query = "SELECT teacher_id FROM teachers WHERE user_id = %s"
    teacher = execute_query(teacher_query, (request.teacher_id,), fetch_one=True)
    
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    teacher_id = teacher["teacher_id"]
    
    # Delete existing assignments
    delete_query = "DELETE FROM teacher_courses WHERE teacher_id = %s"
    execute_query(delete_query, (teacher_id,))
    
    # Insert new assignments
    for course_id in request.course_ids:
        assignment_id = generate_id()
        insert_query = """
            INSERT INTO teacher_courses (assignment_id, teacher_id, course_id, assigned_at)
            VALUES (%s, %s, %s, NOW())
        """
        execute_query(insert_query, (assignment_id, teacher_id, course_id))
    
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
    """Delete a course assignment"""
    delete_query = "DELETE FROM teacher_courses WHERE assignment_id = %s"
    result = execute_query(delete_query, (assignment_id,))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to delete assignment")
    
    return {"success": True, "message": "Assignment deleted successfully"}
