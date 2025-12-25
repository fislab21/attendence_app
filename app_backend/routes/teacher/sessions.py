from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from datetime import datetime, timedelta
from typing import List, Optional
import random
import string
from routes.admin.exclusion_checker import check_and_create_exclusion
from routes.admin.warning_checker import check_and_create_warning

router = APIRouter(prefix="/teacher", tags=["teacher"])

class CreateSessionRequest(BaseModel):
    course_id: str
    teacher_id: str
    date: str
    room: Optional[str] = None
    time_slot: Optional[str] = None

class StartSessionRequest(BaseModel):
    session_id: str

class CloseSessionRequest(BaseModel):
    session_id: str

def generate_attendance_code():
    """Generate a 6-character attendance code"""
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choice(chars) for _ in range(6))

@router.post("/sessions")
async def create_session(request: CreateSessionRequest):
    """Create a new session"""
    # Get teacher_id from user_id
    teacher_query = "SELECT teacher_id FROM teachers WHERE user_id = %s"
    teacher = execute_query(teacher_query, (request.teacher_id,), fetch_one=True)
    
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    # Check if teacher is assigned to this course
    assignment_query = """
        SELECT assignment_id FROM teacher_courses
        WHERE teacher_id = %s AND course_id = %s
    """
    assignment = execute_query(assignment_query, (teacher["teacher_id"], request.course_id), fetch_one=True)
    
    if not assignment:
        raise HTTPException(status_code=403, detail="Teacher not assigned to this course")
    
    session_id = generate_id()
    code = generate_attendance_code()
    
    # Parse date
    try:
        session_date = datetime.fromisoformat(request.date.replace('Z', '+00:00'))
    except:
        session_date = datetime.now()
    
    insert_query = """
        INSERT INTO sessions 
        (session_id, course_id, teacher_id, attendance_code, start_time, expiration_time, status, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, 'Active', NOW())
    """
    
    expiration_time = session_date + timedelta(hours=2)
    
    result = execute_query(
        insert_query,
        (session_id, request.course_id, teacher["teacher_id"], code, session_date, expiration_time)
    )
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to create session")
    
    return {
        "success": True,
        "session_id": session_id,
        "code": code,
        "expires_at": expiration_time.isoformat()
    }

@router.post("/sessions/start")
async def start_session(request: StartSessionRequest):
    """Start a session and generate attendance code"""
    # Get session
    query = """
        SELECT session_id, course_id, teacher_id, status, expiration_time
        FROM sessions
        WHERE session_id = %s
    """
    session = execute_query(query, (request.session_id,), fetch_one=True)
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    if session["status"] == "Completed":
        raise HTTPException(status_code=400, detail="Session already completed")
    
    code = generate_attendance_code()
    expiration_time = datetime.now() + timedelta(hours=2)
    
    update_query = """
        UPDATE sessions
        SET attendance_code = %s, expiration_time = %s, status = 'Active'
        WHERE session_id = %s
    """
    
    result = execute_query(update_query, (code, expiration_time, request.session_id))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to start session")
    
    return {
        "success": True,
        "code": code,
        "expires_at": expiration_time.isoformat()
    }

@router.post("/sessions/close")
async def close_session(request: CloseSessionRequest):
    """Close a session"""
    update_query = """
        UPDATE sessions
        SET status = 'Completed'
        WHERE session_id = %s
    """
    
    result = execute_query(update_query, (request.session_id,))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to close session")
    
    return {"success": True, "message": "Session closed successfully"}

@router.get("/sessions/{teacher_id}")
async def get_teacher_sessions(teacher_id: str):
    """Get all sessions for a teacher"""
    # Get teacher_id from user_id
    teacher_query = "SELECT teacher_id FROM teachers WHERE user_id = %s"
    teacher = execute_query(teacher_query, (teacher_id,), fetch_one=True)
    
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    query = """
        SELECT 
            s.session_id as id,
            s.course_id,
            c.course_name as course,
            c.course_code,
            s.start_time as date,
            s.room,
            s.time_slot as time,
            s.attendance_code as code,
            s.expiration_time as expiresAt,
            s.status
        FROM sessions s
        JOIN courses c ON s.course_id = c.course_id
        WHERE s.teacher_id = %s
        ORDER BY s.start_time DESC
    """
    
    sessions = execute_query(query, (teacher["teacher_id"],), fetch_all=True)
    
    if sessions is None:
        return []
    
    # Convert to lowercase status
    status_map = {
        "Active": "active",
        "Expired": "completed",
        "Completed": "completed"
    }
    
    result = []
    for session in sessions:
        result.append({
            "id": session["id"],
            "course_id": session["course_id"],
            "course": session["course"],
            "course_code": session["course_code"],
            "date": session["date"].isoformat() if session["date"] else None,
            "room": session["room"],
            "time": session["time"],
            "code": session["code"],
            "expiresAt": session["expiresAt"].isoformat() if session["expiresAt"] else None,
            "status": status_map.get(session["status"], "scheduled")
        })
    
    return result

