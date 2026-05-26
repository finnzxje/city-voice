# CityVoice Quality Assurance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the QA section in `docs.tex` into a repeatable quality assurance process for CityVoice, beginning with regression coverage for the documented citizen authentication paths and then expanding to report workflow, RBAC, analytics, and release evidence.

**Architecture:** Treat QA as a project layer that maps requirements in `docs.tex` and the API flow documents to API, database, and test evidence. The first slice adds service-level characterization tests for existing citizen registration and login behavior; later slices add workflow integration tests, API smoke tests, and manual acceptance suites. Frontend and mobile code changes are intentionally out of scope for this plan because other team members own them.

**Tech Stack:** Java 21, Spring Boot 3.4.3, Maven, PostgreSQL/PostGIS, MinIO, Docker Compose, JUnit/MockMvc, optional k6/Testcontainers for broader automation.

---

## Context From `docs.tex`

Relevant QA requirements:

- Lines 1135-1147 define quality from business, operation, and development environments: correct workflow, traceability, RBAC, safe uploads, no invalid status jumps, performance, UI clarity, maintainability.
- Lines 1164-1178 define quality criteria for UC-01 through UC-08.
- Lines 1198-1210 define review/testing criteria for analysis, design, implementation, performance, and security.
- Lines 2659-2671 define implementation-level testing criteria: correct processing, state integrity, geospatial integrity, notification correctness, analytics, export, UI stability.
- Lines 2699-2771 define TC-01 through TC-25.

Current repo observations:

- Backend endpoints already exist for report submission, ownership lookup, review/reject/resolve in `backend/src/main/java/com/cityvoice/report/controller/ReportController.java`.
- Analytics endpoints already exist for stats, heatmap, Excel export, and PDF export in `backend/src/main/java/com/cityvoice/analytics/controller/AnalyticsController.java`.
- Category endpoints already exist in `backend/src/main/java/com/cityvoice/report/controller/CategoryController.java`.
- Backend has only the generated Spring context test today.
- The agreed citizen authentication rule is: self-registration includes a password, email verification is completed by OTP, and an active citizen may log in with either password or OTP. This matches `AuthController` and `AuthService`.
- Read-only frontend review found a separate defect: after requesting a citizen login OTP, switching to staff login or back to citizen password login leaves the email input disabled because `otpSent` is not cleared on those transitions in `frontend/src/pages/auth/Login.tsx`. Record this for the frontend owner; do not fix it in this backend/documentation QA effort.

## Target QA Deliverables

- `docs/qa/traceability-matrix.md`: UC/TC to API, UI screen, table, automated test, manual evidence.
- `docs/qa/manual-test-checklist.md`: repeatable manual acceptance checklist for demo/release.
- `backend/src/test/java/com/cityvoice/auth/service/AuthServiceTest.java`: first-slice regression evidence for citizen registration, email-verification gating, password login, and OTP login.
- `backend/src/test/java/com/cityvoice/...`: automated backend tests for TC-01 to TC-25 where backend-observable.
- `qa/api/cityvoice-smoke.http`: ordered smoke suite using seeded/dev accounts.
- `qa/performance/k6-cityvoice.js`: basic load scenarios for dashboard, heatmap, export, and upload.
- CI or local quality gate that runs backend tests and API/performance smoke checks.

## Quality Gates

Use these gates for every merge or demo build:

- Backend: `cd backend && ./mvnw test` passes.
- Authentication first slice: registration sends a verification OTP; a verified citizen can request an OTP or obtain tokens through password/OTP login; unverified accounts and invalid OTPs do not issue tokens.
- API smoke: TC-01, TC-09, TC-12, TC-14, TC-18, TC-21, TC-23 pass against Docker Compose environment.
- Security/RBAC: citizen cannot access other reports, non-manager cannot access analytics/export, non-admin cannot mutate categories.
- Data integrity: each accepted/rejected/resolved state change creates `status_history`; reject/resolve create both `email` and `in_app` notifications.

---

### Task 1: Create QA Traceability Matrix

**Files:**
- Create: `docs/qa/traceability-matrix.md`
- Read: `docs.tex`
- Read: `backend/src/main/java/com/cityvoice/report/controller/ReportController.java`
- Read: `backend/src/main/java/com/cityvoice/analytics/controller/AnalyticsController.java`
- Read: `backend/src/main/java/com/cityvoice/report/controller/CategoryController.java`

