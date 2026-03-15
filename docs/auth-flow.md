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

## API Response Structure

All API responses follow a unified structure:

```json
{
  "code": 200,
  "message": "Thành công",
  "data": { ... }
}
```

- `code`: Custom application status code (usually matches HTTP status).
- `message`: Human-readable message in Vietnamese.
- `data`: The actual payload. For error responses, this is `null`.

---

## 1. Citizen Registration & Email Verification

New citizens must verify their email before they can log in. A fresh account has `isActive: false` and all login attempts will be rejected until verification is complete.

POST /auth/citizen/register
→ returns: { "code": 201, "message": "Đăng ký thành công. Vui lòng kiểm tra email để xác thực.", "data": null }

POST /auth/citizen/verify-email   { email, otp }
→ returns: { "code": 200, "message": "Xác thực email thành công.", "data": null }

# If OTP expired or lost:
POST /auth/citizen/resend-verification  { email }
→ returns: { "code": 200, "message": "Mã xác thực mới đã được gửi.", "data": null }

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
→ Returns: 
{
  "code": 200,
  "message": "Thành công",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "tokenType": "Bearer",
    "accessExpiresIn": 9000
  }
}
```

### Option B: OTP Login (passwordless)

```
POST /auth/citizen/request-otp   { email }
→ returns: { "code": 200, "message": "Mã OTP đã được gửi.", "data": null }

POST /auth/citizen/verify-otp    { email, otp }
→ Returns: 
{
  "code": 200,
  "message": "Thành công",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "tokenType": "Bearer",
    "accessExpiresIn": 9000
  }
}
```

---

### Staff / Manager / Admin Login

```
POST /auth/staff/login
Body: { "email": "...", "password": "..." }
→ Returns: 
{
  "code": 200,
  "message": "Thành công",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "tokenType": "Bearer",
    "accessExpiresIn": 9000
  }
}
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
→ {
    "code": 200,
    "message": "Thành công",
    "data": {
      "id": "...",
      "email": "...",
      "fullName": "...",
      "role": "...",
      "isActive": true
    }
  }
```

---

## 5. Token Refresh

Access tokens expire in 150 minutes. Use the refresh token to get a new pair **without re-logging in**. Each refresh call **rotates the refresh token** (old one is invalidated).

```
POST /auth/refresh
Body: { "refreshToken": "..." }
→ Returns:
{
  "code": 200,
  "message": "Thành công",
  "data": {
    "accessToken": "...",
    "refreshToken": "..."
  }
}
```

> ⚠️ Store the new `refreshToken` from every response — the old one will no longer work.

---

## 6. Logout

Invalidates the refresh token so it cannot be used to generate new access tokens. The current access token remains valid until it naturally expires.

```
POST /auth/logout
Authorization: Bearer <accessToken>
Body: { "refreshToken": "..." }
→ { "code": 200, "message": "Đăng xuất thành công.", "data": null }
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

Error responses also use the `ApiResponse` structure with `data: null`:

```json
{
  "code": 401,
  "message": "Sai email hoặc mật khẩu.",
  "data": null
}
```

| HTTP Status | Meaning                                                |
| ----------- | ------------------------------------------------------ |
| `400`       | Validation error (missing or invalid fields)           |
| `401`       | Wrong credentials, expired/invalid token, or wrong OTP |
| `403`       | Account inactive (not verified) or insufficient role   |
| `409`       | Email already registered                               |
| `500`       | Internal Server Error                                  |