@router.get("/sessions/{session_id}/attendance")
async def get_session_attendance(session_id: str):
    """Get attendance list for a session"""
    # Get session info
    session_query = """
        SELECT s.session_id, c.course_name, c.course_code
        FROM sessions s
        JOIN courses c ON s.course_id = c.course_id
        WHERE s.session_id = %s
    """
    session = execute_query(session_query, (session_id,), fetch_one=True)
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Get all students enrolled in the course
    students_query = """
        SELECT 
            st.student_id,
            u.user_id,
            u.full_name as name,
            u.email
        FROM course_students cs
        JOIN students st ON cs.student_id = st.student_id
        JOIN users u ON st.user_id = u.user_id
        WHERE cs.course_id = (
            SELECT course_id FROM sessions WHERE session_id = %s
        )
    """
    students = execute_query(students_query, (session_id,), fetch_all=True) or []
    
    # Get attendance records
    attendance_query = """
        SELECT 
            ar.student_id,
            ar.attendance_status as status,
            ar.absence_type
        FROM attendance_records ar
        WHERE ar.session_id = %s
    """
    attendance_records = execute_query(attendance_query, (session_id,), fetch_all=True) or []
    
    # Create a map of student_id to attendance status
    attendance_map = {}
    for record in attendance_records:
        attendance_map[record["student_id"]] = {
            "status": record["status"].lower() if record["status"] else "absent",
            "absence_type": record["absence_type"] or "none"
        }
    
    # Build result
    result = []
    for student in students:
        student_id = student["student_id"]
        attendance = attendance_map.get(student_id, {"status": "absent", "absence_type": "none"})
        
        result.append({
            "id": student_id,
            "name": student["name"],
            "email": student["email"],
            "status": attendance["status"],
            "absence_type": attendance["absence_type"]
        })
    
    return {
        "session": {
            "id": session["session_id"],
            "course": session["course_name"],
            "course_code": session["course_code"]
        },
        "students": result
    }

@router.put("/sessions/{session_id}/attendance/{student_id}")
async def update_attendance_status(session_id: str, student_id: str, absence_type: str):
    """Update absence type for a student"""
    # Get session to find course_id
    session_query = "SELECT course_id FROM sessions WHERE session_id = %s"
    session = execute_query(session_query, (session_id,), fetch_one=True)
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    course_id = session["course_id"]
    
    # Map UI absence_type to database values
    status_map = {
        "justified": "Justified",
        "unjustified": "Unjustified",
        "none": "Absent"
    }
    
    db_status = status_map.get(absence_type.lower(), "Absent")
    
    # Check if record exists
    check_query = """
        SELECT record_id FROM attendance_records
        WHERE session_id = %s AND student_id = %s
    """
    existing = execute_query(check_query, (session_id, student_id), fetch_one=True)
    
    if existing:
        # Update existing record
        update_query = """
            UPDATE attendance_records
            SET attendance_status = %s, absence_type = %s, last_modified = NOW()
            WHERE record_id = %s
        """
        result = execute_query(update_query, (db_status, absence_type, existing["record_id"]))
    else:
        # Create new record
        record_id = generate_id()
        insert_query = """
            INSERT INTO attendance_records
            (record_id, session_id, student_id, attendance_status, absence_type, submission_time)
            VALUES (%s, %s, %s, %s, %s, NOW())
        """
        result = execute_query(insert_query, (record_id, session_id, student_id, db_status, absence_type))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to update attendance")
    
    # Automatically check and create warnings/exclusions (only if absence was marked)
    warning_info = None
    exclusion_info = None
    
    if absence_type.lower() in ["justified", "unjustified", "none"]:
        # First check for warnings (lower threshold)
        warning_info = check_and_create_warning(student_id, course_id)
        
        # Then check for exclusions (higher threshold)
        exclusion_info = check_and_create_exclusion(student_id, course_id)
    
    response = {
        "success": True,
        "message": "Attendance status updated"
    }
    
    # Add warning info if created
    if warning_info and warning_info.get("warning_created"):
        response["warning_created"] = True
        response["warning_message"] = warning_info.get("message")
        response["message"] = "Attendance status updated. Warning issued to student."
    
    # Add exclusion info if created (exclusion takes priority)
    if exclusion_info and exclusion_info.get("exclusion_created"):
        response["exclusion_created"] = True
        response["exclusion_reason"] = exclusion_info.get("reason")
        response["message"] = "Attendance status updated. Student has been excluded from this course."
        # Clear warning message if exclusion was created
        if "warning_created" in response:
            response.pop("warning_created")
            response.pop("warning_message")
    
    return response


@router.get("/courses/{teacher_id}")
async def get_teacher_courses(teacher_id: str):
    """Get all courses assigned to a teacher"""
    # Get teacher_id from user_id
    teacher_query = "SELECT teacher_id FROM teachers WHERE user_id = %s"
    teacher = execute_query(teacher_query, (teacher_id,), fetch_one=True)
    
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    
    query = """
        SELECT 
            c.course_id,
            c.course_name,
            c.course_code
        FROM courses c
        JOIN teacher_courses tc ON c.course_id = tc.course_id
        WHERE tc.teacher_id = %s
        ORDER BY c.course_name
    """
    
    courses = execute_query(query, (teacher["teacher_id"],), fetch_all=True)
    
    if courses is None:
        return []
    
    result = []
    for course in courses:
        result.append({
            "course_id": course["course_id"],
            "course": course["course_name"],
            "course_code": course["course_code"],
        })
    
    return result

