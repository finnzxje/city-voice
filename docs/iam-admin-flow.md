# Module 4: Identity & Access Management (IAM) and System Configuration

This document outlines the architecture and workflows for Module 4 of the CityVoice platform, encompassing Authentication, Role-Based Access Control (RBAC), and Administrator configuration features.

---

## 1. Authentication Flows

The system utilizes a hybrid authentication approach depending on the user type. All authentication results in a short-lived **Access Token** (JWT) and a long-lived **Refresh Token**.

### 1a. Citizen Authentication (Password or OTP)
Citizens self-register with an email and password, verify their email once using an OTP, and may then log in using either their password or a login OTP.

1. **Register:** Client calls `POST /api/auth/citizen/register` with an email and password.
    - The password is encoded and stored in `users.password_hash`.
    - The account is created inactive until the email address is verified.
    - An email-verification OTP is generated and stored in `otp_tokens`.
2. **Verify email:** Client calls `POST /api/auth/citizen/verify-email` with the email and verification OTP.
    - If valid, the OTP is invalidated to prevent reuse and the citizen account becomes active.
3. **Password login:** An active citizen calls `POST /api/auth/citizen/login` with email and password.
    - If the encoded password matches, the system issues an Access Token (`citizen` role) and a Refresh Token.
4. **OTP login:** An active citizen calls `POST /api/auth/citizen/request-otp`, followed by `POST /api/auth/citizen/verify-otp`.
    - The generated login OTP has a 10-minute expiry and cannot be reused after successful verification.
    - If valid, the system issues the same token pair as password login.

Requesting a login OTP does not automatically register a new account. Registration and email verification must already have completed.

### 1b. Staff, Manager & Admin Authentication
Employees (Staff, Managers, and Admins) use traditional email and password credentials.

1. **Login:** Client calls `POST /api/auth/staff/login` with email and password.
2. **Verification:** System validates credentials against securely hashed (BCrypt) passwords in the `users` table.
3. **Issuance:** System issues an Access Token and a Refresh Token embedding the user's ID.

### 1c. Token Refresh
When an Access Token expires (default: 150 minutes), clients can call `POST /api/auth/refresh` with their valid Refresh Token (default: 7 days) to receive a new pair of tokens without requiring the user to log in again.

---

## 2. Role-Based Access Control (RBAC)

Authorization is strictly enforced at the API layer using Spring Security's `@PreAuthorize()`.

| Role | Scope & Permissions | Handled Endpoints (Examples) |
|---|---|---|
| **CITIZEN** | Can submit and view their own incident reports. | `POST /reports`, `GET /reports/my`, `GET /reports/{id}` |
| **STAFF** | Can list, review, reject, and resolve reports subject to workflow rules. | `GET /reports`, `PUT /reports/{id}/review`, `PUT /reports/{id}/reject`, `POST /reports/{id}/resolve` |
| **MANAGER** | Can view reports and access analytical data and exports. | `GET /reports`, `GET /analytics/stats`, `GET /analytics/heatmap`, `GET /analytics/export/pdf`, `GET /analytics/export/excel` |
| **ADMIN** | Superuser. Can configure system settings, manage users, and manage categories. | All `/admin/*`, `POST /categories` |

> [!NOTE] 
> **Live State Validation:** Our `JwtAuthFilter` extracts the `userId` from the JWT and fetches the fresh `User` record on *every* request. This guarantees that if an Admin demotes a user or disables an account, those changes take immediate effect on the very next API call.

---

## 3. Administrative Configuration Workflows

Admins have exclusive access to manage the core metadata that drives the platform.

### 3a. User Role Management
Admins can elevate citizens to staff members or demote managers.
* `GET /api/admin/roles`: Returns a list of all system roles (`citizen`, `staff`, `manager`, `admin`).
* `GET /api/admin/users`: Returns a secure manifest of all users (`id`, `email`, `fullName`, `role`, `isActive`).
* `PUT /api/admin/users/{userId}/role`: Updates a user's role. Requires payload such as `{ "role": "staff" }`.

### 3b. Category Management
Instead of a hardcoded enum, incident categories (e.g., "Pothole", "Fallen Tree") are dynamically driven by the `categories` database table. The public endpoint `GET /api/categories` only lists active categories.
* `GET /api/categories`: *(Public)* Returns only active categories. Used by citizens when submitting reports.
* `GET /api/categories/all`: *(Admin only)* Returns **all** categories regardless of active status. Allows admins to discover and re-enable previously deactivated categories.
* `POST /api/categories`: Creates a new category. Validates that the unique `slug` string is not duplicated (returns `409 Conflict` if it is).
* `PUT /api/categories/{id}`: Updates name, icon, slug, or the `active` boolean status.
* *Soft Deletion:* Setting `"active": false` on a category immediately removes it from the citizen-facing incident reporting form without breaking historical analytical data. To re-enable, an admin calls `GET /api/categories/all` to find the category ID, then calls `PUT /api/categories/{id}` with `"active": true`.

---

## 4. Default Seeded Accounts

For local development and testing, `AdminSeeder` and `DevSeeder` automatically initialize the following accounts on startup (if they don't already exist):

| Role | Email | Password |
|---|---|---|
| **ADMIN** | `admin@cityvoice.vn` | `Admin@123` |
| **MANAGER** | `manager@cityvoice.vn` | `Manager@123` |
| **STAFF** | `staff@cityvoice.vn` | `Staff@123` |
| **CITIZEN** | `citizen@cityvoice.vn` | `Citizen@123` |

*(Note: The seeded citizen is active and supports both documented citizen login paths: password and OTP.)*
