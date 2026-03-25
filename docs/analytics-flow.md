# Module 3: Data Visualization & Analytics — Frontend Integration Guide

This document outlines the API contracts and intended frontend data flows for the **Analytics & Reporting** module of the CityVoice platform. This module is exclusively accessible to users with `MANAGER` or `ADMIN` roles.

## 1. Authentication & Authorization

All analytics endpoints are protected. The frontend must:
1. Ensure the user is logged in as a Staff/Admin (via `/auth/staff/login`).
2. Verify the user has either the `MANAGER` or `ADMIN` role.
3. Attach the JWT access token in the `Authorization: Bearer <token>` header for every request.
4. If a `403 Forbidden` is returned, the user lacks the necessary role and should be shown an appropriate error/redirect.

---

## 2. API Endpoints Overview

All analytics endpoints are under the `/api/analytics` prefix and share a common set of **optional query parameters** for filtering data:

### Common Filter Parameters
| Parameter | Type | Format | Description |
| :--- | :--- | :--- | :--- |
| `from` | string | `YYYY-MM-DD` | Start date (inclusive) |
| `to` | string | `YYYY-MM-DD` | End date (inclusive) |
| `categoryId` | integer | `1`, `2`, etc. | Filter by a specific incident category ID |
| `zoneId` | integer | `1`, `2`, etc. | Filter by a specific administrative zone ID |
| `priority` | string | `low`, `medium`, `high`, `critical` | Filter by incident priority level |

*Example query string:* `?from=2023-01-01&to=2023-12-31&priority=high&categoryId=3`

---

### Endpoint A: Heatmap Data (`GET /api/analytics/heatmap`)

**Purpose:** Returns a lightweight array of geo-coordinates to plot on a map library (like Leaflet.js `Leaflet.heat` or Google Maps Heatmap Layer).

**Response Format:**
```json
{
  "code": 200,
  "message": "Dữ liệu bản đồ nhiệt.",
  "data": [
    {
      "latitude": 10.7769,
      "longitude": 106.7009,
      "priority": "high",
      "category": "Giao thông"
    },
    // ...
  ]
}
```

**Frontend Implementation Notes:**
- Avoid rendering individual markers for this endpoint. Extract the `latitude` and `longitude` fields to create your heatmap data points.
- You can optionally use `priority` to apply different weights/colours to the heatmap points (e.g., `critical` = hot red, `low` = cool blue).

---

### Endpoint B: Aggregated Statistics (`GET /api/analytics/stats`)

**Purpose:** Returns high-level metrics and grouped breakdowns for rendering dashboard widgets (pie charts, bar charts, scorecards).

**Response Format:**
```json
{
  "code": 200,
  "message": "Thống kê báo cáo.",
  "data": {
    "totalReports": 125,
    "newlyReceived": 10,
    "inProgress": 45,
    "resolved": 68,
    "rejected": 2,
    "completionRate": 54.4,     // percentage
    "averageResolutionHours": 24.5,
    "byCategory": {
      "Giao thông": 80,
      "Môi trường": 45
    },
    "byPriority": {
      "critical": 15,
      "high": 30,
      "medium": 60,
      "low": 20
    },
    "byZone": {
      "Quận 1": 50,
      "Quận 3": 75
    }
  }
}
```

**Frontend Implementation Notes:**
- **Scorecards:** Use `totalReports`, `completionRate` (%), and `averageResolutionHours` to build top-level metric cards.
- **Charts:** The `byCategory`, `byPriority`, and `byZone` objects are returned as key-value maps. Object.keys() and Object.values() can easily map these into arrays suitable for Chart.js or Recharts components.

---

### Endpoint C: Export to Excel (`GET /api/analytics/export/excel`)

**Purpose:** Generates a downloadable `.xlsx` file containing the raw, filtered incident data with styled headers.

**Response Type:** Binary (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`)

---

### Endpoint D: Export to PDF (`GET /api/analytics/export/pdf`)

**Purpose:** Generates a downloadable `.pdf` file containing a formatted, printable table of the filtered incident data.

**Response Type:** Binary (`application/pdf`)

**Frontend Implementation Notes for Exports:**
Because these endpoints return binary files, modern fetch/axios implementations should handle them as `Blob` data.

Example snippet to handle file downloads in React/Vue:

```javascript
async function downloadExport(type, filters) {
  // type is 'excel' or 'pdf'
  const filterString = new URLSearchParams(filters).toString();
  const url = `/api/analytics/export/${type}?${filterString}`;

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${getToken()}`,
        "Accept": type === 'excel' ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" : "application/pdf"
      }
    });

    if (!response.ok) throw new Error("Export failed");

    // Extract filename from Content-Disposition header if possible, or fallback
    const disposition = response.headers.get('content-disposition');
    let filename = `cityvoice-reports.${type === 'excel' ? 'xlsx' : 'pdf'}`;
    if (disposition && disposition.indexOf('filename=') !== -1) {
      filename = disposition.split('filename=')[1].replace(/"/g, '');
    }

    // Convert response to Blob
    const blob = await response.blob();
    const downloadUrl = window.URL.createObjectURL(blob);
    
    // Create an invisible anchor tag to trigger the browser download
    const link = document.createElement("a");
    link.href = downloadUrl;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(downloadUrl);

  } catch (error) {
    console.error("Error downloading file:", error);
    // Show error toast to user
  }
}
```

## 3. Recommended Frontend Workflow

1. **Dashboard View:**
   - Display a unified Filter Bar at the top (Date Pickers, Category Dropdown, Zone Dropdown, Priority Dropdown).
   - On filter change, simultaneously fetch `GET /api/analytics/stats` and `GET /api/analytics/heatmap`.
   - Update your Scorecards, Pie/Bar Charts, and Map component accordingly.

2. **Actions Menu:**
   - Provide "Export to Excel" and "Export to PDF" buttons.
   - When clicked, trigger the `downloadExport` function (as shown above), passing in the *currently applied filters* from the Filter Bar so the exported document matches the on-screen dashboard view.
