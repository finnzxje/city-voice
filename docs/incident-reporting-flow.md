# CityVoice – Incident Reporting API Guide

> **Swagger UI**: http://localhost:8080/api/swagger-ui.html  
> **Raw API JSON**: http://localhost:8080/api/v3/api-docs
> **Base URL**: `http://localhost:8080/api`  
> **Auth header**: `Authorization: Bearer <accessToken>`

---

## Overview

The Incident Reporting flow allows verified citizens to submit geo-tagged issues (potholes, broken lights, etc.) with photo evidence. The system automatically validates that the incident occurred within Ho Chi Minh City bounds and assigns it to the correct administrative district.

| Component                   | Technology / Implementation                                |
| --------------------------- | ---------------------------------------------------------- |
| **Geospatial Validation**   | PostGIS `ST_Contains` against HCMC `MultiPolygon` boundary |
| **Location Encoding**       | GPS Coordinates (Lat/Lon) → PostGIS `Point` geometry       |
| **Image Storage**           | S3-compatible Object Storage (MinIO)                       |

---

## 1. Fetching Categories

Before a citizen can submit a report, the client app must fetch the list of available active categories.

```http
GET /categories
Authorization: Bearer <anyValidToken>
```
**Returns:**
```json
{
  "code": 200,
  "message": "Thành công",
  "data": [
    {
      "id": 1,
      "name": "Hư hỏng đường bộ",
      "slug": "hu-hong-duong-bo",
      "iconKey": "road_repair"
    }
  ]
}
```

---

## 2. Submitting an Incident Report

Only users with the `citizen` role can submit reports. The request must be sent as `multipart/form-data` to handle the image upload alongside the textual data.

```http
POST /reports
Authorization: Bearer <citizenToken>
Content-Type: multipart/form-data
```

**Form Parts:**
| Field Name    | Type     | Required | Description                                      |
| ------------- | -------- | -------- | ------------------------------------------------ |
| `title`       | text     | Yes      | Short summary of the issue (max 500 chars)       |
| `description` | text     | No       | Detailed explanation                             |
| `categoryId`  | number   | Yes      | ID from the `/categories` endpoint               |
| `latitude`    | number   | Yes      | GPS Latitude (e.g., 10.7769)                     |
| `longitude`   | number   | Yes      | GPS Longitude (e.g., 106.7009)                   |
| `image`       | file     | Yes      | JPEG or PNG image file (max 10MB)                |

### Server-Side Processing Flow:
1. **File Validation:** Checks for valid image MIME types (`image/jpeg`, `image/png`) and size.
2. **Location Validation:** PostGIS checks if `(longitude, latitude)` falls inside the HCMC boundary.
3. **District Resolution:** PostGIS maps the point to a specific District (Administrative Zone).
4. **Storage:** The image is uploaded to MinIO bucket; a public URL is generated.
5. **Database:** The `Report` is saved in the database with status `newly_received`.
6. **Audit:** A `StatusHistory` record is created logging the citizen's submission.

### Responses
- **`201 Created`**: Report saved successfully. 
  - Body: `{ "code": 201, "message": "Báo cáo đã được gửi thành công.", "data": { ReportResponse } }`
- **`400 Bad Request`**: Out of bounds, invalid category, or validation error.
  - Body: `{ "code": 400, "message": "Lỗi xác thực dữ liệu.", "data": { "field": "error message" } }`
- **`413 Payload Too Large`**: Image exceeds 10MB.
- **`403 Forbidden`**: Admin/Staff tried to submit, or account is unverified.

---

## 3. Viewing Reports

A citizen can see a list of all reports they have ever submitted.

```http
GET /reports/my
Authorization: Bearer <citizenToken>
→ { "code": 200, "message": "Thành công", "data": [ ...Array of ReportResponse... ] }
```

### 3b. Fetching a specific report details

Both the citizen who created the report and any internal staff/admin can fetch the full details of a specific report.

```http
GET /reports/{reportId}
Authorization: Bearer <validToken>
```
**Returns:**
```json
{
  "code": 200,
  "message": "Thành công",
  "data": {
    "id": "uuid-here",
    "title": "Pothole on Nguyen Hue Boulevard",
    "description": "Large pothole causing traffic disruption near Quan 1",
    "categoryName": "Hư hỏng đường bộ",
    "latitude": 10.7769,
    "longitude": 106.7009,
    "administrativeZoneName": "Quận 1",
    "incidentImageUrl": "http://localhost:9000/cityvoice-reports/...",
    "currentStatus": "newly_received",
    "createdAt": "2026-03-08T12:00:00Z"
  }
}
```