- [ ] **Step 1: Create the QA docs folder**

Run:

```bash
mkdir -p docs/qa
```

Expected: directory exists at `docs/qa`.

- [ ] **Step 2: Add traceability rows for all documented test cases**

Create `docs/qa/traceability-matrix.md` with this structure:

```markdown
# CityVoice QA Traceability Matrix

| TC | UC | Requirement | API | UI Surface | Data Tables | Automated Evidence | Manual Evidence | Status |
|---|---|---|---|---|---|---|---|---|
| TC-01 | UC-01 | Submit valid citizen report with default medium priority | POST /reports | Citizen submit client | reports, status_history, categories, administrative_zones | `ReportWorkflowIntegrationTest.tc01_validCitizenReportCreatesNewlyReceivedMediumPriorityReportAndInitialHistory` | Manual: submit report from citizen UI | Implemented (service integration) |
| TC-02 | UC-01 | Reject invalid image MIME | POST /reports | Citizen submit client | reports | Backend integration: PDF upload returns 4xx | Manual: upload PDF | Planned |
| TC-03 | UC-01 | Reject oversized image | POST /reports | Citizen submit client | reports | Backend integration: >10MB multipart returns 413/4xx | Manual: upload >10MB file | Planned |
| TC-04 | UC-01 | Reject coordinates outside HCMC | POST /reports | Citizen submit client | reports, administrative_zones | Backend integration with outside coordinate | Manual: submit outside coordinate | Planned |
| TC-05 | UC-01 | Reject unknown category | POST /reports | Citizen submit client | categories, reports | Backend integration with missing categoryId | Manual: tampered categoryId | Planned |
| TC-06 | UC-01 | Create initial status history | POST /reports | Not directly visible; report detail activity | reports, status_history | Repository assertion after TC-01 | Manual: inspect activity log or DB | Planned |
| TC-07 | UC-02 | Citizen sees own reports only | GET /reports/my | Citizen report history client | reports, users | Backend integration with two citizens | Manual: login citizen and view list | Planned |
| TC-08 | UC-02 | Citizen cannot view another citizen report | GET /reports/{id} | Citizen report detail client | reports, users | Backend integration expects 403 or 404 | Manual: direct URL/API call | Planned |
| TC-09 | UC-03 | Staff reviews report into in_progress | PUT /reports/{id}/review | Staff report detail | reports, status_history, users | Backend integration with staff token | Manual: staff accepts report | Planned |
| TC-10 | UC-03 | Reject duplicate review after processing | PUT /reports/{id}/review | Staff report detail | reports, status_history | Backend integration repeat call returns 400 | Manual: accept twice | Planned |
| TC-11 | UC-03 | Reject assignment to non-staff | PUT /reports/{id}/review | Staff report detail | users, reports | Backend integration assignedTo citizen returns 400 | Manual: tampered payload | Planned |
| TC-12 | UC-04 | Staff rejects newly_received report | PUT /reports/{id}/reject | Staff report detail | reports, status_history | Backend integration with note | Manual: reject report | Planned |
| TC-13 | UC-04 | Reject creates citizen notifications | PUT /reports/{id}/reject | Citizen notifications | notifications | Repository assertion finds email and in_app | Manual: citizen checks notifications | Planned |
| TC-14 | UC-05 | Assigned staff resolves report | POST /reports/{id}/resolve | Staff report detail | reports, status_history | Backend integration with proof image | Manual: resolve assigned report | Planned |
| TC-15 | UC-05 | Resolve requires proof image | POST /reports/{id}/resolve | Staff report detail | reports | Backend integration without image returns 400 | Manual: submit without image | Planned |
| TC-16 | UC-05 | Non-assigned staff cannot resolve | POST /reports/{id}/resolve | Staff report detail | reports, users | Backend integration staff B returns 403 | Manual: login as staff B | Planned |
| TC-17 | UC-05 | Resolve creates notifications and resolvedAt | POST /reports/{id}/resolve | Citizen notifications; report detail | reports, notifications | Repository assertion | Manual: citizen notification and detail | Planned |
| TC-18 | UC-06 | Manager loads stats | GET /analytics/stats | Manager dashboard | reports, categories, administrative_zones | Backend integration returns aggregate DTO | Manual: dashboard stats visible | Planned |
| TC-19 | UC-06 | Manager loads heatmap | GET /analytics/heatmap | Manager heatmap | reports | Backend integration returns coordinate list | Manual: heatmap points visible | Planned |
| TC-20 | UC-06 | Invalid date range rejected | GET /analytics/stats or /heatmap | Manager dashboard filters | reports | Backend integration from > to returns 400 | Manual: invalid date filter | Planned |
| TC-21 | UC-07 | Export PDF | GET /analytics/export/pdf | Manager export action | reports | Backend integration Content-Type application/pdf | Manual: file opens as PDF | Planned |
| TC-22 | UC-07 | Export Excel | GET /analytics/export/excel | Manager export action | reports | Backend integration xlsx Content-Type | Manual: file opens in spreadsheet app | Planned |
| TC-23 | UC-08 | Admin creates category | POST /categories | Admin categories tab | categories | Backend integration returns 201 | Manual: create category | Planned |
| TC-24 | UC-08 | Duplicate slug blocked | POST/PUT /categories | Admin categories tab | categories | Backend integration returns 409 | Manual: duplicate slug | Planned |
| TC-25 | UC-08 | Inactive category hidden from citizen form | GET /categories | Citizen submit form | categories | Backend integration excludes inactive | Manual: inactive category hidden | Planned |
```

