# Kế hoạch mobile cho chức năng Update a Portfolio

## 1. Kết luận sau khi đối chiếu backend

UC-S4-PORT-02 hiện được backend hỗ trợ và compatibility gate đã đạt. Đã đối chiếu trực tiếp routes, controller, schema, service, repository, OpenAPI registry và test tại `D:\wdp\ittalent-backend\tests\unit\portfolio-links` cùng `tests\integration\portfolio-links.integration.test.ts`.

Contract thực tế:

- `PATCH /api/v1/me/portfolio-links/{id}` với JSON body strict, không có idempotency header.
- `expectedVersion` (integer, >= 1) là bắt buộc. Có thể gửi partial `title`, `url`, `description`; phải có ít nhất một field thay đổi bên cạnh version.
- Field vắng mặt được giữ nguyên; `description: null`, `""` hoặc toàn khoảng trắng đều clear description.
- URL được backend kiểm tra/sanitize thành external HTTP hoặc HTTPS URL an toàn và normalize bằng `new URL(value).toString()`; URL normalized là unique theo owner.
- Thành công trả `200` với item đầy đủ. Cập nhật thực sự tăng version đúng một lần; no-op hoặc retry của thay đổi đã commit trả item hiện có mà không tăng version thêm.
- `409 VERSION_CONFLICT` cho version stale, `409 DUPLICATE_PORTFOLIO_URL` cho URL trùng, `404` chung cho missing/foreign, và `503` khi storage không khả dụng. Backend test xác nhận ownership, concurrency, duplicate và clear-description.

Mobile sử dụng stable item ID và version do server trả về, chỉ gửi diff, và không gọi API cho no-op ở UI.

## 2. Contract backend hiện có mà mobile phải giữ nguyên

Các điểm đã được xác nhận trực tiếp từ backend:

- Candidate role có giá trị `user`; create/delete yêu cầu tài khoản Active và email đã xác minh.
- Portfolio ID là Mongo ObjectId.
- Version bắt đầu từ `1`.
- Title tối đa 200 ký tự.
- Description là optional, khi trả về có thể là `null`, tối đa 1000 ký tự khi có giá trị.
- URL tối đa 2048 ký tự; backend chấp nhận safe external HTTP hoặc HTTPS URL, cấm credential, localhost, private/local/internal host và private IP ranges.
- URL được chuẩn hóa bằng `new URL(value).toString()`.
- URL là unique theo cặp owner + normalized URL.
- Duplicate create trả 409 với code `DUPLICATE_PORTFOLIO_URL`.
- Delete dùng `expectedVersion` ở query, trả 409 `VERSION_CONFLICT` khi stale.
- Missing hoặc foreign item trả cùng 404 và không lộ metadata.
- Storage failure trả 503.
- Response item hiện có `id`, `title`, `url`, `description`, `version`, `createdAt`, `updatedAt`.
- Backend không fetch hoặc xác minh nội dung website bên ngoài.
- Delete là hard delete trong model hiện tại; backend chưa có trường `status` hoặc `available` cho portfolio.

Mobile phải ưu tiên các quy tắc này hơn giả định trong tài liệu nghiệp vụ nếu hai bên chưa đồng bộ. Không sửa DOCX nguồn để hợp thức hóa khác biệt.

## 3. Cổng tương thích trước khi code

Trước mỗi lần bắt đầu implementation, kiểm tra lại các file backend sau ở chế độ read-only:

- `src/modules/portfolio-links/portfolio-links.routes.ts`
- `src/modules/portfolio-links/portfolio-links.controller.ts`
- `src/modules/portfolio-links/portfolio-links.schemas.ts`
- `src/modules/portfolio-links/portfolio-links.service.ts`
- `src/modules/portfolio-links/portfolio-links.repository.ts`
- `src/modules/portfolio-links/portfolio-links.openapi.ts`
- `src/modules/portfolio-links/portfolio-links.constants.ts`
- `src/models/portfolio-link.model.ts`
- Test portfolio trong `tests/unit/portfolio-links/` và `tests/integration/portfolio-links.integration.test.ts`

