# Backend Files - Visual Organization Guide

## 🎯 How to Navigate Backend Code

This guide helps you quickly find and understand any backend method.

---

## 📂 File Organization Tree

```
backend/
│
├── 🔐 auth.php                     ← Authentication
│   │
│   └── METHOD: POST /auth.php/login
│       └── UC1: Login (lines 18-127)
│           • Validate credentials
│           • Hash password verification
│           • Account lockout handling
│           • Return user details
│
├── 👨‍🎓 student.php                    ← Student Operations
│   │
│   ├── METHOD: POST /student.php/enter-code
│   │   └── UC2: Enter Code (lines 20-103)
│   │       • Validate code format
│   │       • Check session active
│   │       • Verify enrollment
│   │       • Mark present
│   │
│   ├── METHOD: GET /student.php/history
│   │   └── UC3: View History (lines 104-195)
│   │       • Attendance records
│   │       • Statistics calculation
│   │       • Warnings & exclusions
│   │
│   └── METHOD: GET /student.php/profile
│       └── UC8: View Profile (lines 196-220)
│           • User information
│           • Account details
│
├── 👨‍🏫 teacher.php                     ← Teacher Operations
│   │
│   ├── METHOD: POST /teacher.php/generate-session
│   │   └── UC4: Generate Session (lines 20-67)
│   │       • Generate attendance code
│   │       • Set expiration time
│   │       • Create session record
│   │
│   ├── METHOD: POST /teacher.php/mark-absence
│   │   └── UC5: Mark Absence (lines 69-145)
│   │       • Validate absence type
│   │       • Update attendance
│   │       • Auto-trigger warnings
│   │
│   ├── METHOD: PUT /teacher.php/update-attendance
│   │   └── UC6: Update Attendance (lines 147-200)
│   │       • Modify status
│   │       • Recalculate triggers
│   │
│   ├── METHOD: GET /teacher.php/records
│   │   └── UC7: View Records (lines 202-250)
│   │       • Complex database join
│   │       • Attendance statistics
│   │
│   ├── METHOD: GET /teacher.php/courses
│   │   └── HELPER: List Courses (lines 252-270)
│   │       • Assigned courses only
│   │
│   └── METHOD: GET /teacher.php/non-submitters
│       └── HELPER: Non-Submitters (lines 272-290)
│           • Students without submission
│
├── 👤 admin.php                      ← Admin Operations
│   │
│   ├── METHOD: GET /admin.php/users
│   │   └── UC9: Get Users (lines 20-40)
│   │       • List all users
│   │       • Filter by role/status
│   │
│   ├── METHOD: POST /admin.php/users
│   │   └── UC9: Create User (lines 42-100)
│   │       • Validate inputs
│   │       • Hash password
│   │       • Create role record
│   │
│   ├── METHOD: DELETE /admin.php/users
│   │   └── UC9: Delete User (lines 102-112)
│   │       • Soft delete
│   │
│   ├── METHOD: POST /admin.php/reinstate
│   │   └── UC9: Reinstate User (lines 114-124)
│   │       • Set status Active
│   │
│   ├── METHOD: POST /admin.php/suspend
│   │   └── UC9: Suspend User (lines 126-136)
│   │       • Set status Suspended
│   │
│   ├── METHOD: POST /admin.php/assign-courses
│   │   └── UC10: Assign Courses (lines 146-167)
│   │       • Clear & reassign
│   │       • Validate courses
│   │
│   ├── METHOD: GET /admin.php/courses [NEW]
│   │   └── UC10: Get Courses (lines 169-177)
│   │       • Available courses
│   │
│   ├── METHOD: GET /admin.php/assignments [NEW]
│   │   └── UC10: Get Assignments (lines 179-192)
│   │       • Teacher-course pairs
│   │
│   ├── METHOD: POST /admin.php/remove-assignment [NEW]
│   │   └── UC10: Remove Assignment (lines 194-205)
│   │       • Delete assignment
│   │
│   └── METHOD: GET /admin.php/all-records
│       └── UC7: View Records (lines 207-225)
│           • System-wide attendance
│
├── ⚙️ config.php                     ← Configuration
│   ├── Database connection
│   ├── CORS headers
│   └── Helper functions include
│
└── 🔧 helpers.php                    ← Utilities
    ├── Input validation functions
    ├── Database operation helpers
    ├── Business logic functions
    └── Response formatting
```

