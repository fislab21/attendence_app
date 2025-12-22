import mysql.connector
from mysql.connector import Error
import uuid

# Database configuration
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "Abdou2004!@#",
    "database": "student_attendence_db"
}

def create_db_connection():
    """Create and return a database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def get_db():
    """Get database connection (for dependency injection)"""
    conn = create_db_connection()
    try:
        yield conn
    finally:
        if conn and conn.is_connected():
            conn.close()

def generate_id():
    """Generate a UUID string"""
    return str(uuid.uuid4())

def execute_query(query, params=None, fetch_one=False, fetch_all=False):
    """Execute a SQL query and return results"""
    conn = create_db_connection()
    if not conn:
        return None
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params or ())
        
        if fetch_one:
            result = cursor.fetchone()
        elif fetch_all:
            result = cursor.fetchall()
        else:
            conn.commit()
            result = cursor.rowcount
        
        cursor.close()
        return result
    except Error as e:
        print(f"Error executing query: {e}")
        conn.rollback()
        return None
    finally:
        if conn and conn.is_connected():
            conn.close()