- [ ] **Step 3: Commit traceability**

Run:

```bash
git add docs/qa/traceability-matrix.md
git commit -m "docs: add QA traceability matrix"
```

Expected: one docs commit.

---

### Task 2: Add Manual Acceptance Checklist

**Files:**
- Create: `docs/qa/manual-test-checklist.md`

- [ ] **Step 1: Create checklist**

Create `docs/qa/manual-test-checklist.md`:

```markdown
# CityVoice Manual QA Checklist

## Environment

- [ ] Docker Compose services are running: database, MinIO, backend.
- [ ] Any frontend verification owned by the separate frontend tester is coordinated before final release.
- [ ] Client applications used for manual QA point to the same backend base URL.
- [ ] Seeded admin account can log in.
- [ ] At least one citizen, one staff, one manager, and one admin account are available.

## Citizen Authentication

- [ ] New citizen registration requires an email and password and sends an email-verification OTP.
- [ ] A citizen cannot log in before completing email verification.
- [ ] A verified citizen can log in with email and password.
- [ ] A verified citizen can request and verify a login OTP.
- [ ] A login OTP cannot be reused after successful verification.
- [ ] Known frontend observation: after OTP is requested, switching login modes must re-enable the email field; report failure to the frontend owner without modifying frontend code in this QA slice.

## UC-01 Citizen Submit Report

- [ ] Citizen can load active categories.
- [ ] Citizen can submit valid title, description, category, JPEG image, and HCMC coordinates.
- [ ] Invalid MIME file is rejected with clear error text.
- [ ] Oversized image is rejected.
- [ ] Outside-HCMC coordinate is rejected.
- [ ] Created report appears with `newly_received`.
- [ ] Created report starts with default priority `medium`.

## UC-02 Citizen Track Report

- [ ] Citizen sees only their own reports.
- [ ] Direct access to another citizen report is blocked.
- [ ] Report detail shows title, description, category, image, location, current status, and activity.

## UC-03 Staff Review And Assign

- [ ] Staff sees newly received reports.
- [ ] Staff can confirm or change priority and choose an assignee.
- [ ] Successful review changes status to `in_progress`.
- [ ] A second review attempt is blocked.
- [ ] Assignment to a non-staff user is blocked.

## UC-04 Staff Reject

- [ ] Staff can reject a `newly_received` report with a note.
- [ ] Rejected report cannot be reviewed or resolved.
- [ ] Citizen receives in-app notification.

## UC-05 Staff Resolve

- [ ] Assigned staff can upload proof image and resolve report.
- [ ] Missing proof image is blocked.
- [ ] Different staff account cannot resolve the report.
- [ ] Citizen receives in-app notification.

## UC-06 Manager Analytics

- [ ] Manager can load stats.
- [ ] Manager can load heatmap.
- [ ] Filters for date, category, zone, and priority affect results.
- [ ] Invalid date range is rejected.
- [ ] Staff/citizen accounts cannot access analytics.

## UC-07 Export

- [ ] Manager can download PDF.
- [ ] Manager can download Excel.
- [ ] Downloaded files contain filtered report rows.
- [ ] Staff/citizen accounts cannot export.

## UC-08 Category Management

- [ ] Admin can create category.
- [ ] Duplicate slug is blocked.
- [ ] Admin can deactivate category.
- [ ] Inactive category is hidden from citizen submit form.
- [ ] Old reports still display their historical category.
```

