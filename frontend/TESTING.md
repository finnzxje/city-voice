# Frontend Testing Guide

Tài liệu này mô tả bộ test frontend CityVoice sau khi thống nhất dùng:

- **Jest + React Testing Library** cho unit test.
- **Selenium WebDriver** cho browser/e2e test.

Cypress đã được gỡ khỏi project.

## Công cụ đang dùng

- **Jest**: chạy unit test cho React component.
- **React Testing Library**: render component theo góc nhìn người dùng.
- **@testing-library/jest-dom**: thêm matcher dễ đọc như `toBeInTheDocument`.
- **@testing-library/user-event**: mô phỏng thao tác người dùng trong unit test.
- **Selenium WebDriver**: mở Chrome và tự thao tác trên web thật.
- **start-server-and-test**: tự khởi động Vite dev server rồi mới chạy Selenium.

## File cấu hình

- `jest.config.cjs`: cấu hình Jest cho React + TypeScript + jsdom.
- `tsconfig.jest.json`: TypeScript config riêng cho Jest.
- `src/test/setupTests.ts`: setup matcher Testing Library và polyfill `TextEncoder/TextDecoder`.
- `src/test/__mocks__/fileMock.ts`: mock asset import trong test.
- `selenium/home.test.mjs`: Selenium smoke test cho trang chủ.
- `selenium/citizen-report.test.mjs`: Selenium flow đăng nhập citizen và gửi báo cáo.
- `selenium/staff-workflow.test.mjs`: Selenium flow staff duyệt, phân công, và nghiệm thu báo cáo.
- `selenium/manager-dashboard.test.mjs`: Selenium flow manager xem analytics, filter, và export.
- `selenium/admin-workflow.test.mjs`: Selenium flow admin đổi role user và tạo category.
- `tsconfig.app.json`: exclude test files khỏi build production.
- `eslint.config.js`: thêm global cho Jest để lint file test không báo sai.

## Unit Test Hiện Có

- `src/components/Hero.test.tsx`
  - Kiểm tra headline, mô tả, nút CTA, ảnh hero, và card sự cố mới nhất.

- `src/components/Header.test.tsx`
  - Kiểm tra navigation khi chưa đăng nhập.
  - Kiểm tra link citizen và thao tác logout khi đã đăng nhập.

- `src/components/Stats.test.tsx`
  - Kiểm tra các chỉ số cộng đồng hiển thị đúng.

## Selenium Test Hiện Có

- `selenium/home.test.mjs`
  - Mở Chrome.
  - Truy cập trang chủ `/`.
  - Kiểm tra các nội dung chính của landing page.

- `selenium/citizen-report.test.mjs`
  - Mở Chrome.
  - Đăng nhập citizen.
  - Mở form gửi báo cáo.
  - Upload ảnh.
  - Chọn danh mục.
  - Nhập tiêu đề, mô tả, tọa độ.
  - Submit báo cáo.
  - Kiểm tra báo cáo mới xuất hiện trên dashboard.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.

- `selenium/staff-workflow.test.mjs`
  - Mở Chrome.
  - Đăng nhập staff.
  - Mở danh sách báo cáo.
  - Mở chi tiết báo cáo mới tiếp nhận.
  - Chọn priority.
  - Duyệt và phân công báo cáo.
  - Upload ảnh nghiệm thu.
  - Hoàn thành và đóng hồ sơ.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.

- `selenium/manager-dashboard.test.mjs`
  - Mở Chrome.
  - Đăng nhập manager.
  - Xem analytics dashboard.
  - Mở filter.
  - Chọn priority.
  - Trigger export Excel/PDF.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.

- `selenium/admin-workflow.test.mjs`
  - Mở Chrome.
  - Đăng nhập admin.
  - Xem danh sách user.
  - Đổi role citizen sang manager.
  - Xem danh sách category.
  - Tạo category mới.
  - Mặc định dùng mock API nội bộ nên không cần bật backend Spring Boot.

## Scripts

Chạy trong thư mục `frontend`:

```bash
npm test
```

Chạy toàn bộ unit test bằng Jest.

```bash
npm test -- --runInBand
```

Chạy Jest tuần tự, hữu ích khi muốn output ổn định trong terminal hoặc CI.

