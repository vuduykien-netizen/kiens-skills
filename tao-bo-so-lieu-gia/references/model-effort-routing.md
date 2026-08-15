# Định tuyến model và reasoning effort

Đề xuất theo model đang thực sự khả dụng tại runtime. Nếu tên model khác bảng dưới đây, ánh xạ theo vai trò `efficient`, `balanced` hoặc `frontier`; khi thông tin hiện hành không chắc chắn, dùng `$openai-docs` để kiểm tra trước khi nêu tên model.

## Nguyên tắc

- Bắt đầu bằng cấu hình nhỏ nhất có khả năng đạt tiêu chí hoàn tất.
- Dùng `low` cho tác vụ thường quy, ít mơ hồ và ưu tiên tốc độ.
- Dùng `medium` làm mức cân bằng mặc định cho viết script và xử lý nhiều bước.
- Chỉ tăng `high` hoặc `xhigh` khi độ phức tạp, rủi ro riêng tư hoặc kiểm định thực tế cho thấy có lợi.
- Chỉ đề xuất `max` cho trường hợp khó nhất, ưu tiên chất lượng, có tiêu chí đánh giá rõ; so sánh với `xhigh` trước.
- Chỉ đề xuất Pro mode cho audit khó, giá trị cao khi lợi ích chất lượng dự kiến đáng với độ trễ/chi phí; không dùng cho công việc thường quy.

## Ánh xạ ưu tiên khi GPT-5.6 khả dụng

| Vai trò | Model | Baseline effort | Dùng cho |
|---|---|---|---|
| `efficient` | `gpt-5.6-luna` | `low` | Thu thập tham số, cập nhật trạng thái, hướng dẫn chạy đơn giản |
| `balanced` | `gpt-5.6-terra` | `medium` | Viết script chuẩn, sinh `schema_only`, manifest và kiểm tra thường quy |
| `frontier` | `gpt-5.6-sol` | `high` | Riêng tư, debug phức tạp, ràng buộc nhiều biến và audit cuối |

## Mặc định theo giai đoạn

| Giai đoạn | Đề xuất mặc định | Tăng cấu hình khi |
|---|---|---|
| Cổng 1 — xác định nguồn/cấu hình | `efficient / low` | Nguồn, phạm vi hoặc ranh giới riêng tư mơ hồ: `balanced / medium` |
| Cổng 2 — viết script metadata | `balanced / medium` | Cú pháp đa phiên bản, schema phức tạp hoặc lỗi khó tái hiện: `frontier / high` |
| Cổng 2 — duyệt an toàn metadata | `frontier / high` | Quần thể nhỏ/bệnh hiếm, nhiều bán định danh hoặc `local_fit`: `frontier / xhigh` |
| Cổng 3 — sinh `schema_only` | `balanced / medium` | Nhiều nhánh, cụm, thời gian hoặc biến dẫn xuất: `frontier / high` |
| Cổng 3 — kiểm định riêng tư | `frontier / high` | `local_fit`, near-duplicate hoặc tổ hợp hiếm khó đánh giá: `frontier / xhigh` |
| Bàn giao — manifest/checksum | `balanced / medium` | Audit nhiều tệp hoặc lỗi không nhất quán: `frontier / high` |
| Audit cuối chất lượng cao | `frontier / high` | Chỉ cân nhắc `xhigh`/`max` hoặc Pro mode khi tiêu chí đánh giá và giá trị gia tăng rõ ràng |

## Mẫu trả lời sau mỗi giai đoạn

```text
Gợi ý bước tiếp theo
- Trạng thái hiện tại: <PASS|PENDING|FAIL và lý do>
- Việc làm ngay: <một hành động cụ thể>
- Cách làm và dấu hiệu hoàn tất: <hướng dẫn ngắn + điều kiện dừng>
- Bước kế tiếp sau đó: <xem trước một bước>
- Model / effort đề xuất: <vai trò; tên model khả dụng; effort>
- Điều kiện điều chỉnh: <khi nào tăng/hạ cấu hình>
```
