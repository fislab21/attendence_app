from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query
from typing import List, Optional

router = APIRouter(tags=["student"])

class AttendanceRecord(BaseModel):
    id: str
    session_id: str
    course_name: str
    course_code: str
    date: str
    status: str
    recorded_at: str

@router.get("/student/attendance-records/{student_id}")
async def get_attendance_records(student_id: str):
    """Get all attendance records for a student"""
    query = """
        SELECT 
            ar.record_id as id,
            ar.session_id,
            c.course_name,
            c.course_code,
            s.start_time as date,
            ar.attendance_status as status,
            ar.submission_time as recorded_at
        FROM attendance_records ar
        JOIN sessions s ON ar.session_id = s.session_id
        JOIN courses c ON s.course_id = c.course_id
        JOIN students st ON ar.student_id = st.student_id
        WHERE st.user_id = %s
        ORDER BY s.start_time DESC
    """
    
    records = execute_query(query, (student_id,), fetch_all=True)
    
    if records is None:
        raise HTTPException(status_code=500, detail="Failed to fetch attendance records")
    
    # Convert to lowercase status for UI
    status_map = {
        "Present": "present",
        "Absent": "unjustified",
        "Justified": "justified",
        "Unjustified": "unjustified"
    }
    
    result = []
    for record in records:
        result.append({
            "id": record["id"],
            "session_id": record["session_id"],
            "course_name": record["course_name"],
            "course_code": record["course_code"],
            "date": record["date"].isoformat() if record["date"] else None,
            "status": status_map.get(record["status"], "present"),
            "recorded_at": record["recorded_at"].isoformat() if record["recorded_at"] else None
        })
    
    return result

@router.get("/student/stats/{student_id}")
async def get_student_stats(student_id: str, course_id: Optional[str] = None):
    """Get student attendance statistics"""
    # Get student_id from user_id
    student_query = "SELECT student_id FROM students WHERE user_id = %s"
    student = execute_query(student_query, (student_id,), fetch_one=True)
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    actual_student_id = student["student_id"]
    
    if course_id:
        # Stats for specific course
        query = """
            SELECT 
                COUNT(CASE WHEN ar.attendance_status = 'Present' THEN 1 END) as present_count,
                COUNT(CASE WHEN ar.attendance_status = 'Justified' THEN 1 END) as justified_count,
                COUNT(CASE WHEN ar.attendance_status = 'Unjustified' THEN 1 END) as unjustified_count,
                COUNT(CASE WHEN ar.attendance_status = 'Absent' THEN 1 END) as absent_count
            FROM attendance_records ar
            JOIN sessions s ON ar.session_id = s.session_id
            WHERE ar.student_id = %s AND s.course_id = %s
        """
        stats = execute_query(query, (actual_student_id, course_id), fetch_one=True)
    else:
        # Overall stats
        query = """
            SELECT 
                COUNT(CASE WHEN ar.attendance_status = 'Present' THEN 1 END) as present_count,
                COUNT(CASE WHEN ar.attendance_status = 'Justified' THEN 1 END) as justified_count,
                COUNT(CASE WHEN ar.attendance_status = 'Unjustified' THEN 1 END) as unjustified_count,
                COUNT(CASE WHEN ar.attendance_status = 'Absent' THEN 1 END) as absent_count
            FROM attendance_records ar
            WHERE ar.student_id = %s
        """
        stats = execute_query(query, (actual_student_id,), fetch_one=True)
    
    if stats is None:
        stats = {
            "present_count": 0,
            "justified_count": 0,
            "unjustified_count": 0,
            "absent_count": 0
        }
    
    # Check for warnings and exclusions
    warning_query = """
        SELECT COUNT(*) as warning_count
        FROM warnings
        WHERE student_id = %s AND is_active = TRUE
    """
    warnings = execute_query(warning_query, (actual_student_id,), fetch_one=True)
    
    exclusion_query = """
        SELECT COUNT(*) as exclusion_count
        FROM exclusions
        WHERE student_id = %s AND is_active = TRUE
    """
    exclusions = execute_query(exclusion_query, (actual_student_id,), fetch_one=True)
    
    return {
        "student_id": student_id,
        "course_id": course_id,
        "sessions_attended": stats.get("present_count", 0),
        "total_absences": stats.get("justified_count", 0) + stats.get("unjustified_count", 0) + stats.get("absent_count", 0),
        "justified_absences": stats.get("justified_count", 0),
        "unjustified_absences": stats.get("unjustified_count", 0) + stats.get("absent_count", 0),
        "warning_count": warnings.get("warning_count", 0) if warnings else 0,
        "is_excluded": exclusions.get("exclusion_count", 0) > 0 if exclusions else False
    }

