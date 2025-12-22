"""
Helper functions to automatically check and create exclusions based on absence counts
"""
from connection import execute_query, generate_id

def check_and_create_exclusion(student_id: str, course_id: str):
    """
    Check if student meets exclusion criteria and create exclusion if needed.
    Conditions: 3 unjustified absences OR 5 justified absences
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
    
    # Check if exclusion criteria is met
    should_exclude = False
    exclusion_reason = ""
    
    if unjustified_count >= 3:
        should_exclude = True
        exclusion_reason = f"Student has {unjustified_count} unjustified absences (threshold: 3)"
    elif justified_count >= 5:
        should_exclude = True
        exclusion_reason = f"Student has {justified_count} justified absences (threshold: 5)"
    
    # Check if exclusion already exists
    if should_exclude:
        check_existing = """
            SELECT exclusion_id FROM exclusions
            WHERE student_id = %s AND course_id = %s AND is_active = TRUE
        """
        existing = execute_query(check_existing, (student_id, course_id), fetch_one=True)
        
        if not existing:
            # Create exclusion
            exclusion_id = generate_id()
            total_absences = unjustified_count + justified_count
            
            insert_query = """
                INSERT INTO exclusions 
                (exclusion_id, student_id, course_id, absence_count, exclusion_reason, is_active)
                VALUES (%s, %s, %s, %s, %s, TRUE)
            """
            
            result = execute_query(insert_query, (exclusion_id, student_id, course_id, total_absences, exclusion_reason))
            
            if result is not None:
                return {
                    "exclusion_created": True,
                    "exclusion_id": exclusion_id,
                    "reason": exclusion_reason
                }
    
    return None

