# Selenium Admin Tests

File này ghi riêng các chức năng admin đã được chạy bằng Selenium.

## Script

Chạy luồng admin:

```bash
npm run test:selenium:admin
```

File test:

```text
selenium/admin-workflow.test.mjs
```

Mặc định test dùng mock API tại:

```text
http://127.0.0.1:18080/api
```

Vì vậy không cần bật backend Spring Boot.

## Tóm Tắt Luồng Test

- `selenium/admin-workflow.test.mjs`
  - Khởi động mock API nội bộ.
  - Mở Chrome.
  - Mở trang `/login`.
  - Chọn tab `Cán bộ`.
  - Đăng nhập admin.
  - Đợi trang `Quản lý quyền truy cập` hiển thị.
  - Kiểm tra danh sách user có dữ liệu.
  - Mở dropdown `Thay đổi vai trò` của citizen.
  - Đổi role citizen sang `manager`.
  - Kiểm tra role mới hiển thị trong bảng user.
  - Mở tab `Categories`.
  - Đợi trang `CẤU TRÚC PHẢN HỒI` hiển thị.
  - Mở modal `Tạo danh mục mới`.
  - Nhập tên, slug, icon cho danh mục mới.
  - Bấm `Tạo danh mục`.
  - Kiểm tra danh mục mới xuất hiện trong danh sách.
  - Đóng Chrome.
  - Tắt mock API.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.

## Luồng Chạy File MJS

Khi chạy:

```bash
npm run test:selenium:admin
```

Luồng chạy là:

1. `package.json` gọi script:

```bash
start-server-and-test dev:selenium http://127.0.0.1:5173 selenium:admin
```

2. `dev:selenium` khởi động Vite với API mock:

```bash
VITE_API_BASE_URL=http://127.0.0.1:18080/api vite
```

3. `start-server-and-test` đợi frontend sẵn sàng tại:

```text
http://127.0.0.1:5173
```

4. Sau khi frontend sẵn sàng, script `selenium:admin` được chạy:

```bash
node selenium/admin-workflow.test.mjs
```

5. File `.mjs` tự tạo mock API server.
6. File `.mjs` tạo Chrome WebDriver.
7. Selenium mở `/login`.
8. Selenium đăng nhập admin qua tab `Cán bộ`.
9. App điều hướng tới `/admin/users`.
10. Selenium đổi role của citizen.
11. Selenium mở `/admin/categories`.
12. Selenium tạo danh mục mới.
13. Cuối test đóng browser và mock API.

## Thứ Tự API Trong Admin Flow

```text
POST /api/auth/staff/login
GET  /api/auth/me
GET  /api/admin/users
GET  /api/admin/roles
PUT  /api/admin/users/:id/role
GET  /api/categories/all
POST /api/categories
GET  /api/categories/all
```

Một vài request có thể xuất hiện 2 lần trong dev mode do React Strict Mode hoặc component mount lại.
