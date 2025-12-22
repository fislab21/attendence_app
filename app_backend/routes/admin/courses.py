from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import Optional

router = APIRouter(prefix="/admin", tags=["admin"])

class CreateCourseRequest(BaseModel):
    course_name: str
    course_code: str
    department: Optional[str] = None

@router.post("/courses")
async def create_course(request: CreateCourseRequest):
    """Create a new course"""
    # Check if course code exists
    check_query = "SELECT course_id FROM courses WHERE course_code = %s"
    existing = execute_query(check_query, (request.course_code,), fetch_one=True)
    
    if existing:
        raise HTTPException(status_code=400, detail="Course code already exists")
    
    course_id = generate_id()
    
    insert_query = """
        INSERT INTO courses (course_id, course_name, course_code, created_at)
        VALUES (%s, %s, %s, NOW())
    """
    
    result = execute_query(insert_query, (course_id, request.course_name, request.course_code))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to create course")
    
    return {
        "success": True,
        "course_id": course_id,
        "message": "Course created successfully"
    }

@router.get("/courses")
async def get_all_courses():
    """Get all courses"""
    query = """
        SELECT 
            course_id as id,
            course_name as name,
            course_code as code,
            created_at
        FROM courses
        ORDER BY course_name
    """
    
    courses = execute_query(query, fetch_all=True)
    
    if courses is None:
        return []
    
    result = []
    for course in courses:
        result.append({
            "id": course["id"],
            "name": course["name"],
            "code": course["code"],
            "created_at": course["created_at"].isoformat() if course["created_at"] else None
        })
    
    return result

@router.get("/courses/{course_id}")
async def get_course(course_id: str):
    """Get a specific course by ID"""
    query = """
        SELECT 
            course_id as id,
            course_name as name,
            course_code as code,
            created_at
        FROM courses
        WHERE course_id = %s
    """
    
    course = execute_query(query, (course_id,), fetch_one=True)
    
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return {
        "id": course["id"],
        "name": course["name"],
        "code": course["code"],
        "created_at": course["created_at"].isoformat() if course["created_at"] else None
    }

@router.delete("/courses/{course_id}")
async def delete_course(course_id: str):
    """Delete a course"""
    delete_query = "DELETE FROM courses WHERE course_id = %s"
    result = execute_query(delete_query, (course_id,))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to delete course")
    
    return {"success": True, "message": "Course deleted successfully"}
