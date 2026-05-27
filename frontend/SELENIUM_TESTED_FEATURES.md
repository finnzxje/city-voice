# Selenium Tested Features

File này là mục lục tổng cho các chức năng đã được test bằng Selenium.

## Trang Chủ Public

Script:

```bash
npm run test:selenium
```

File test:

```text
selenium/home.test.mjs
```

Chức năng đã kiểm tra:

- Mở trình duyệt Chrome bằng Selenium.
- Truy cập trang chủ public `/`.
- Kiểm tra nội dung thương hiệu `CityVoice`.
- Kiểm tra nội dung hero cũ đã chuyển từ Cypress sang Selenium:
  - `Cùng nhau xây dựng`
  - `Gửi báo cáo ngay`
- Kiểm tra khu vực bản đồ sự cố cộng đồng hiển thị.
- Kiểm tra khu vực thống kê cộng đồng hiển thị.

## Citizen Tests

Xem file riêng:

```text
SELENIUM_CITIZEN_TESTS.md
```

Script chính:

```bash
npm run test:selenium:citizen
```

Các nhóm chức năng:

- Đăng nhập citizen.
- Mở form gửi báo cáo dân sự.
- Upload ảnh bằng chứng.
- Nhập thông tin báo cáo.
- Gửi báo cáo dân sự.
- Kiểm tra báo cáo mới trên dashboard.

## Staff Tests

Xem file riêng:

```text
SELENIUM_STAFF_TESTS.md
```

Script chính:

```bash
npm run test:selenium:staff
```

Các nhóm chức năng:

- Đăng nhập staff.
- Mở danh sách và chi tiết báo cáo.
- Duyệt và phân công báo cáo.
- Nghiệm thu và đóng hồ sơ.

## Manager Tests

Xem file riêng:

```text
SELENIUM_MANAGER_TESTS.md
```

Script chính:

```bash
npm run test:selenium:manager
```

Các nhóm chức năng:

- Đăng nhập manager.
- Xem analytics dashboard.
- Mở và áp dụng bộ lọc.
- Trigger export Excel.
- Trigger export PDF.

## Admin Tests

Xem file riêng:

```text
SELENIUM_ADMIN_TESTS.md
```

Script chính:

```bash
npm run test:selenium:admin
```

Các nhóm chức năng:

- Đăng nhập admin.
- Xem danh sách user.
- Đổi role user.
- Xem danh sách category.
- Tạo category mới.

## Chưa Được Selenium Test

Các phần sau chưa có Selenium test tự động:

- Register citizen.
- Login bằng OTP.
- Staff reject report.
- Admin user role management.
- Notification UI.
- Export PDF/Excel.