```bash
npm run test:watch
```

Chạy Jest ở watch mode khi đang phát triển.

```bash
npm run test:coverage
```

Chạy Jest và xuất coverage report.

```bash
npm run test:selenium
```

Tự khởi động Vite dev server tại `http://127.0.0.1:5173`, rồi chạy Selenium smoke test trang chủ.

```bash
npm run test:e2e
```

Alias cho `npm run test:selenium`. Browser/e2e test hiện dùng Selenium.

```bash
npm run selenium:run
```

Chạy Selenium smoke test trực tiếp. Lệnh này giả định dev server đã chạy sẵn.

```bash
npm run test:selenium:citizen
```

Tự khởi động Vite với mock API URL, mở Chrome, rồi chạy luồng đăng nhập citizen và gửi báo cáo.

```bash
npm run test:selenium:staff
```

Tự khởi động Vite với mock API URL, mở Chrome, rồi chạy luồng staff xử lý và nghiệm thu báo cáo.

```bash
npm run test:selenium:manager
```

Tự khởi động Vite với mock API URL, mở Chrome, rồi chạy luồng manager analytics/filter/export.

```bash
npm run test:selenium:admin
```

Tự khởi động Vite với mock API URL, mở Chrome, rồi chạy luồng admin user/category management.

```bash
npm run selenium:citizen
```

Chạy Selenium citizen flow trực tiếp. Lệnh này giả định dev server đã chạy sẵn với API phù hợp.

```bash
npm run selenium:staff
```

Chạy Selenium staff flow trực tiếp. Lệnh này giả định dev server đã chạy sẵn với API phù hợp.

```bash
npm run selenium:manager
npm run selenium:admin
```

Chạy Selenium manager/admin flow trực tiếp. Các lệnh này giả định dev server đã chạy sẵn với API phù hợp.

## Luồng Chạy Unit Test

1. Jest đọc `jest.config.cjs`.
2. Jest dùng môi trường `jsdom` để mô phỏng browser DOM.
3. `setupFilesAfterEnv` nạp `src/test/setupTests.ts`.
4. Các file khớp pattern `src/**/*.test.{ts,tsx}` được chạy.
5. Component được render bằng React Testing Library.
6. Test assert theo nội dung người dùng nhìn thấy, ví dụ heading, button, link.

## Luồng Chạy Selenium Trang Chủ

1. Chạy `npm run test:selenium`.
2. `start-server-and-test` gọi `npm run dev`.
3. Vite khởi động app trên port `5173`.
4. Tool đợi `http://127.0.0.1:5173` trả HTTP 200.
5. Sau khi app sẵn sàng, tool gọi `npm run selenium:run`.
6. Node chạy file `selenium/home.test.mjs`.
7. Selenium mở Chrome qua WebDriver.
8. Test truy cập trang chủ và kiểm tra nội dung chính.
9. Test kết thúc thì browser được đóng bằng `driver.quit()`.

## Luồng Selenium Đăng Nhập Và Gửi Báo Cáo

1. Chạy `npm run test:selenium:citizen`.
2. Script `dev:selenium` khởi động Vite với:

```bash
VITE_API_BASE_URL=http://127.0.0.1:18080/api
```

3. Selenium script tự dựng mock API tại `http://127.0.0.1:18080/api`.
4. Chrome mở trang `/login`.
5. Selenium nhập email/password citizen:

```text
citizen@example.com
password123
```

6. Mock API trả token và user citizen.
7. App redirect tới dashboard citizen.
8. Selenium mở `/reports/new`.
9. Selenium upload ảnh tạm, nhập tiêu đề, chọn danh mục, nhập mô tả và tọa độ.
10. Form được submit qua browser API `requestSubmit()`.
11. Mock API nhận `POST /api/reports`.
12. App quay về dashboard và Selenium kiểm tra báo cáo `Ổ gà trước cổng trường` có trạng thái `Mới tiếp nhận`.

## Chạy Chậm Để Quan Sát

Mặc định luồng citizen chạy chậm để dễ quan sát: mỗi bước dừng khoảng `900ms` và cuối test giữ browser `5000ms`.

Chạy chậm hơn:

```bash
SELENIUM_STEP_DELAY_MS=1500 SELENIUM_PAUSE_MS=10000 npm run test:selenium:citizen
```

