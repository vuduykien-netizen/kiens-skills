# Tham số runtime cho từng dự án

Master skill không lưu giá trị cụ thể. Thu thập hoặc xác nhận các tham số sau khi bắt đầu mỗi dự án.

| Tham số | Bắt buộc | Quy tắc |
|---|---:|---|
| `source_software` | Có | `spss`, `stata` hoặc `r` |
| `source_format` | Có | Định dạng phù hợp với phần mềm nguồn |
| `source_path` | Có | Đường dẫn local; phân loại `LOCAL_ONLY` |
| `project_root` | Có | Thư mục đích do người dùng chọn; không nằm trong thư mục skill |
| `synthetic_n` | Bắt buộc trước Cổng 3 | Phải hỏi trực tiếp người dùng số dòng/đối tượng giả mong muốn; chỉ nhận số nguyên dương, không suy đoán hoặc đặt mặc định |
| `seed` | Khi sinh dữ liệu | Số nguyên cố định; có thể dùng mặc định do skill chọn và phải ghi vào cấu hình dự án |
| `special_missing_codes` | Không | Mặc định rỗng; không suy đoán từ dự án trước |
| `small_cell_threshold` | Không | Mặc định cảnh báo `10`, trừ khi chính sách dự án quy định khác |
| `synthesis_mode` | Không | `schema_only` mặc định; `approved_aggregates` hoặc `local_fit` cần đủ điều kiện |
| `output_format` | Khi sinh dữ liệu | Chọn theo công cụ và nhu cầu kiểm thử của dự án |

## Mẫu cấu hình dự án

Chỉ tạo mẫu sau trong `<project-root>/01_gate1_source/project_config.yaml`; không điền giá trị thật vào master skill.

```yaml
source_software: "<spss|stata|r>"
source_format: "<format>"
synthetic_n: "<positive-integer-or-pending>"
seed: "<integer>"
special_missing_codes: []
small_cell_threshold: 10
synthesis_mode: "schema_only"
output_format: "<format>"
```

Khi `synthetic_n` chưa được trả lời, ghi `pending` trong cấu hình dự án, nhắc lại câu hỏi trước Cổng 3 và không sinh dữ liệu giả. Ghi `source_path` riêng trong `<project-root>/01_gate1_source/source_pointer.txt` với nhãn `LOCAL_ONLY`. Không đưa đường dẫn này vào manifest chia sẻ, log chung, báo cáo AI hoặc gói bàn giao.