---

## Report Status Lifecycle

The `currentStatus` field of a report maps to the PostgreSQL enumerator `report_status`:

1. `newly_received`: Default state upon submission.
2. `in_progress`: A staff member has been assigned and is working on the issue.
3. `resolved`: The issue has been fixed (usually accompanied by a `resolutionImageUrl`).
4. `rejected`: The report was deemed invalid, duplicate, or unactionable.

All status changes are tracked transactionally in the `status_history` table for auditing and transparency.

---

## 4. Staff Workflow (Module 2)

Staff, managers, and admins manage the lifecycle of reports through a strictly enforced state machine.

```
newly_received ──► in_progress  (staff reviews & accepts)
newly_received ──► rejected     (staff rejects as inauthentic)
in_progress    ──► resolved     (staff uploads proof image)
```

No step-skipping is allowed. Any invalid transition returns `400 Bad Request`.

---

### 4a. List All Reports (Staff/Manager/Admin)

```http
GET /reports?status=newly_received&priority=high&page=0&size=20
Authorization: Bearer <staffToken>
```

**Query Parameters (all optional):**
| Param | Type | Example |
|---|---|---|
| `status` | enum | `newly_received`, `in_progress`, `resolved`, `rejected` |
| `priority` | enum | `low`, `medium`, `high`, `critical` |
| `assignedTo` | UUID | staff user UUID |
| `categoryId` | integer | `1` |
| `page` / `size` | integer | defaults: `0` / `20` |

**Returns:** Paginated `ReportResponse`. Staff-visible fields added in Module 2:
```json
{
  "priority": "high",
  "citizenId": "uuid",
  "citizenName": "Nguyen Van A",
  "assignedToId": "uuid",
  "assignedToName": "Tran Thi B"
}
```

---

### 4b. Review Report → `in_progress`

```http
PUT /reports/{reportId}/review
Authorization: Bearer <staffToken>
Content-Type: application/json

{
  "priority": "high",
  "assignedTo": "<staffUserUUID>",
  "note": "Verified authentic – assigning for repair"
}
```

**Transitions:** `newly_received → in_progress`  
**Returns:** `200` with updated `ReportResponse` or `400` if report is not in `newly_received`.

---

### 4c. Reject Report → `rejected`

```http
PUT /reports/{reportId}/reject
Authorization: Bearer <staffToken>
Content-Type: application/json

{
  "note": "Báo cáo không đủ bằng chứng để xác minh."
}
```

**Transitions:** `newly_received → rejected`  
**Side effects:** Dual-channel notification (in-app + email) sent to the citizen.

---

### 4d. Resolve Report → `resolved`

```http
POST /reports/{reportId}/resolve
Authorization: Bearer <staffToken>
Content-Type: multipart/form-data

image: <proof image file>  (required)
note:  "Pothole repaired"  (optional text part)
```

Via curl:
```bash
curl -X POST http://localhost:8080/api/reports/{reportId}/resolve \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -F "image=@/path/to/proof.jpg;type=image/jpeg" \
  -F "note=Pothole fully repaired and resurfaced"
```

**Transitions:** `in_progress → resolved`  
**Side effects:** Sets `resolutionImageUrl`, `resolvedAt`. Dual-channel notification sent to the citizen.

---

## 5. Citizen Notifications

Notifications are triggered automatically on `resolved` and `rejected` transitions.

### 5a. List My In-App Notifications

```http
GET /notifications
Authorization: Bearer <citizenToken>
```

**Returns:** Array of in-app `NotificationResponse` (newest first):
```json
[
  {
    "id": "uuid",
    "type": "report_resolved",
    "message": "Báo cáo \"Test pothole\" của bạn đã được giải quyết thành công.",
    "isRead": false,
    "sentAt": "2026-03-15T07:00:00Z",
    "reportId": "uuid"
  }
]
```

### 5b. Unread Count (for badge display)

```http
GET /notifications/unread-count
Authorization: Bearer <citizenToken>
→ { "code": 200, "data": { "count": 2 } }
```

### 5c. Mark Notification as Read

```http
PUT /notifications/{notifId}/read
Authorization: Bearer <citizenToken>
→ { "code": 200, "data": { ...NotificationResponse, "isRead": true } }
```

> **Note:** `isRead` is only surfaced for in-app notifications. Email rows are dispatch receipts only and are never returned by these endpoints.