---

## 🔍 How to Find a Method

### By Use Case (UC)

```
Need UC2 (Student Enter Code)?
  → Go to: student.php
  → Look for: POST /student.php/enter-code
  → Lines: 20-103

Need UC5 (Teacher Mark Absence)?
  → Go to: teacher.php
  → Look for: POST /teacher.php/mark-absence
  → Lines: 69-145

Need UC9 (Admin Create User)?
  → Go to: admin.php
  → Look for: POST /admin.php/users
  → Lines: 42-100
```

### By HTTP Method

```
Looking for POST endpoints?
  auth.php:      POST /auth.php/login
  student.php:   POST /student.php/enter-code
  teacher.php:   POST /teacher.php/generate-session
               POST /teacher.php/mark-absence
  admin.php:     POST /admin.php/users
               POST /admin.php/reinstate
               POST /admin.php/suspend
               POST /admin.php/assign-courses
               POST /admin.php/remove-assignment

Looking for GET endpoints?
  student.php:   GET /student.php/history
               GET /student.php/profile
  teacher.php:   GET /teacher.php/records
               GET /teacher.php/courses
               GET /teacher.php/non-submitters
  admin.php:     GET /admin.php/users
               GET /admin.php/courses
               GET /admin.php/assignments
               GET /admin.php/all-records

Looking for PUT endpoints?
  teacher.php:   PUT /teacher.php/update-attendance

Looking for DELETE endpoints?
  admin.php:     DELETE /admin.php/users
```

### By Functionality

```
Authentication:
  → auth.php (lines 18-127)

Attendance Management:
  → student.php: enter-code (lines 20-103)
  → student.php: history (lines 104-195)
  → teacher.php: mark-absence (lines 69-145)
  → teacher.php: update-attendance (lines 147-200)
  → admin.php: all-records (lines 207-225)

Session Management:
  → teacher.php: generate-session (lines 20-67)
  → teacher.php: records (lines 202-250)

User Management:
  → admin.php: users (lines 20-100)
  → admin.php: reinstate (lines 114-124)
  → admin.php: suspend (lines 126-136)

Course Management:
  → admin.php: assign-courses (lines 146-167)
  → admin.php: courses (lines 169-177)
  → admin.php: assignments (lines 179-192)
  → admin.php: remove-assignment (lines 194-205)
  → teacher.php: courses (lines 252-270)
```

---

## 📋 Method Block Structure Template

Every method follows this pattern:

```php
// ===========================
// UC#: METHOD NAME
// ===========================
if ($action === 'endpoint-name' && $_SERVER['REQUEST_METHOD'] === 'HTTP_METHOD') {

    // STEP 1: Parse input
    $data = json_decode(file_get_contents("php://input"), true);
    
    // STEP 2: Validate
    validateRequired($data, ['field1', 'field2']);
    
    // STEP 3: Sanitize
    $var1 = sanitize($data['field1']);
    
    // STEP 4: Database queries
    $result = executeSelectOne($sql);
    
    // STEP 5: Validate business logic
    if (!$result) {
        error('Error message', 400);
    }
    
    // STEP 6: Main operation
    executeInsertUpdateDelete($sql);
    
    // STEP 7: Return response
    success('Success message', $data);
}
```

---

## 🚀 Quick Start - Copy Any Method

### Example 1: Login (UC1)

```
File: auth.php
Lines: 18-127
Copy entire block between:
  if ($action === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
  ...
  success(...);
  }
```

### Example 2: Enter Code (UC2)

```
File: student.php
Lines: 20-103
Copy entire block between:
  if ($action === 'enter-code' && $_SERVER['REQUEST_METHOD'] === 'POST') {
  ...
  success(...);
  }
```