- [ ] **Step 2: Commit checklist**

Run:

```bash
git add docs/qa/manual-test-checklist.md
git commit -m "docs: add manual QA checklist"
```

Expected: checklist available for demos and regression runs.

---

### Task 3: Establish Backend Test Structure

**Files:**
- Modify: `backend/pom.xml`
- Create: `backend/src/test/java/com/cityvoice/testsupport/TestUsers.java`
- Create: `backend/src/test/java/com/cityvoice/testsupport/TestImages.java`
- Create: `backend/src/test/java/com/cityvoice/report/ReportWorkflowIntegrationTest.java`
- Create: `backend/src/test/java/com/cityvoice/analytics/AnalyticsIntegrationTest.java`
- Create: `backend/src/test/java/com/cityvoice/report/CategoryIntegrationTest.java`

- [ ] **Step 1: Add integration test dependencies only if Docker-backed DB tests are chosen**

Recommended for PostGIS accuracy: add Testcontainers dependencies to `backend/pom.xml` under test dependencies:

```xml
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
```

Expected: Maven resolves test dependencies. If the team cannot download new dependencies, use the existing Docker Compose database at `localhost:5433` for integration tests and document the environment requirement in `docs/qa/manual-test-checklist.md`.

- [ ] **Step 2: Create image helper**

Create `backend/src/test/java/com/cityvoice/testsupport/TestImages.java`:

```java
package com.cityvoice.testsupport;

import org.springframework.mock.web.MockMultipartFile;

public final class TestImages {
    private TestImages() {
    }

    public static MockMultipartFile jpeg(String fieldName) {
        return new MockMultipartFile(
                fieldName,
                "incident.jpg",
                "image/jpeg",
                new byte[] {(byte) 0xff, (byte) 0xd8, (byte) 0xff, 0x00, 0x01, (byte) 0xff, (byte) 0xd9});
    }

    public static MockMultipartFile pdf(String fieldName) {
        return new MockMultipartFile(
                fieldName,
                "incident.pdf",
                "application/pdf",
                "%PDF-1.4".getBytes());
    }
}
```

- [ ] **Step 3: Write backend integration tests by UC group**

Use these test classes and scopes:

- `ReportWorkflowIntegrationTest`: TC-01 through TC-17.
- `AnalyticsIntegrationTest`: TC-18 through TC-22.
- `CategoryIntegrationTest`: TC-23 through TC-25.

Each test must set up users, categories, reports, and tokens through repositories/services, then call controller/API using `MockMvc` or service-level methods. Assertions must check HTTP result and database side effects.

**Incremental implementation status (updated 2026-05-26):**

| Test Case | Implemented Test Method | Coverage Boundary | Status |
|---|---|---|---|
| TC-01 | `ReportWorkflowIntegrationTest.tc01_validCitizenReportCreatesNewlyReceivedMediumPriorityReportAndInitialHistory` | Spring service/database integration with real PostgreSQL/PostGIS and mocked `StorageService` | Implemented and passed |

Verification evidence: `cd backend && ./mvnw clean test -Dtest=ReportWorkflowIntegrationTest` executed on 2026-05-26 with 1 test run, 0 failures, and 0 errors. This verifies category lookup, HCMC boundary/district queries, report persistence with default `medium` priority, and initial `status_history` persistence. HTTP authentication/multipart routing and real MinIO storage remain for later API/E2E coverage.

- [ ] **Step 4: Run backend tests**

Run:

```bash
cd backend
./mvnw test
```

Expected: all backend tests pass. Failures caused by missing PostGIS or MinIO test setup are fixed by either mocking `StorageService` in tests or running against Docker Compose services.

- [ ] **Step 5: Commit backend QA tests**

