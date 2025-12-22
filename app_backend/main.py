from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import auth
from routes.student import mark_attendance, view_attendance_records
from routes.teacher import sessions
from routes.admin import users, courses, assignments, enrollments, warnings, exclusions

app = FastAPI(title="Student Attendance API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(mark_attendance.router)
app.include_router(view_attendance_records.router)
app.include_router(sessions.router)
app.include_router(users.router)
app.include_router(courses.router)
app.include_router(assignments.router)
app.include_router(enrollments.router)
app.include_router(warnings.router)
app.include_router(exclusions.router)

@app.get("/")
async def read_root():
    return {"message": "Student Attendance API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