### Example 3: Create User (UC9)

```
File: admin.php
Lines: 42-100
Copy entire block between:
  else if ($action === 'users' && $_SERVER['REQUEST_METHOD'] === 'POST') {
  ...
  success(...);
  }
```

---

## 🔗 Dependencies

```
Every backend file depends on:

┌─────────────────────────────────────┐
│ Include: config.php                 │
│ ├── Database connection             │
│ ├── CORS headers                    │
│ └── Include: helpers.php            │
│     ├── Validation functions        │
│     ├── Database operations         │
│     ├── Business logic              │
│     └── Response formatting         │
└─────────────────────────────────────┘

Flow:
  backend/
  ├── auth.php ──┐
  ├── student.php├──> config.php ──> helpers.php
  ├── teacher.php├──>
  └── admin.php ─┘

Every file has:
  1. Include config.php
  2. Handle OPTIONS (CORS)
  3. Extract action from URL
  4. Route to appropriate method
  5. Call helpers for validation
  6. Perform database operations
  7. Return JSON response
```

---

## 💡 Tips for Reading Code

### 1. **Start with Comments**
Every method has a comment block:
```php
// ===========================
// UC#: METHOD NAME
// ===========================
```

### 2. **Follow the Flow**
```
Input → Validate → Query → Logic → Response
```

### 3. **Look for Error Checks**
Lines with `error()` calls indicate validation points

### 4. **Database Operations**
Count the `executeSelect()` and `executeInsertUpdateDelete()` calls

### 5. **Security Points**
Look for:
- `sanitize()` calls
- `validateRequired()` calls
- `password_verify()` usage
- Account status checks

---

## 📊 Complexity Level by Method

```
SIMPLE (< 30 lines):
  ✓ DELETE /admin.php/users
  ✓ POST /admin.php/reinstate
  ✓ POST /admin.php/suspend
  ✓ GET /admin.php/courses
  ✓ GET /teacher.php/courses

MEDIUM (30-100 lines):
  ✓ POST /auth.php/login
  ✓ POST /student.php/enter-code
  ✓ GET /student.php/profile
  ✓ GET /admin.php/users
  ✓ POST /admin.php/users
  ✓ POST /teacher.php/generate-session
  ✓ POST /teacher.php/mark-absence

COMPLEX (> 100 lines):
  ✓ GET /student.php/history
  ✓ PUT /teacher.php/update-attendance
  ✓ GET /teacher.php/records
  ✓ GET /admin.php/all-records
  ✓ POST /admin.php/assign-courses
```

---

## 🎓 Learning Path

### Day 1: Authentication
1. Read: auth.php (lines 18-127)
2. Understand: Login flow
3. Learn: Password hashing, account lockout

### Day 2: Student Features
1. Read: student.php (lines 20-103)
2. Understand: Attendance code validation
3. Read: student.php (lines 104-195)
4. Learn: Complex queries with joins

### Day 3: Teacher Features
1. Read: teacher.php (lines 20-67)
2. Understand: Session generation
3. Read: teacher.php (lines 69-145)
4. Learn: Business logic triggers

### Day 4: Admin Features
1. Read: admin.php (lines 20-100)
2. Understand: User creation & validation
3. Read: admin.php (lines 146-167)
4. Learn: Complex assignments

### Day 5: System Design
1. Review: config.php, helpers.php
2. Understand: Database architecture
3. Learn: Security patterns

---

## ✅ Verification Checklist

When learning a method, verify:

- [ ] **Header:** Clear UC comment
- [ ] **Input:** Proper validation
- [ ] **Security:** sanitize() and error checks
- [ ] **Database:** Correct queries
- [ ] **Logic:** Business rules applied
- [ ] **Response:** Proper JSON format
- [ ] **Errors:** HTTP status codes

---

**Last Updated:** January 2, 2026  
**Total Methods:** 21  
**Total Lines:** ~1682  
**Status:** ✅ FULLY DOCUMENTED