Run:

```bash
git add backend/pom.xml backend/src/test/java/com/cityvoice
git commit -m "test: cover CityVoice backend QA cases"
```

Expected: backend TC coverage is committed.

---

### Task 4: Add API Smoke Suite

**Files:**
- Create: `qa/api/cityvoice-smoke.http`
- Modify: `backend/http/*.http` if reusing current request files is cleaner

- [ ] **Step 1: Create smoke folder**

Run:

```bash
mkdir -p qa/api
```

- [ ] **Step 2: Add ordered smoke requests**

Create `qa/api/cityvoice-smoke.http` with sections:

```http
### 1. Staff login
POST http://localhost:8080/auth/staff/login
Content-Type: application/json

{
  "email": "admin@cityvoice.vn",
  "password": "Admin@123"
}

### 2. List active categories
GET http://localhost:8080/categories

### 3. Manager stats
GET http://localhost:8080/analytics/stats
Authorization: Bearer {{accessToken}}

### 4. Manager heatmap
GET http://localhost:8080/analytics/heatmap
Authorization: Bearer {{accessToken}}

### 5. Export PDF
GET http://localhost:8080/analytics/export/pdf
Authorization: Bearer {{accessToken}}

### 6. Export Excel
GET http://localhost:8080/analytics/export/excel
Authorization: Bearer {{accessToken}}
```

Add citizen submit/review/reject/resolve once the team standardizes how `.http` variables capture tokens and IDs in its editor.

- [ ] **Step 3: Run smoke manually**

Run Docker Compose:

```bash
docker compose up -d db minio backend
```

Expected: backend is reachable on `http://localhost:8080`.

Use the `.http` file in IntelliJ IDEA, VS Code REST Client, or another HTTP client and record pass/fail in the traceability matrix.

- [ ] **Step 4: Commit API smoke suite**

Run:

```bash
git add qa/api/cityvoice-smoke.http
git commit -m "test: add API smoke suite"
```

---

### Task 5: Add Security And RBAC Regression Tests

**Files:**
- Create: `backend/src/test/java/com/cityvoice/security/RbacIntegrationTest.java`
- Create: `docs/qa/security-checklist.md`

- [ ] **Step 1: Create RBAC tests**

Cover:

- Unauthenticated users cannot submit reports.
- Citizen cannot call `GET /reports` all-reports endpoint.
- Citizen cannot call `PUT /reports/{id}/review`.
- Staff cannot call `GET /analytics/stats`.
- Staff cannot call `POST /categories`.
- Manager can call analytics but cannot mutate categories.
- Admin can mutate categories.
- Citizen A cannot read citizen B report.

- [ ] **Step 2: Create manual security checklist**

Create `docs/qa/security-checklist.md`:

```markdown
# CityVoice Security QA Checklist

- [ ] JWT is required for protected report, analytics, admin, notification, and user endpoints.
- [ ] Role restrictions match the RBAC table in AGENTS.md.
- [ ] Citizen report ownership is enforced server-side.
- [ ] Upload accepts only allowed image MIME types.
- [ ] Oversized upload fails before persistence.
- [ ] Invalid status transition fails without writing partial data.
- [ ] OTP cannot be reused after verification.
- [ ] Refresh token cannot be reused after logout.
- [ ] Error responses do not expose stack traces or secrets.
- [ ] Seed passwords and JWT secrets are documented as dev-only.
```

- [ ] **Step 3: Run backend security tests**

Run:

```bash
cd backend
./mvnw test -Dtest=RbacIntegrationTest
```

Expected: RBAC tests pass.

- [ ] **Step 4: Commit security QA**

Run:

```bash
git add backend/src/test/java/com/cityvoice/security/RbacIntegrationTest.java docs/qa/security-checklist.md
git commit -m "test: add RBAC regression coverage"
```

---

### Task 6: Add Performance Smoke Testing

**Files:**
- Create: `qa/performance/k6-cityvoice.js`
- Create: `docs/qa/performance-baseline.md`

- [ ] **Step 1: Create performance script**

