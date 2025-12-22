from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query
import hashlib
from datetime import datetime, timedelta

router = APIRouter(prefix="/auth", tags=["auth"])

class LoginRequest(BaseModel):
    username: str
    password: str
    role: str  # student, teacher, admin

class LoginResponse(BaseModel):
    id: str
    username: str
    name: str
    email: str
    role: str

@router.post("/login")
async def login(request: LoginRequest):
    """Login endpoint with 3 attempt limit"""
    # Hash password (simple MD5 for demo - use bcrypt in production)
    password_hash = hashlib.md5(request.password.encode()).hexdigest()
    
    # Map UI role to database role
    role_map = {
        "student": "Student",
        "teacher": "Teacher",
        "admin": "Admin"
    }
    db_role = role_map.get(request.role.lower(), "Student")
    
    # First, check if user exists and get their login attempt info
    user_check_query = """
        SELECT u.user_id, u.username, u.password, u.full_name, u.email, u.user_type, 
               u.account_status, u.failed_login_attempts, u.account_locked_until
        FROM users u
        WHERE u.username = %s AND u.user_type = %s
    """
    
    user = execute_query(user_check_query, (request.username, db_role), fetch_one=True)
    
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Check if account is locked using SQL comparison
    if user.get("account_locked_until"):
        # Check if lock is still active using SQL
        check_lock_query = """
            SELECT account_locked_until 
            FROM users 
            WHERE user_id = %s AND account_locked_until > NOW()
        """
        still_locked = execute_query(check_lock_query, (user["user_id"],), fetch_one=True)
        
        if still_locked:
            # Calculate remaining time
            lock_time = user["account_locked_until"]
            if isinstance(lock_time, datetime):
                remaining_seconds = (lock_time - datetime.now()).total_seconds()
            else:
                # If it's a string, parse it
                try:
                    if isinstance(lock_time, str):
                        lock_time = datetime.fromisoformat(lock_time.replace('Z', '+00:00').replace('+00:00', ''))
                    remaining_seconds = (lock_time - datetime.now()).total_seconds()
                except:
                    remaining_seconds = 1800  # Default to 30 minutes
            
            remaining_minutes = max(1, int(remaining_seconds / 60))
            raise HTTPException(
                status_code=423, 
                detail=f"Account is locked due to too many failed login attempts. Try again in {remaining_minutes} minute(s)."
            )
        else:
            # Lock period expired, reset attempts
            reset_query = """
                UPDATE users 
                SET failed_login_attempts = 0, account_locked_until = NULL
                WHERE user_id = %s
            """
            execute_query(reset_query, (user["user_id"],))
            user["failed_login_attempts"] = 0
            user["account_locked_until"] = None
    
    # Check if account is active
    if user["account_status"] != "Active":
        raise HTTPException(status_code=403, detail="Account is not active")
    
    # Verify password
    if user["password"] != password_hash:
        # Increment failed login attempts
        failed_attempts = (user.get("failed_login_attempts") or 0) + 1
        remaining_attempts = 3 - failed_attempts
        
        if failed_attempts >= 3:
            # Lock account for 30 minutes
            lock_until = datetime.now() + timedelta(minutes=30)
            update_query = """
                UPDATE users 
                SET failed_login_attempts = %s, account_locked_until = %s
                WHERE user_id = %s
            """
            execute_query(update_query, (failed_attempts, lock_until, user["user_id"]))
            raise HTTPException(
                status_code=423,
                detail="Account locked due to 3 failed login attempts. Please try again in 30 minutes or contact administrator."
            )
        else:
            # Update failed attempts
            update_query = """
                UPDATE users 
                SET failed_login_attempts = %s
                WHERE user_id = %s
            """
            execute_query(update_query, (failed_attempts, user["user_id"]))
            raise HTTPException(
                status_code=401, 
                detail=f"Invalid credentials. {remaining_attempts} attempt(s) remaining."
            )
    
    # Login successful - reset failed attempts and update last_login
    reset_query = """
        UPDATE users 
        SET failed_login_attempts = 0, account_locked_until = NULL, last_login = NOW()
        WHERE user_id = %s
    """
    execute_query(reset_query, (user["user_id"],))
    
    # Map database role back to UI role
    role_map_reverse = {
        "Student": "student",
        "Teacher": "teacher",
        "Admin": "admin"
    }
    
    return {
        "id": user["user_id"],
        "username": user["username"],
        "name": user["full_name"],
        "email": user["email"],
        "role": role_map_reverse.get(user["user_type"], "student")
    }

@router.post("/unlock-account/{user_id}")
async def unlock_account(user_id: str):
    """Unlock a user account (admin function)"""
    # Check if user exists
    check_query = "SELECT user_id FROM users WHERE user_id = %s"
    user = execute_query(check_query, (user_id,), fetch_one=True)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Unlock account
    unlock_query = """
        UPDATE users 
        SET failed_login_attempts = 0, account_locked_until = NULL
        WHERE user_id = %s
    """
    result = execute_query(unlock_query, (user_id,))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to unlock account")
    
    return {"success": True, "message": "Account unlocked successfully"}

