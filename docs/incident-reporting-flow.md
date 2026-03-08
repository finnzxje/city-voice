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
[
  {
    "id": 1,
    "name": "Hư hỏng đường bộ",
    "slug": "hu-hong-duong-bo",
    "iconKey": "road_repair"
  }
]
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
- **`201 Created`**: Report saved successfully. Returns report details including the `incidentImageUrl` and assigned `administrativeZoneName`.
- **`400 Bad Request`**: Out of bounds (e.g., "Incident location is outside Ho Chi Minh City bounds"), invalid category, or bad multipart stream.
- **`413 Payload Too Large`**: Image exceeds 10MB.
- **`403 Forbidden`**: Admin/Staff tried to submit, or account is unverified.

---

## 3. Viewing Reports

### 3a. Citizen viewing their own history

A citizen can see a list of all reports they have ever submitted.

```http
GET /reports/my
Authorization: Bearer <citizenToken>
→ Returns Array of ReportResponse objects
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
```

---

## Report Status Lifecycle

The `currentStatus` field of a report maps to the PostgreSQL enumerator `report_status`:

1. `newly_received`: Default state upon submission.
2. `in_progress`: A staff member has been assigned and is working on the issue.
3. `resolved`: The issue has been fixed (usually accompanied by a `resolutionImageUrl`).
4. `rejected`: The report was deemed invalid, duplicate, or unactionable.

All status changes are tracked transactionally in the `status_history` table for auditing and transparency.