Create `qa/performance/k6-cityvoice.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '1m',
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1000'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const TOKEN = __ENV.ACCESS_TOKEN || '';

export default function () {
  const headers = TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {};

  const stats = http.get(`${BASE_URL}/analytics/stats`, { headers });
  check(stats, {
    'stats status is 200': (res) => res.status === 200,
  });

  const heatmap = http.get(`${BASE_URL}/analytics/heatmap`, { headers });
  check(heatmap, {
    'heatmap status is 200': (res) => res.status === 200,
  });

  sleep(1);
}
```

- [ ] **Step 2: Document baseline**

Create `docs/qa/performance-baseline.md`:

```markdown
# CityVoice Performance Baseline

## Baseline Environment

- Backend: local Docker Compose backend
- Database: PostgreSQL/PostGIS on Docker Compose
- Dataset: seeded development data plus QA-generated reports
- Load profile: 10 virtual users for 1 minute

## Acceptance Thresholds

- Failed HTTP requests below 5%.
- p95 response time below 1000ms for stats and heatmap.
- Export PDF/Excel manually verified under 5 seconds for development dataset.
- Upload report manually verified under 3 seconds for a JPEG below 10MB.

## Latest Result

Record date, commit hash, command, and observed k6 summary after each release candidate.
```

- [ ] **Step 3: Run performance smoke**

Run:

```bash
k6 run -e BASE_URL=http://localhost:8080 -e ACCESS_TOKEN=<manager-or-admin-token> qa/performance/k6-cityvoice.js
```

Expected: thresholds pass. If k6 is unavailable, record that performance smoke was skipped and run manual timing for stats, heatmap, export, and upload.

- [ ] **Step 4: Commit performance QA**

Run:

```bash
git add qa/performance/k6-cityvoice.js docs/qa/performance-baseline.md
git commit -m "test: add performance smoke baseline"
```

---

### Task 7: Add Release QA Command Script

**Files:**
- Create: `qa/run-local-quality-gate.sh`

- [ ] **Step 1: Create executable quality gate script**

Create `qa/run-local-quality-gate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR/backend"
./mvnw test
```

Then run:

```bash
chmod +x qa/run-local-quality-gate.sh
```

- [ ] **Step 2: Run the quality gate**

Run:

```bash
./qa/run-local-quality-gate.sh
```

Expected: all configured checks pass.

- [ ] **Step 3: Commit quality gate**

Run:

```bash
git add qa/run-local-quality-gate.sh
git commit -m "chore: add local QA quality gate"
```

---

### Task 8: Add Citizen Authentication Regression Coverage (First Execution Slice)

**Files:**
- Create: `backend/src/test/java/com/cityvoice/auth/service/AuthServiceTest.java`
- Read: `backend/src/main/java/com/cityvoice/auth/service/AuthService.java`
- Read: `backend/src/main/java/com/cityvoice/auth/controller/AuthController.java`

This task is intentionally the first execution slice. The authentication behavior already exists, so these are characterization/regression tests and are expected to pass when first added; no authentication implementation change is planned.

**Implementation status (updated 2026-05-26):**

| Test Case | Implemented Test Method | Test Type | Status |
|---|---|---|---|
| AUTH-01 | `AuthServiceTest.registrationHashesCitizenPasswordAndSendsVerificationOtp` | White-box service unit test with mocks | Implemented and developer-verified |
| AUTH-02 | `AuthServiceTest.verifiedCitizenCanLoginWithPassword` | White-box service unit test with mocks | Implemented and developer-verified |
| AUTH-03 | `AuthServiceTest.verifiedCitizenCanRequestLoginOtp` | White-box service unit test with mocks | Implemented and developer-verified |
| AUTH-04 | `AuthServiceTest.verifiedCitizenCanLoginWithOtp` | White-box service unit test with mocks | Implemented and developer-verified |
| AUTH-05 | `AuthServiceTest.unverifiedCitizenCannotLoginWithPassword` | White-box service unit test with mocks | Implemented and developer-verified |
| AUTH-06 | `AuthServiceTest.invalidLoginOtpDoesNotIssueTokens` | White-box service unit test with mocks | Implemented and developer-verified |

Verification note: an initial `cd backend && ./mvnw test -Dtest=AuthServiceTest` run on 2026-05-26 completed with 6 tests run, 0 failures, and 0 errors. A later run exposed stale IDE-generated output missing Lombok-generated `User` methods; `./mvnw clean test -Dtest=AuthServiceTest` rebuilt valid Maven output and passed with 6 tests run, 0 failures, and 0 errors. The developer then confirmed that `./mvnw test -Dtest=AuthServiceTest` passes locally after the clean rebuild. Live HTTP black-box/E2E authentication testing remains planned.