Chỉ được tiếp tục code mobile khi tất cả điều kiện sau đã đúng:

1. Backend có route update thật và route đã được đăng ký.
2. Request schema và response schema đã rõ ràng.
3. OpenAPI có cùng method, path, payload và response codes với code chạy thật.
4. Backend test xác nhận optimistic concurrency và ownership.
5. Quy ước clear description đã được chốt bằng contract, không chỉ bằng suy đoán.

Nếu một điều kiện chưa đạt, dừng implementation mobile, ghi blocker cụ thể và không tạo UI chết hoặc API call không tồn tại.

## 4. Contract update backend cần có trước khi mobile triển khai

Phần này là yêu cầu tích hợp, không phải contract hiện đã tồn tại. Backend team cần cung cấp contract thực tế tương đương các khả năng sau:

- Update một portfolio link theo stable ID.
- Body có `expectedVersion` bắt buộc.
- Cho phép partial update title, URL và description.
- Từ chối body chỉ có `expectedVersion` hoặc định nghĩa rõ no-op behavior.
- Recheck Candidate authority, owner, record existence và version trước commit.
- Normalize và validate URL bằng cùng rule của create.
- Giữ unique owner + normalized URL và trả error code rõ ràng khi trùng.
- Tăng version đúng một lần khi metadata thay đổi.
- Không thay đổi snapshot của application đã nộp.
- Trả item đầy đủ theo `portfolioLinkResponseSchema` hiện hành.
- Có response rõ cho 400, 401, 403, 404, 409 version conflict, 409 duplicate URL và 503.
- Quy định rõ: field description vắng mặt là preserve; giá trị nào là explicit clear.

Method, path, payload và error code cuối cùng phải lấy từ implementation/OpenAPI backend, không lấy từ ví dụ trong kế hoạch này. Nếu backend chọn contract khác Certificate, mobile phải theo Portfolio backend.

## 5. Kế hoạch mobile sau khi backend sẵn sàng

### Bước 1: Đồng bộ DTO và constants theo response thật

Files dự kiến:

- `lib/features/applicant/portfolio/portfolio_providers.dart`
- `lib/features/applicant/portfolio/portfolio_constants.dart`

Thực hiện:

- Chỉ thêm field response mà UI hoặc conflict flow thực sự cần; không bắt buộc parse `createdAt`/`updatedAt` nếu không dùng.
- Thêm error code đúng như backend công bố, không suy đoán tên code.
- Thêm `PortfolioDraft` nếu giúp tạo payload diff rõ ràng; không tạo thêm repository/service wrapper.

### Bước 2: Thêm update action theo đúng contract backend

File: `lib/features/applicant/portfolio/portfolio_providers.dart`

- Thêm `PortfolioActions.update` dùng method/path/body thực tế từ backend.
- Luôn dùng `current.id` và `current.version`; không gửi owner ID.
- Chỉ gửi field thay đổi nếu backend hỗ trợ partial update.
- Clear description đúng theo schema backend; nếu backend chưa hỗ trợ clear thì UI không được giả vờ đã clear.
- No-op không gọi API nếu contract backend không yêu cầu ghi nhận no-op.
- Parse item server trả về và invalidate `portfolioProvider` sau thành công.
- Không tự tăng version phía client.

### Bước 3: Dùng chung form add và edit

File: `lib/features/applicant/portfolio/widgets/portfolio_form_page.dart`

- Cho form nhận `PortfolioLink? existing` và prefill title, URL, description.
- Giữ create idempotency key riêng cho POST; không gửi header đó cho update nếu backend không yêu cầu.
- Đổi title/nút submit theo add hoặc edit.
- Hiển thị version hiện tại và thông báo application snapshot cũ không thay đổi.
- Validation phía client phải phù hợp backend: chấp nhận HTTP/HTTPS nếu backend vẫn cho phép; server validation là thẩm quyền cuối cùng.
- Giữ dữ liệu nhập khi validation, 409 hoặc 503 xảy ra.
- Không fetch/probe URL.

### Bước 4: Nối Edit vào menu và màn hình

