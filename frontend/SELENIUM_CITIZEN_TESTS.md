# Selenium Citizen Tests

File này ghi riêng các chức năng citizen đã được chạy bằng Selenium.

## Script

Chạy luồng citizen:

```bash
npm run test:selenium:citizen
```

File test:

```text
selenium/citizen-report.test.mjs
```

Mặc định test dùng mock API tại:

```text
http://127.0.0.1:18080/api
```

Vì vậy không cần bật backend Spring Boot.

## Tóm Tắt Luồng Test

- `selenium/citizen-report.test.mjs`
  - Khởi động mock API nội bộ.
  - Mở Chrome.
  - Mở trang `/login`.
  - Đăng nhập citizen.
  - Đợi dashboard `Báo cáo của tôi` hiển thị.
  - Mở form `/reports/new`.
  - Upload ảnh bằng chứng.
  - Chọn danh mục.
  - Nhập tiêu đề, mô tả, tọa độ.
  - Submit báo cáo.
  - Đợi dashboard citizen tải lại.
  - Kiểm tra báo cáo mới xuất hiện trên dashboard.
  - Kiểm tra trạng thái `Mới tiếp nhận`.
  - Đóng Chrome.
  - Tắt mock API.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.


## 1. Đăng nhập citizen

Chức năng đã kiểm tra:

- Mở trang `/login`.
- Nhập email citizen:

```text
citizen@example.com
```

- Nhập mật khẩu:

```text
password123
```

- Bấm nút `Đăng nhập ngay`.
- Mock API trả access token, refresh token và thông tin user citizen.
- App điều hướng về dashboard citizen.
- Kiểm tra dashboard có tiêu đề `Báo cáo của tôi`.

Kết quả mong đợi:

- Citizen đăng nhập thành công.
- Header hiển thị tên user `Nguyen Van A`.
- Dashboard citizen hiển thị.

## 2. Mở form gửi báo cáo dân sự

Chức năng đã kiểm tra:

- Sau khi đăng nhập, Selenium mở route:

```text
/reports/new
```

- Kiểm tra form `Báo cáo Sự cố mới` hiển thị.
- Mock API trả danh sách danh mục:
  - `Hạ tầng đường bộ`
  - `Hệ thống chiếu sáng`

Kết quả mong đợi:

- Form gửi báo cáo mở được.
- Dropdown danh mục có dữ liệu.

## 3. Upload ảnh bằng chứng

Chức năng đã kiểm tra:

- Selenium tạo một file ảnh PNG tạm.
- Upload ảnh vào input `file-upload`.
- Form nhận file ảnh để chuẩn bị submit.

Kết quả mong đợi:

- Field ảnh hợp lệ.
- Form không bị chặn bởi validation thiếu ảnh.

## 4. Nhập thông tin báo cáo

Chức năng đã kiểm tra:

- Nhập tiêu đề:

```text
Ổ gà trước cổng trường
```

- Chọn danh mục:

```text
Hạ tầng đường bộ
```

- Nhập mô tả:

```text
Mặt đường hư hỏng cần xử lý để bảo đảm an toàn.
```

- Nhập tọa độ:

```text
Latitude: 10.7769
Longitude: 106.7009
```

- Kiểm tra các field `required` hợp lệ trước khi submit.

Kết quả mong đợi:

- Form có đầy đủ dữ liệu bắt buộc.
- Không còn field required nào invalid.

## 5. Gửi báo cáo dân sự

Chức năng đã kiểm tra:

- Submit form gửi báo cáo.
- Mock API nhận request:

```text
POST /api/reports
```

- Mock API trả report mới với trạng thái:

```text
newly_received
```

- App điều hướng về dashboard citizen.

Kết quả mong đợi:

- Gửi báo cáo thành công.
- Không hiển thị lỗi submit.

## 6. Kiểm tra báo cáo mới trên dashboard

Chức năng đã kiểm tra:

- Dashboard gọi mock API:

```text
GET /api/reports/my
```

- Kiểm tra báo cáo mới xuất hiện với tiêu đề:

```text
Ổ gà trước cổng trường
```

- Kiểm tra trạng thái hiển thị:

```text
Mới tiếp nhận
```

Kết quả mong đợi:

- Báo cáo mới hiển thị trong danh sách `Báo cáo của tôi`.
- Trạng thái đúng với workflow ban đầu của citizen report.

## API Mock Cho Citizen Flow

Các endpoint được mock:

```text
POST /api/auth/citizen/login
GET  /api/auth/me
GET  /api/categories
POST /api/reports
GET  /api/reports/my
```

## Chạy Chậm Để Quan Sát

Chạy mặc định:

```bash
npm run test:selenium:citizen
```

Chạy chậm hơn:

```bash
SELENIUM_STEP_DELAY_MS=1500 SELENIUM_PAUSE_MS=10000 npm run test:selenium:citizen
```

Chạy nhanh:

```bash
SELENIUM_STEP_DELAY_MS=0 SELENIUM_PAUSE_MS=0 npm run test:selenium:citizen
```
