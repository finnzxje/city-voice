# Selenium Manager Tests

File này ghi riêng các chức năng manager đã được chạy bằng Selenium.

## Script

Chạy luồng manager:

```bash
npm run test:selenium:manager
```

File test:

```text
selenium/manager-dashboard.test.mjs
```

Mặc định test dùng mock API tại:

```text
http://127.0.0.1:18080/api
```

Vì vậy không cần bật backend Spring Boot.

## Tóm Tắt Luồng Test

- `selenium/manager-dashboard.test.mjs`
  - Khởi động mock API nội bộ.
  - Mở Chrome.
  - Mở trang `/login`.
  - Chọn tab `Cán bộ`.
  - Đăng nhập manager.
  - Đợi dashboard `Tổng quan Phân tích` hiển thị.
  - Kiểm tra các KPI analytics.
  - Kiểm tra khu vực `Top Khu vực`.
  - Kiểm tra khu vực `Mức độ Ưu tiên`.
  - Mở panel `Bộ lọc`.
  - Chọn filter priority `high`.
  - Trigger export `Excel`.
  - Trigger export `PDF`.
  - Kiểm tra dashboard vẫn hiển thị dữ liệu phân tích.
  - Đóng Chrome.
  - Tắt mock API.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.

## Luồng Chạy File MJS

Khi chạy:

```bash
npm run test:selenium:manager
```

Luồng chạy là:

1. `package.json` gọi script:

```bash
start-server-and-test dev:selenium http://127.0.0.1:5173 selenium:manager
```

2. `dev:selenium` khởi động Vite với API mock:

```bash
VITE_API_BASE_URL=http://127.0.0.1:18080/api vite
```

3. `start-server-and-test` đợi frontend sẵn sàng tại:

```text
http://127.0.0.1:5173
```

4. Sau khi frontend sẵn sàng, script `selenium:manager` được chạy:

```bash
node selenium/manager-dashboard.test.mjs
```

5. File `.mjs` tự tạo mock API server.
6. File `.mjs` tạo Chrome WebDriver.
7. Selenium mở `/login`.
8. Selenium đăng nhập manager qua tab `Cán bộ`.
9. App điều hướng tới `/manager/dashboard`.
10. Selenium kiểm tra analytics, filter và export.
11. Cuối test đóng browser và mock API.

## Thứ Tự API Trong Manager Flow

```text
POST /api/auth/staff/login
GET  /api/auth/me
GET  /api/categories
GET  /api/analytics/stats
GET  /api/analytics/heatmap
GET  /api/analytics/export/excel
GET  /api/analytics/export/pdf
```

Một vài request có thể xuất hiện 2 lần trong dev mode do React Strict Mode hoặc component mount lại.