Files:

- `lib/features/applicant/portfolio/widgets/portfolio_sheets.dart`
- `lib/features/applicant/portfolio/portfolio_screen.dart`

Thực hiện:

- Thêm `PortfolioMenuAction.edit` với icon pencil giữa Open link và Delete.
- Mở form edit bằng item hiện tại.
- Sau thành công, refresh list và hiển thị toast Saved.
- Không thêm route edit riêng và không thêm dependency.

### Bước 5: Xử lý lỗi theo backend

Files:

- `lib/features/applicant/portfolio/widgets/portfolio_sheets.dart`
- `lib/features/applicant/portfolio/widgets/portfolio_form_page.dart`

Thực hiện:

- Version conflict: hiển thị Load latest, invalidate list và đóng form khi người dùng xác nhận; không tự merge hoặc overwrite.
- 404 missing/foreign: hiển thị một trạng thái unavailable chung, refresh list, không lộ metadata.
- Duplicate URL: chỉ gắn lỗi URL nếu backend trả code tương ứng cho update.
- 400 validation: ưu tiên field details nếu contract cung cấp; nếu không, dùng thông báo validation/update chung.
- 401/403: để auth flow hiện có xử lý session, đồng thời không báo thành công.
- 503/unknown: giữ form và dữ liệu nhập để retry.

### Bước 6: Localization

Files:

- `assets/translations/en.json`
- `assets/translations/vi.json`

Thêm key đồng nhất EN/VI cho menu Edit, edit title, save, success, update failure, conflict, unavailable và snapshot notice. Không hardcode text trong widget.

### Bước 7: Tests

File chính: `test/features/applicant/portfolio_screen_test.dart`

Test phải dựa trên contract backend đã xác nhận:

1. Menu mở form edit và prefill dữ liệu.
2. Request update dùng đúng method/path/body/version.
3. Payload diff/no-op theo schema backend.
4. Clear description theo contract backend.
5. URL HTTP/HTTPS và invalid URL phù hợp rule backend.
6. Update thành công refresh list và hiển thị item/version server trả về.
7. Version conflict không overwrite và có Load latest.
8. 404 dùng trạng thái unavailable chung.
9. Duplicate URL theo error code backend.
10. 400/503 giữ dữ liệu form và không báo thành công.
11. Create/list/delete tests hiện có vẫn pass.

## 6. Trình tự thực hiện

1. Kiểm tra backend compatibility gate.
2. Nếu backend chưa có update endpoint: dừng và báo blocker; không sửa mobile feature.
3. Nếu backend đã có: cập nhật phần contract trong kế hoạch bằng method/path/schema/error thực tế.
4. Implement mobile theo các bước 1-7 ở trên.
5. Chạy `dart format .` cho file đã sửa.
6. Chạy `flutter analyze`.
7. Chạy test portfolio liên quan, sau đó `flutter test` toàn bộ theo `AGENTS.md`.
8. Kiểm tra `git diff` để chắc chắn không sửa DOCX, backend hoặc file ngoài phạm vi.

## 7. Tiêu chí hoàn thành

- Không có API call mobile nào trỏ tới endpoint chưa tồn tại.
- Mobile request/response/error handling khớp backend và OpenAPI hiện hành.
- Stable ID và server-provided version được dùng đúng; không gửi owner ID và không tự tăng version.
- Conflict, missing/foreign, duplicate, validation và storage failure không tạo false success.
- Application snapshot cũ không bị thay đổi và UI giải thích đúng phạm vi update.
- Không fetch/probe URL và không sửa DOCX nguồn.
- Không thêm dependency, route hoặc abstraction không cần thiết.
- Format, analyze và toàn bộ test pass.

## 8. Ngoài phạm vi của nhánh mobile

- Không tự triển khai hoặc sửa backend trong nhánh `feat/update-a-portfolio`.
- Không sửa `D:\wdp\S3+S4.updated.docx`.
- Không thêm search/filter/select-default cho Portfolio.
- Không thay đổi create/delete/list ngoài refactor tối thiểu cần cho form dùng chung.
