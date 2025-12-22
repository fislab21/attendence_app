from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import Optional, List

router = APIRouter(prefix="/admin", tags=["admin"])

class CreateWarningRequest(BaseModel):
    student_id: str
    course_id: str
    absence_count: int
    warning_message: Optional[str] = None

class UpdateWarningRequest(BaseModel):
    is_active: Optional[bool] = None
    warning_message: Optional[str] = None

@router.post("/warnings")
async def create_warning(request: CreateWarningRequest):
    """Create a warning for a student"""
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
    
    warning_id = generate_id()
    
    insert_query = """
        INSERT INTO warnings (warning_id, student_id, course_id, absence_count, warning_message, is_active)
        VALUES (%s, %s, %s, %s, %s, TRUE)
    """
    
    result = execute_query(insert_query, (warning_id, actual_student_id, request.course_id, request.absence_count, request.warning_message))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to create warning")
    
    return {
        "success": True,
        "warning_id": warning_id,
        "message": "Warning created successfully"
    }

@router.get("/warnings")
async def get_all_warnings(student_id: Optional[str] = None, course_id: Optional[str] = None, active_only: bool = False):
    """Get all warnings, optionally filtered by student or course"""
    query = """
        SELECT 
            w.warning_id as id,
            w.student_id,
            u.user_id as student_user_id,
            u.full_name as student_name,
            w.course_id,
            c.course_name,
            c.course_code,
            w.absence_count,
            w.warning_message,
            w.is_active,
            w.issue_date
        FROM warnings w
        JOIN students st ON w.student_id = st.student_id
        JOIN users u ON st.user_id = u.user_id
        JOIN courses c ON w.course_id = c.course_id
        WHERE 1=1
    """
    params = []
    
    if student_id:
        query += " AND u.user_id = %s"
        params.append(student_id)
    
    if course_id:
        query += " AND w.course_id = %s"
        params.append(course_id)
    
    if active_only:
        query += " AND w.is_active = TRUE"
    
    query += " ORDER BY w.issue_date DESC"
    
    warnings = execute_query(query, tuple(params) if params else None, fetch_all=True)
    
    if warnings is None:
        return []
    
    result = []
    for warning in warnings:
        result.append({
            "id": warning["id"],
            "student_id": warning["student_user_id"],
            "student_name": warning["student_name"],
            "course_id": warning["course_id"],
            "course_name": warning["course_name"],
            "course_code": warning["course_code"],
            "absence_count": warning["absence_count"],
            "warning_message": warning["warning_message"],
            "is_active": warning["is_active"],
            "issue_date": warning["issue_date"].isoformat() if warning["issue_date"] else None
        })
    
    return result

@router.get("/warnings/{warning_id}")
async def get_warning(warning_id: str):
    """Get a specific warning by ID"""
    query = """
        SELECT 
            w.warning_id as id,
            w.student_id,
            u.user_id as student_user_id,
            u.full_name as student_name,
            w.course_id,
            c.course_name,
            c.course_code,
            w.absence_count,
            w.warning_message,
            w.is_active,
            w.issue_date
        FROM warnings w
        JOIN students st ON w.student_id = st.student_id
        JOIN users u ON st.user_id = u.user_id
        JOIN courses c ON w.course_id = c.course_id
        WHERE w.warning_id = %s
    """
    
    warning = execute_query(query, (warning_id,), fetch_one=True)
    
    if not warning:
        raise HTTPException(status_code=404, detail="Warning not found")
    
    return {
        "id": warning["id"],
        "student_id": warning["student_user_id"],
        "student_name": warning["student_name"],
        "course_id": warning["course_id"],
        "course_name": warning["course_name"],
        "course_code": warning["course_code"],
        "absence_count": warning["absence_count"],
        "warning_message": warning["warning_message"],
        "is_active": warning["is_active"],
        "issue_date": warning["issue_date"].isoformat() if warning["issue_date"] else None
    }

@router.put("/warnings/{warning_id}")
async def update_warning(warning_id: str, request: UpdateWarningRequest):
    """Update a warning"""
    # Check if warning exists
    check_query = "SELECT warning_id FROM warnings WHERE warning_id = %s"
    warning = execute_query(check_query, (warning_id,), fetch_one=True)
    
    if not warning:
        raise HTTPException(status_code=404, detail="Warning not found")
    
    # Build update query dynamically
    updates = []
    params = []
    
    if request.is_active is not None:
        updates.append("is_active = %s")
        params.append(request.is_active)
    
    if request.warning_message is not None:
        updates.append("warning_message = %s")
        params.append(request.warning_message)
    
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    params.append(warning_id)
    update_query = f"UPDATE warnings SET {', '.join(updates)} WHERE warning_id = %s"
    
    result = execute_query(update_query, tuple(params))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to update warning")
    
    return {"success": True, "message": "Warning updated successfully"}

@router.delete("/warnings/{warning_id}")
async def delete_warning(warning_id: str):
    """Delete a warning"""
    delete_query = "DELETE FROM warnings WHERE warning_id = %s"
    result = execute_query(delete_query, (warning_id,))
    
    if result is None or result == 0:
        raise HTTPException(status_code=404, detail="Warning not found")
    
    return {"success": True, "message": "Warning deleted successfully"}

