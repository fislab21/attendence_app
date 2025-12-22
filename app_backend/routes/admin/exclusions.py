from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import Optional, List

router = APIRouter(prefix="/admin", tags=["admin"])

class CreateExclusionRequest(BaseModel):
    student_id: str
    course_id: str
    absence_count: int
    exclusion_reason: Optional[str] = None

class UpdateExclusionRequest(BaseModel):
    is_active: Optional[bool] = None
    exclusion_reason: Optional[str] = None

@router.post("/exclusions")
async def create_exclusion(request: CreateExclusionRequest):
    """Create an exclusion for a student"""
    # Get student_id from user_id
    student_query = "SELECT student_id FROM students WHERE user_id = %s"
    student = execute_query(student_query, (request.student_id,), fetch_one=True)
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    actual_student_id = student["student_id"]
    
    # Check if course exists
    course_query = "SELECT course_id FROM courses WHERE course_id = %s"
    course = execute_query(course_query, (request.course_id,), fetch_one=True)
    
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    exclusion_id = generate_id()
    
    insert_query = """
        INSERT INTO exclusions (exclusion_id, student_id, course_id, absence_count, exclusion_reason, is_active)
        VALUES (%s, %s, %s, %s, %s, TRUE)
    """
    
    result = execute_query(insert_query, (exclusion_id, actual_student_id, request.course_id, request.absence_count, request.exclusion_reason))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to create exclusion")
    
    return {
        "success": True,
        "exclusion_id": exclusion_id,
        "message": "Exclusion created successfully"
    }

@router.get("/exclusions")
async def get_all_exclusions(student_id: Optional[str] = None, course_id: Optional[str] = None, active_only: bool = False):
    """Get all exclusions, optionally filtered by student or course"""
    query = """
        SELECT 
            e.exclusion_id as id,
            e.student_id,
            u.user_id as student_user_id,
            u.full_name as student_name,
            e.course_id,
            c.course_name,
            c.course_code,
            e.absence_count,
            e.exclusion_reason,
            e.is_active,
            e.issue_date
        FROM exclusions e
        JOIN students st ON e.student_id = st.student_id
        JOIN users u ON st.user_id = u.user_id
        JOIN courses c ON e.course_id = c.course_id
        WHERE 1=1
    """
    params = []
    
    if student_id:
        query += " AND u.user_id = %s"
        params.append(student_id)
    
    if course_id:
        query += " AND e.course_id = %s"
        params.append(course_id)
    
    if active_only:
        query += " AND e.is_active = TRUE"
    
    query += " ORDER BY e.issue_date DESC"
    
    exclusions = execute_query(query, tuple(params) if params else None, fetch_all=True)
    
    if exclusions is None:
        return []
    
    result = []
    for exclusion in exclusions:
        result.append({
            "id": exclusion["id"],
            "student_id": exclusion["student_user_id"],
            "student_name": exclusion["student_name"],
            "course_id": exclusion["course_id"],
            "course_name": exclusion["course_name"],
            "course_code": exclusion["course_code"],
            "absence_count": exclusion["absence_count"],
            "exclusion_reason": exclusion["exclusion_reason"],
            "is_active": exclusion["is_active"],
            "issue_date": exclusion["issue_date"].isoformat() if exclusion["issue_date"] else None
        })
    
    return result

@router.get("/exclusions/{exclusion_id}")
async def get_exclusion(exclusion_id: str):
    """Get a specific exclusion by ID"""
    query = """
        SELECT 
            e.exclusion_id as id,
            e.student_id,
            u.user_id as student_user_id,
            u.full_name as student_name,
            e.course_id,
            c.course_name,
            c.course_code,
            e.absence_count,
            e.exclusion_reason,
            e.is_active,
            e.issue_date
        FROM exclusions e
        JOIN students st ON e.student_id = st.student_id
        JOIN users u ON st.user_id = u.user_id
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.exclusion_id = %s
    """
    
    exclusion = execute_query(query, (exclusion_id,), fetch_one=True)
    
    if not exclusion:
        raise HTTPException(status_code=404, detail="Exclusion not found")
    
    return {
        "id": exclusion["id"],
        "student_id": exclusion["student_user_id"],
        "student_name": exclusion["student_name"],
        "course_id": exclusion["course_id"],
        "course_name": exclusion["course_name"],
        "course_code": exclusion["course_code"],
        "absence_count": exclusion["absence_count"],
        "exclusion_reason": exclusion["exclusion_reason"],
        "is_active": exclusion["is_active"],
        "issue_date": exclusion["issue_date"].isoformat() if exclusion["issue_date"] else None
    }

@router.put("/exclusions/{exclusion_id}")
async def update_exclusion(exclusion_id: str, request: UpdateExclusionRequest):
    """Update an exclusion"""
    # Check if exclusion exists
    check_query = "SELECT exclusion_id FROM exclusions WHERE exclusion_id = %s"
    exclusion = execute_query(check_query, (exclusion_id,), fetch_one=True)
    
    if not exclusion:
        raise HTTPException(status_code=404, detail="Exclusion not found")
    
    # Build update query dynamically
    updates = []
    params = []
    
    if request.is_active is not None:
        updates.append("is_active = %s")
        params.append(request.is_active)
    
    if request.exclusion_reason is not None:
        updates.append("exclusion_reason = %s")
        params.append(request.exclusion_reason)
    
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    params.append(exclusion_id)
    update_query = f"UPDATE exclusions SET {', '.join(updates)} WHERE exclusion_id = %s"
    
    result = execute_query(update_query, tuple(params))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to update exclusion")
    
    return {"success": True, "message": "Exclusion updated successfully"}

@router.delete("/exclusions/{exclusion_id}")
async def delete_exclusion(exclusion_id: str):
    """Delete an exclusion"""
    delete_query = "DELETE FROM exclusions WHERE exclusion_id = %s"
    result = execute_query(delete_query, (exclusion_id,))
    
    if result is None or result == 0:
        raise HTTPException(status_code=404, detail="Exclusion not found")
    
    return {"success": True, "message": "Exclusion deleted successfully"}

