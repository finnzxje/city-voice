# CityVoice – Authentication API Guide

> **Swagger UI**: http://localhost:8080/api/swagger-ui.html  
> **Raw API JSON**: http://localhost:8080/api/v3/api-docs
> **Base URL**: `http://localhost:8080/api`  
> **Auth header**: `Authorization: Bearer <accessToken>`

---

## Overview

CityVoice has two classes of users with distinct authentication flows:

| User Type                   | Registration                                | Login Options       |
| --------------------------- | ------------------------------------------- | ------------------- |
| **Citizen**                 | Self-register (requires email verification) | Password **or** OTP |
| **Staff / Manager / Admin** | Seeded by Admin                             | Password only       |

---

## 1. Citizen Registration & Email Verification

New citizens must verify their email before they can log in. A fresh account has `isActive: false` and all login attempts will be rejected until verification is complete.

```
POST /auth/citizen/register
→ Account created (inactive)
→ Verification OTP sent to email (valid for 15 minutes)

POST /auth/citizen/verify-email   { email, otp }
→ Account activated (isActive: true)
→ Returns 200 OK

# If OTP expired or lost:
POST /auth/citizen/resend-verification  { email }
→ Invalidates old OTP, sends a fresh one
```

**Flow diagram:**

```
Register → [Email arrives] → Verify OTP → ✅ Active Account
                                ↓ (expired)
                          Resend OTP → Verify OTP → ✅
```

---

## 2. Citizen Login

Verified citizens have two login options. Both return the same token pair.

### Option A: Password Login

```
POST /auth/citizen/login
Body: { "email": "...", "password": "..." }
→ Returns: { accessToken, refreshToken, tokenType, accessExpiresIn }
```

### Option B: OTP Login (passwordless)

```
POST /auth/citizen/request-otp   { email }
→ Login OTP sent to email (valid for 10 minutes)

POST /auth/citizen/verify-otp    { email, otp }
→ Returns: { accessToken, refreshToken, tokenType, accessExpiresIn }
```

---

## 3. Staff / Manager / Admin Login

Internal users (staff, managers, admin) are created by an administrator and log in with a password only. There is no self-registration.

```
POST /auth/staff/login
Body: { "email": "...", "password": "..." }
→ Returns: { accessToken, refreshToken, tokenType, accessExpiresIn }
```

> **Default Admin** (created on first startup):  
> Email: `admin@cityvoice.vn`  
> Password: configurable via `ADMIN_PASSWORD` env var (default: `Admin@123`)  
> ⚠️ Change this immediately in production.

---

## 4. Using Tokens

All protected endpoints require a JWT access token:

```
Authorization: Bearer <accessToken>
```

| Token          | Expiry      | Purpose                   |
| -------------- | ----------- | ------------------------- |
| `accessToken`  | 150 minutes | Authenticate API requests |
| `refreshToken` | 7 days      | Obtain a new access token |

### Get Current User Info

```
GET /auth/me
Authorization: Bearer <accessToken>
→ { id, email, fullName, role, isActive }
```

---

## 5. Token Refresh

Access tokens expire in 150 minutes. Use the refresh token to get a new pair **without re-logging in**. Each refresh call **rotates the refresh token** (old one is invalidated).

```
POST /auth/refresh
Body: { "refreshToken": "..." }
→ Returns a new { accessToken, refreshToken } pair
```

> ⚠️ Store the new `refreshToken` from every response — the old one will no longer work.

---

## 6. Logout

Invalidates the refresh token so it cannot be used to generate new access tokens. The current access token remains valid until it naturally expires.

```
POST /auth/logout
Authorization: Bearer <accessToken>
Body: { "refreshToken": "..." }
→ 200 OK
```

---

## 7. Role-Based Access (RBAC)

| Role      | Access Level                   |
| --------- | ------------------------------ |
| `citizen` | Own reports, public city data  |
| `staff`   | Assigned reports in their zone |
| `manager` | All reports, staff management  |
| `admin`   | Full system access             |

Role is embedded in the JWT payload and enforced server-side on each request. You do **not** need to send the role separately.

---

## Error Reference

| HTTP Status | Meaning                                                |
| ----------- | ------------------------------------------------------ |
| `400`       | Validation error (missing or invalid fields)           |
| `401`       | Wrong credentials, expired/invalid token, or wrong OTP |
| `403`       | Account inactive (not verified) or insufficient role   |
| `409`       | Email already registered                               |
