# Project Specification: CityVoice – Civic Issue Reporting Platform

## Overview

CityVoice is a civic infrastructure reporting platform scoped exclusively to **Ho Chi Minh City**. Citizens can submit geo-tagged incident reports, staff manage and resolve them, and managers access analytics and heatmaps. The application is built incrementally, module by module, with clarifying questions asked before each feature is implemented.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Spring Boot 3.4.3 (Maven) |
| Database | PostgreSQL 17 + PostGIS 3.5 (via Docker) |
| Migrations | Flyway (versioned SQL migrations) |
| Container | Docker Compose (`postgis/postgis:17-3.5`) |

**Local dev DB:** `localhost:5433` — user `cityvoice`, password `cityvoice_dev`, db `cityvoice`
*(Port 5433 used to avoid conflict with any existing local PostgreSQL on 5432)*

---

## Module 1: Infrastructure Incident Reporting (Citizen Facing)

- Citizens must be **authenticated** to submit a report (no anonymous submissions).
- Citizens upload a photo and select a category from the **dynamic `categories` table** (admin-configurable, not a hardcoded enum).
- GPS coordinates are extracted automatically (EXIF or device location).
- Before persisting, the backend validates:
  - Image payload: max file size + allowed MIME types.
  - GPS coordinates: must fall strictly within the **official HCMC administrative boundary** (`ST_Contains()` PostGIS query).
- On success: report is created with status `newly_received`, image uploaded to Cloud Storage, confirmation returned.

---

## Module 2: Workflow & Resolution Management (Staff Facing)

- Staff review incoming reports for authenticity.
- **Priority** (`low` / `medium` / `high` / `critical`) is set by **staff** during review — not by citizens on submission.
- Staff assign reports to a person/unit and transition to `in_progress`.
- **State machine (strictly enforced — no skipping):**
  ```
  newly_received → in_progress  (staff accepts)
  newly_received → rejected     (staff marks inauthentic)
  in_progress    → resolved     (staff uploads proof image)
  ```
- On resolution: staff uploads a proof-of-completion image. Status becomes `resolved` and notifications fire (email + in-app) to the reporting citizen.

---

## Module 3: Data Visualization & Analytics (Manager Facing)

- Heatmap of all geo-tagged reports overlaid on a map.
- Multi-criteria filtering: Timeframe, Category, Administrative Zone (any of 22 HCMC districts), Priority Level.
- Export reports (completion rates, avg resolution time) in **PDF and Excel** formats.

---

## Module 4: Identity & Access Management (System Core)

### Authentication
- **Citizens:** Register/login via Email + OTP (no password). OTP tokens stored in `otp_tokens` table with expiry.
- **Staff, Managers & Admins:** Login with pre-provisioned email + bcrypt password. Account provisioning is **hybrid**:
  - Initial staff and one admin account are seeded for testing via migration.
  - Admins can assign/change `staff`, `manager`, or `admin` roles to any user.

### RBAC (enforced at API level)

| Role | Permissions |
|---|---|
| `citizen` | Submit reports; view their own reports only |
| `staff` | View, assign, update status on reports |
| `manager` | Full access: analytics, heatmaps, and system-wide reports |
| `admin` | Superuser: all manager permissions + user role management, category management, system configuration |

### Audit Logging
Every state change is recorded in `status_history` with: timestamp, acting user, `from_status`, `to_status`, optional note.

---

## Notifications

Both **email** and **in-app** channels are supported via the `notifications` table (`channel` enum: `email` | `in_app`). Notifications are triggered automatically on status transitions.

---

## Database Schema

| Table | Purpose |
|---|---|
| `users` | All accounts (citizen / staff / manager) |
| `otp_tokens` | Time-limited OTP tokens for citizen auth |
| `administrative_zones` | HCMC city boundary + 22 district polygons (PostGIS MULTIPOLYGON) |
| `categories` | Admin-configurable incident categories |
| `reports` | Core incident entity with GPS `POINT` location |
| `status_history` | Immutable audit log of all state transitions |
| `notifications` | Email + in-app notification queue |

All schema changes are managed via **Flyway migrations** (`V{N}__{description}.sql`). Hibernate is set to `validate` mode — it never modifies the schema.

---

## Development Approach

- **Incremental**: one module at a time; clarifying questions asked before each feature.
- **Geospatial**: district boundaries use bounding-box polygons in dev. Replace with official OCHA HDX GeoJSON (Vietnam admin level 2) for production.