- [x] **Step 1: Add service regression tests for the documented citizen authentication contract**

Create `backend/src/test/java/com/cityvoice/auth/service/AuthServiceTest.java`:

```java
package com.cityvoice.auth.service;

import com.cityvoice.auth.dto.CitizenRegisterRequest;
import com.cityvoice.auth.dto.LoginRequest;
import com.cityvoice.auth.dto.OtpRequest;
import com.cityvoice.auth.dto.OtpVerifyRequest;
import com.cityvoice.auth.dto.TokenResponse;
import com.cityvoice.auth.entity.RefreshToken;
import com.cityvoice.security.JwtUtil;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.enums.OtpType;
import com.cityvoice.user.enums.UserRole;
import com.cityvoice.user.repository.RefreshTokenRepository;
import com.cityvoice.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private RefreshTokenRepository refreshTokenRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtUtil jwtUtil;
    @Mock
    private OtpService otpService;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(authService, "refreshExpirationMs", 604800000L);
    }

    @Test
    void registrationHashesCitizenPasswordAndSendsVerificationOtp() {
        CitizenRegisterRequest request = new CitizenRegisterRequest(
                "citizen@cityvoice.vn", "Citizen@123", "Test Citizen", "0900000000");
        when(userRepository.existsByEmail(request.email())).thenReturn(false);
        when(passwordEncoder.encode(request.password())).thenReturn("encoded-password");

        authService.registerCitizen(request);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User savedUser = captor.getValue();
        assertThat(savedUser.getEmail()).isEqualTo(request.email());
        assertThat(savedUser.getPasswordHash()).isEqualTo("encoded-password");
        assertThat(savedUser.getRole()).isEqualTo(UserRole.citizen);
        assertThat(savedUser.isActive()).isFalse();
        verify(otpService).sendVerificationOtp(savedUser);
    }

    @Test
    void verifiedCitizenCanLoginWithPassword() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));
        when(passwordEncoder.matches("Citizen@123", citizen.getPasswordHash())).thenReturn(true);
        stubTokens(citizen);

        TokenResponse response = authService.citizenLoginWithPassword(
                new LoginRequest(citizen.getEmail(), "Citizen@123"));

        assertThat(response.accessToken()).isEqualTo("access-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    void verifiedCitizenCanRequestLoginOtp() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));

        authService.requestLoginOtp(new OtpRequest(citizen.getEmail()));

        verify(otpService).sendLoginOtp(citizen);
    }

    @Test
    void verifiedCitizenCanLoginWithOtp() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));
        when(otpService.verifyOtp(citizen, "123456", OtpType.login)).thenReturn(true);
        stubTokens(citizen);

        TokenResponse response = authService.verifyLoginOtp(
                new OtpVerifyRequest(citizen.getEmail(), "123456"));

        assertThat(response.accessToken()).isEqualTo("access-token");
        assertThat(response.refreshToken()).isEqualTo("refresh-token");
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    void unverifiedCitizenCannotLoginWithPassword() {
        User citizen = activeCitizen();
        citizen.setActive(false);
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));

        assertThatThrownBy(() -> authService.citizenLoginWithPassword(
                new LoginRequest(citizen.getEmail(), "Citizen@123")))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        ex -> assertThat(ex.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));

        verifyNoInteractions(jwtUtil, refreshTokenRepository);
    }

    @Test
    void invalidLoginOtpDoesNotIssueTokens() {
        User citizen = activeCitizen();
        when(userRepository.findByEmail(citizen.getEmail())).thenReturn(Optional.of(citizen));
        when(otpService.verifyOtp(citizen, "000000", OtpType.login)).thenReturn(false);

        assertThatThrownBy(() -> authService.verifyLoginOtp(
                new OtpVerifyRequest(citizen.getEmail(), "000000")))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        ex -> assertThat(ex.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED));

        verifyNoInteractions(jwtUtil, refreshTokenRepository);
    }

    private User activeCitizen() {
        return User.builder()
                .id(UUID.fromString("11111111-1111-1111-1111-111111111111"))
                .email("citizen@cityvoice.vn")
                .passwordHash("encoded-password")
                .role(UserRole.citizen)
                .active(true)
                .build();
    }

    private void stubTokens(User citizen) {
        when(jwtUtil.generateAccessToken(citizen)).thenReturn("access-token");
        when(jwtUtil.generateRefreshToken(citizen)).thenReturn("refresh-token");
        when(jwtUtil.getAccessExpirationMs()).thenReturn(9000000L);
    }
}
```

