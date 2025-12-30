# Error & Warning Handling Guide

**Status:** ✅ Added execution and error handling functions

---

## What Are Error & Warning Functions?

These functions make it easy to send consistent responses back to Flutter app:

- **`success()`** - Send success message
- **`error()`** - Send error message (stops execution)
- **`warning()`** - Send warning message (continues execution)
- **`executeSelect()`** - Run SELECT query safely
- **`executeInsertUpdateDelete()`** - Run INSERT/UPDATE/DELETE safely
- **`validateRequired()`** - Check if required fields exist
- **`sanitize()`** - Clean input data

---

## These Functions Are in config.php

Every file includes `config.php`, so all functions work everywhere:

```php
include 'config.php';  // Includes all functions!
```

---

## How to Use Error & Warning Functions

### 1. Success Response

```php
// Get user data
$sql = "SELECT * FROM users WHERE user_id = '1'";
$user = executeSelectOne($sql);

if ($user) {
    // Send success with data
    success('User found', $user);
}
```

**Response sent to Flutter:**
```json
{
  "success": true,
  "message": "User found",
  "data": {
    "user_id": 1,
    "name": "Brahimi Ahmed",
    "email": "brahimi@example.com"
  }
}
```

---

### 2. Error Response

```php
$username = $_GET['username'];

// Check if username exists
if (!$username) {
    error('Username is required', 400);
}
```

**Response sent to Flutter:**
```json
{
  "success": false,
  "error": "Username is required"
}
```

**Error stops execution immediately!**

---

### 3. Warning Response

```php
$sql = "SELECT * FROM courses WHERE course_id = '999'";
$courses = executeSelect($sql);

if (count($courses) == 0) {
    // Send warning but continue
    warning('No courses found', []);
}
```

**Response sent to Flutter:**
```json
{
  "success": true,
  "warning": "No courses found",
  "data": []
}
```

---

## Database Execution Functions

### executeSelect() - Get Multiple Rows

```php
$sql = "SELECT * FROM users WHERE role = 'student'";
$students = executeSelect($sql);

// $students is an array of results
foreach ($students as $student) {
    echo $student['first_name'];
}
```

**What it does:**
- Runs the query
- Gets ALL rows
- Returns array
- If error → sends error response and stops

---

### executeSelectOne() - Get One Row

```php
$sql = "SELECT * FROM users WHERE user_id = '1'";
$user = executeSelectOne($sql);

// $user is ONE row (or NULL if not found)
echo $user['first_name'];
```

**What it does:**
- Runs the query
- Gets FIRST row only
- Returns one array (or NULL)
- If error → sends error response and stops

---

### executeInsertUpdateDelete() - Execute INSERT/UPDATE/DELETE

```php
$sql = "INSERT INTO courses (course_code, course_name)
        VALUES ('CRS001', 'Mathematics')";

$affected = executeInsertUpdateDelete($sql);

// $affected = number of rows changed
echo "Updated $affected rows";
```

**What it does:**
- Runs INSERT, UPDATE, or DELETE
- Returns how many rows were changed
- If error → sends error response and stops

---

### executeInsertGetId() - Insert and Get New ID

```php
$sql = "INSERT INTO users (username, first_name, last_name)
        VALUES ('ahmed', 'Ahmed', 'Ali')";

$id = executeInsertGetId($sql);

// $id = the new user_id
echo "New user ID: $id";
```

**What it does:**
- Inserts new row
- Returns the ID of the new row
- If error → sends error response and stops

---

## Validation Functions

### validateRequired() - Check Required Fields

```php
$data = json_decode(file_get_contents("php://input"), true);

// Check if all these fields exist and are not empty
validateRequired($data, ['username', 'password', 'email']);

// If any field is missing → sends error and stops!
```

**What it does:**
- Checks if each field exists
- Checks if each field is not empty
- If missing → sends error message like: "Missing required field: username"

---

### recordExists() - Check if Record Exists

```php
$username = 'ahmed';

// Check if username already exists in users table
if (recordExists('users', 'username', $username)) {
    error('Username already exists', 400);
}
```

**What it does:**
- Counts rows matching the condition
- Returns true/false
- `recordExists('users', 'username', 'ahmed')` → checks if username='ahmed' exists

---

### sanitize() - Clean Input Data

```php
$username = $_GET['username'];
$username = sanitize($username);  // Clean it!

$sql = "SELECT * FROM users WHERE username = '$username'";
```

**What it does:**
- Removes dangerous characters
- Protects against SQL injection
- Use on ALL user input!

---

## Real Example: Create User

```php
<?php
include 'config.php';

$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($action == 'create_user') {
    // Get data from Flutter
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Check required fields
    validateRequired($data, ['username', 'password', 'email']);
    
    // Clean input
    $username = sanitize($data['username']);
    $password = sanitize($data['password']);
    $email = sanitize($data['email']);
    
    // Check if username exists
    if (recordExists('users', 'username', $username)) {
        error('Username already taken', 400);
    }
    
    // Insert new user
    $sql = "INSERT INTO users (username, password, email)
            VALUES ('$username', '$password', '$email')";
    
    $id = executeInsertGetId($sql);
    
    // Send success
    success('User created successfully', ['id' => $id]);
}
?>
```

**What happens:**
1. Check if username, password, email are sent
2. If not → error stops everything
3. Clean the inputs
4. Check if username already exists
5. If yes → error
6. Insert into database
7. Get new ID
8. Send success with the new ID

---

## All Functions in config.php

```php
success($message, $data)        // Send success
error($message, $code)          // Send error (stops)
warning($message, $data)        // Send warning
executeSelect($sql)             // Get all rows
executeSelectOne($sql)          // Get one row
executeInsertUpdateDelete($sql) // INSERT/UPDATE/DELETE
executeInsertGetId($sql)        // INSERT and get new ID
validateRequired($data, $fields)// Check required fields
sanitize($input)                // Clean input
recordExists($table, $col, $val)// Check if exists
getById($table, $id)            // Get record by ID
```

---

## Testing Errors in Terminal

```bash
# Missing required field
curl -X POST http://localhost:8000/admin.php?action=create_user \
  -H "Content-Type: application/json" \
  -d '{"username":"ahmed"}'

# Response:
# {"success":false,"error":"Missing required field: password"}

# Duplicate username
curl -X POST http://localhost:8000/admin.php?action=create_user \
  -H "Content-Type: application/json" \
  -d '{"username":"brahimi","password":"pass","email":"email@test.com","first_name":"Test","last_name":"User","role":"student"}'

# Response (if brahimi exists):
# {"success":false,"error":"Username already exists"}

# Successful creation
curl -X POST http://localhost:8000/admin.php?action=create_user \
  -H "Content-Type: application/json" \
  -d '{"username":"newuser","password":"pass","email":"new@test.com","first_name":"New","last_name":"User","role":"student"}'

# Response:
# {"success":true,"message":"User created successfully","data":{"id":10}}
```

---

## Summary

✅ **All files now have:**
- Proper error handling
- Warning messages
- Input validation
- Input sanitization
- Safe database execution
- Consistent JSON responses

This makes debugging easy and keeps your code clean!