Chạy nhanh:

```bash
SELENIUM_STEP_DELAY_MS=0 SELENIUM_PAUSE_MS=0 npm run test:selenium:citizen
```

Chạy headless:

```bash
SELENIUM_HEADLESS=true npm run test:selenium:citizen
```

## Dùng Backend Thật

Luồng citizen mặc định dùng mock API nên không cần backend. Nếu muốn test với backend thật:

1. Chạy backend Spring Boot và database.
2. Đảm bảo API base URL trỏ tới backend thật.
3. Chạy Selenium script với mock API tắt:

```bash
SELENIUM_USE_MOCK_API=false npm run selenium:citizen
```

Khi dùng backend thật, cần dữ liệu thật tương ứng: citizen account, category trong database, và endpoint submit report hoạt động.

## Luồng Selenium Staff

1. Chạy `npm run test:selenium:staff`.
2. Script `dev:selenium` khởi động Vite với:

```bash
VITE_API_BASE_URL=http://127.0.0.1:18080/api
```

3. Selenium script tự dựng mock API tại `http://127.0.0.1:18080/api`.
4. Chrome mở trang `/login`.
5. Selenium chọn tab `Cán bộ`.
6. Selenium nhập email/password staff:

```text
staff@example.com
password123
```

7. Mock API trả token và user role `staff`.
8. App redirect tới `/staff/reports`.
9. Selenium mở chi tiết báo cáo `Cột đèn giao thông bị hỏng`.
10. Selenium chọn priority `cao`.
11. Selenium bấm `Duyệt & Phân công`.
12. Mock API nhận `PUT /api/reports/:id/review` và chuyển báo cáo sang `in_progress`.
13. Selenium upload ảnh nghiệm thu.
14. Selenium nhập ghi chú hoàn thành.
15. Selenium bấm `Hoàn thành & Đóng hồ sơ`.
16. Mock API nhận `POST /api/reports/:id/resolve` và chuyển báo cáo sang `resolved`.
17. Selenium kiểm tra trang chi tiết hiển thị trạng thái `Đã giải quyết`.

## Quy Trình Thêm Unit Test Mới

1. Đặt file test cạnh component, ví dụ:

```text
src/components/MyComponent.test.tsx
```

2. Render component bằng React Testing Library:

```tsx
import { render, screen } from "@testing-library/react";
import MyComponent from "./MyComponent";

describe("MyComponent", () => {
  it("renders the main heading", () => {
    render(<MyComponent />);

    expect(screen.getByRole("heading", { name: /cityvoice/i })).toBeInTheDocument();
  });
});
```

3. Nếu component dùng router, bọc bằng `MemoryRouter`.
4. Nếu component dùng context, mock context hoặc render bằng provider thật.
5. Ưu tiên query theo vai trò/ngôn ngữ người dùng thấy: `getByRole`, `getByText`, `getByLabelText`.
6. Chạy:

```bash
npm test -- --runInBand
```

## Quy Trình Thêm Selenium Test Mới

1. Tạo file trong:

```text
selenium/
```

2. Đặt tên theo luồng test, ví dụ:

```text
staff-review.test.mjs
```

3. Viết test theo hành vi thật trên browser: mở trang, nhập dữ liệu, click, submit, assert kết quả.
4. Nếu cần API nhưng chưa muốn bật backend, tạo mock API trong chính file Selenium giống `citizen-report.test.mjs`.
5. Thêm script vào `package.json`, ví dụ:

```json
"selenium:staff": "node selenium/staff-review.test.mjs",
"test:selenium:staff": "start-server-and-test dev:selenium http://127.0.0.1:5173 selenium:staff"
```

## Quy Trình Kiểm Tra Trước Khi Commit

Nên chạy tối thiểu:

```bash
npm test -- --runInBand
npm run test:selenium
npm run test:selenium:citizen
npm run test:selenium:staff
npm run test:selenium:manager
npm run test:selenium:admin
```

Nếu đang thay đổi code app nhiều, chạy thêm:

```bash
npm run build
npm run lint
```

Hiện tại `build` và `lint` toàn repo có thể fail vì một số lỗi TypeScript/ESLint đã tồn tại trong source app, không phải do bộ test mới.
