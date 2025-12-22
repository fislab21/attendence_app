"""
Helper functions to automatically check and create warnings based on absence counts
"""
from connection import execute_query, generate_id

def check_and_create_warning(student_id: str, course_id: str):
    """
    Check if student meets warning criteria and create warning if needed.
    Conditions: 2 unjustified absences OR 3 justified absences
    """
    # Count absences for this student in this course
    query = """
        SELECT 
            COUNT(CASE WHEN ar.attendance_status = 'Unjustified' OR ar.attendance_status = 'Absent' THEN 1 END) as unjustified_count,
            COUNT(CASE WHEN ar.attendance_status = 'Justified' THEN 1 END) as justified_count
        FROM attendance_records ar
        JOIN sessions s ON ar.session_id = s.session_id
        WHERE ar.student_id = %s AND s.course_id = %s
    """
    
    counts = execute_query(query, (student_id, course_id), fetch_one=True)
    
    if not counts:
        return None
    
    unjustified_count = counts.get("unjustified_count", 0) or 0
    justified_count = counts.get("justified_count", 0) or 0
    
    # Check if warning criteria is met (lower threshold than exclusion)
    should_warn = False
    warning_message = ""
    
    if unjustified_count >= 2:
        should_warn = True
        warning_message = f"Student has {unjustified_count} unjustified absences (warning threshold: 2). Risk of exclusion at 3 absences."
    elif justified_count >= 3:
        should_warn = True
        warning_message = f"Student has {justified_count} justified absences (warning threshold: 3). Risk of exclusion at 5 absences."
    
    # Check if warning already exists
    if should_warn:
        check_existing = """
            SELECT warning_id FROM warnings
            WHERE student_id = %s AND course_id = %s AND is_active = TRUE
        """
        existing = execute_query(check_existing, (student_id, course_id), fetch_one=True)
        
        if not existing:
            # Create warning
            warning_id = generate_id()
            total_absences = unjustified_count + justified_count
            
            insert_query = """
                INSERT INTO warnings 
                (warning_id, student_id, course_id, absence_count, warning_message, is_active)
                VALUES (%s, %s, %s, %s, %s, TRUE)
            """
            
            result = execute_query(insert_query, (warning_id, student_id, course_id, total_absences, warning_message))
            
            if result is not None:
                return {
                    "warning_created": True,
                    "warning_id": warning_id,
                    "message": warning_message
                }
    
    return None

