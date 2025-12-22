from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from connection import execute_query, generate_id
from typing import Optional
import hashlib

router = APIRouter(prefix="/admin", tags=["admin"])

class CreateUserRequest(BaseModel):
    username: str
    password: str
    email: str
    full_name: str
    role: str  # student, teacher, admin

class UpdateUserStatusRequest(BaseModel):
    status: str  # active, deleted, suspended

@router.post("/users")
async def create_user(request: CreateUserRequest):
    """Create a new user"""
    # Check if username exists
    check_query = "SELECT user_id FROM users WHERE username = %s"
    existing = execute_query(check_query, (request.username,), fetch_one=True)
    
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Check if email exists
    check_email = "SELECT user_id FROM users WHERE email = %s"
    existing_email = execute_query(check_email, (request.email,), fetch_one=True)
    
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already exists")
    
    # Map UI role to database role
    role_map = {
        "student": "Student",
        "teacher": "Teacher",
        "admin": "Admin"
    }
    db_role = role_map.get(request.role.lower(), "Student")
    
    # Hash password
    password_hash = hashlib.md5(request.password.encode()).hexdigest()
    
    # Generate IDs
    user_id = generate_id()
    role_id = generate_id()
    
    # Insert user
    insert_user = """
        INSERT INTO users (user_id, username, password, email, full_name, user_type, account_status)
        VALUES (%s, %s, %s, %s, %s, %s, 'Active')
    """
    result = execute_query(insert_user, (user_id, request.username, password_hash, request.email, request.full_name, db_role))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to create user")
    
    # Insert role-specific record
    if db_role == "Student":
        insert_role = "INSERT INTO students (student_id, user_id) VALUES (%s, %s)"
        execute_query(insert_role, (role_id, user_id))
    elif db_role == "Teacher":
        insert_role = "INSERT INTO teachers (teacher_id, user_id) VALUES (%s, %s)"
        execute_query(insert_role, (role_id, user_id))
    elif db_role == "Admin":
        insert_role = "INSERT INTO admins (admin_id, user_id) VALUES (%s, %s)"
        execute_query(insert_role, (role_id, user_id))
    
    return {
        "success": True,
        "user_id": user_id,
        "message": "User created successfully"
    }

@router.get("/users")
async def get_all_users():
    """Get all users"""
    query = """
        SELECT 
            u.user_id as id,
            u.username,
            u.email,
            u.full_name as name,
            u.user_type as role,
            u.account_status as status,
            u.created_at
        FROM users u
        ORDER BY u.created_at DESC
    """
    
    users = execute_query(query, fetch_all=True)
    
    if users is None:
        return []
    
    # Map database role to UI role
    role_map = {
        "Student": "student",
        "Teacher": "teacher",
        "Admin": "admin"
    }
    
    status_map = {
        "Active": "active",
        "Deleted": "deleted",
        "Suspended": "suspended"
    }
    
    result = []
    for user in users:
        result.append({
            "id": user["id"],
            "username": user["username"],
            "email": user["email"],
            "name": user["name"],
            "role": role_map.get(user["role"], "student"),
            "status": status_map.get(user["status"], "active"),
            "created_at": user["created_at"].isoformat() if user["created_at"] else None
        })
    
    return result

@router.put("/users/{user_id}/status")
async def update_user_status(user_id: str, request: UpdateUserStatusRequest):
    """Update user account status"""
    # Map UI status to database status
    status_map = {
        "active": "Active",
        "deleted": "Deleted",
        "suspended": "Suspended"
    }
    db_status = status_map.get(request.status.lower(), "Active")
    
    update_query = "UPDATE users SET account_status = %s WHERE user_id = %s"
    result = execute_query(update_query, (db_status, user_id))
    
    if result is None:
        raise HTTPException(status_code=500, detail="Failed to update user status")
    
    return {"success": True, "message": "User status updated"}

@router.delete("/users/{user_id}")
async def delete_user(user_id: str):
    """Delete a user (hard delete - permanently removes from database)"""
    # Check if user exists
    check_query = "SELECT user_id FROM users WHERE user_id = %s"
    user = execute_query(check_query, (user_id,), fetch_one=True)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete user (CASCADE will handle related records in students/teachers/admins tables)
    delete_query = "DELETE FROM users WHERE user_id = %s"
    result = execute_query(delete_query, (user_id,))
    
    if result is None or result == 0:
        raise HTTPException(status_code=500, detail="Failed to delete user")
    
    return {"success": True, "message": "User permanently deleted"}

