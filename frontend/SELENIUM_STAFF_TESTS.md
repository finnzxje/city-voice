# Selenium Staff Tests

File này ghi riêng các chức năng staff đã được chạy bằng Selenium.

## Script

Chạy luồng staff:

```bash
npm run test:selenium:staff
```

File test:

```text
selenium/staff-workflow.test.mjs
```

Mặc định test dùng mock API tại:

```text
http://127.0.0.1:18080/api
```

Vì vậy không cần bật backend Spring Boot.

## Tóm Tắt Luồng Test

- `selenium/staff-workflow.test.mjs`
  - Khởi động mock API nội bộ.
  - Mở Chrome.
  - Mở trang `/login`.
  - Chọn tab `Cán bộ`.
  - Đăng nhập staff.
  - Đợi trang `Quản lý báo cáo sự cố` hiển thị.
  - Kiểm tra danh sách báo cáo có dữ liệu.
  - Mở chi tiết báo cáo.
  - Chọn mức ưu tiên `cao`.
  - Bấm `Duyệt & Phân công`.
  - Kiểm tra trạng thái chuyển sang `Đang xử lý`.
  - Kiểm tra module `Nghiệm thu` xuất hiện.
  - Upload ảnh nghiệm thu.
  - Nhập ghi chú hoàn thành.
  - Bấm `Hoàn thành & Đóng hồ sơ`.
  - Kiểm tra trạng thái chuyển sang `Đã giải quyết`.
  - Kiểm tra nhãn `ẢNH NGHIỆM THU` hiển thị.
  - Đóng Chrome.
  - Tắt mock API.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.


## 1. Đăng nhập staff

Chức năng đã kiểm tra:

- Mở trang `/login`.
- Chọn tab `Cán bộ`.
- Nhập email staff:

```text
staff@example.com
```

- Nhập mật khẩu:

```text
password123
```

- Bấm `Đăng nhập Hệ thống`.
- Mock API trả token và user role `staff`.
- App điều hướng tới staff dashboard.

Kết quả mong đợi:

- Staff đăng nhập thành công.
- Trang `Quản lý báo cáo sự cố` hiển thị.

## 2. Mở danh sách và chi tiết báo cáo

Chức năng đã kiểm tra:

- Mock API trả danh sách báo cáo.
- Staff thấy báo cáo:

```text
Cột đèn giao thông bị hỏng
```

- Staff bấm nút xem chi tiết.
- Trang chi tiết sự cố mở thành công.

Kết quả mong đợi:

- Danh sách báo cáo staff hiển thị dữ liệu.
- Trang chi tiết báo cáo hiển thị đúng tiêu đề và trạng thái ban đầu `Mới tiếp nhận`.

## 3. Duyệt và phân công báo cáo

Chức năng đã kiểm tra:

- Staff chọn priority:

```text
cao
```

- Staff bấm:

```text
Duyệt & Phân công
```

- Mock API nhận:

```text
PUT /api/reports/:id/review
```

- Report chuyển trạng thái:

```text
newly_received -> in_progress
```

Kết quả mong đợi:

- Trang chi tiết hiển thị trạng thái `Đang xử lý`.
- Module `Nghiệm thu` xuất hiện.

## 4. Nghiệm thu và đóng hồ sơ

Chức năng đã kiểm tra:

- Staff upload ảnh nghiệm thu.
- Staff nhập ghi chú hoàn thành:

```text
Đã thay thế bóng đèn và kiểm tra tín hiệu.
```

- Staff bấm:

```text
Hoàn thành & Đóng hồ sơ
```

- Mock API nhận:

```text
POST /api/reports/:id/resolve
```

- Report chuyển trạng thái:

```text
in_progress -> resolved
```

Kết quả mong đợi:

- Trang chi tiết hiển thị `Đã giải quyết`.
- Ảnh nghiệm thu hiển thị với nhãn `ẢNH NGHIỆM THU`.

## API Mock Cho Staff Flow

Các endpoint được mock:

```text
POST /api/auth/staff/login
GET  /api/auth/me
GET  /api/reports
GET  /api/reports/:id
PUT  /api/reports/:id/review
PUT  /api/reports/:id/reject
POST /api/reports/:id/resolve
```

Ghi chú: endpoint reject đã được mock sẵn, nhưng hiện test staff chính chưa chạy nhánh từ chối.

## Chạy Chậm Để Quan Sát

Chạy mặc định:

```bash
npm run test:selenium:staff
```

Chạy chậm hơn:

```bash
SELENIUM_STEP_DELAY_MS=1500 SELENIUM_PAUSE_MS=10000 npm run test:selenium:staff
```

Chạy nhanh:

```bash
SELENIUM_STEP_DELAY_MS=0 SELENIUM_PAUSE_MS=0 npm run test:selenium:staff
```