- [x] **Step 2: Run only the citizen authentication regression tests**

Run:

```bash
cd backend
./mvnw test -Dtest=AuthServiceTest
```

Expected: `BUILD SUCCESS` with six passing tests, since the tests characterize the currently implemented contract.

- [ ] **Step 3: Record authentication traceability**

When `docs/qa/traceability-matrix.md` is created in Task 1, add these rows before the report use cases:

```markdown
| AUTH-01 | IAM | Citizen registration stores password and sends verification OTP | POST /auth/citizen/register | Citizen registration | users, otp_tokens | AuthServiceTest.registrationHashesCitizenPasswordAndSendsVerificationOtp | Manual: register and receive verification OTP | Planned |
| AUTH-02 | IAM | Verified citizen logs in with password | POST /auth/citizen/login | Citizen login | users, refresh_tokens | AuthServiceTest.verifiedCitizenCanLoginWithPassword | Manual: password login | Planned |
| AUTH-03 | IAM | Verified citizen requests a login OTP | POST /auth/citizen/request-otp | Citizen login | otp_tokens | AuthServiceTest.verifiedCitizenCanRequestLoginOtp | Manual: request OTP | Planned |
| AUTH-04 | IAM | Verified citizen logs in with OTP | POST /auth/citizen/verify-otp | Citizen login | otp_tokens, refresh_tokens | AuthServiceTest.verifiedCitizenCanLoginWithOtp | Manual: enter received OTP | Planned |
| AUTH-05 | IAM | Unverified citizen cannot log in | POST /auth/citizen/login | Citizen login | users | AuthServiceTest.unverifiedCitizenCannotLoginWithPassword | Manual: attempt login before verification | Planned |
| AUTH-06 | IAM | Invalid login OTP does not issue tokens | POST /auth/citizen/verify-otp | Citizen login | otp_tokens, refresh_tokens | AuthServiceTest.invalidLoginOtpDoesNotIssueTokens | Manual: enter invalid OTP | Planned |
```

- [ ] **Step 4: Commit the first backend QA slice**

Run:

```bash
git add backend/src/test/java/com/cityvoice/auth/service/AuthServiceTest.java docs/qa/traceability-matrix.md
git commit -m "test: cover citizen password and OTP authentication"
```

Expected: the first backend QA regression slice is committed without modifying frontend code.

---

## Suggested Execution Order

1. Start with Task 8 only: add citizen authentication regression tests and the authentication traceability rows.
2. Create the remaining QA docs: Tasks 1 and 2.
3. Add report workflow and RBAC backend tests: Tasks 3 and 5.
4. Add API smoke suite: Task 4.
5. Add performance/release gates: Tasks 6 and 7.

## Minimum Viable QA For A Course Demo

If time is short, complete these first:

- `docs/qa/traceability-matrix.md`
- `docs/qa/manual-test-checklist.md`
- Backend tests for AUTH-01 through AUTH-06
- Backend tests for TC-01, TC-04, TC-08, TC-09, TC-10, TC-12, TC-14, TC-16, TC-18, TC-21, TC-23, TC-24
- Manual run of all TC-01 through TC-25 with screenshots or recorded evidence

## Self-Review Checklist

- Every TC-01 through TC-25 from `docs.tex` maps to at least one verification path.
- Critical business invariants are automated on backend: ownership, RBAC, status transitions, status history, notifications, geospatial validation.
- Citizen authentication is explicitly covered as password or OTP after email verification, consistent with current backend behavior.
- Manual client checks focus on user-visible risk; frontend and mobile automated test coverage are delegated to separate owners.
- Performance testing is framed as a smoke baseline with explicit thresholds.
- The known frontend OTP mode-switch issue is recorded for the frontend owner and is not silently fixed as part of this plan.
