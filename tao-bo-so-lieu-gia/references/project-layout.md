# Cấu trúc quản lý theo giai đoạn

Tất cả đường dẫn dưới đây tương đối với `<project-root>` được chọn tại runtime. Không ghi project root cụ thể vào master skill.

```text
project-root/
├── 00_project_control/
│   ├── PROJECT_STATUS.md
│   ├── RUN_ORDER.md
│   ├── MANIFEST_LOCAL_ONLY.tsv
│   └── MANIFEST_SHAREABLE.tsv
├── 01_gate1_source/
│   ├── source_pointer.txt
│   ├── project_config.yaml
│   └── decisions/
├── 02_gate2_metadata/
│   ├── scripts/
│   ├── runs_pending/
│   ├── reviewed/
│   └── guides/
├── 03_gate3_synthetic/
│   ├── specification/
│   ├── scripts/
│   ├── data_pending/
│   ├── data_safe/
│   ├── validation/
│   └── guides/
├── 04_handoff/
│   ├── audit/
│   ├── package/
│   └── checksums/
└── 90_archive/
    ├── metadata_runs/
    ├── synthetic_runs/
    └── replaced_files/
```

## Trạng thái và quyền chia sẻ

| Vị trí | Trạng thái | Chia sẻ |
|---|---|---|
| Dữ liệu thật ngoài project root | `LOCAL_ONLY` | Không |
| `02_gate2_metadata/runs_pending` | chưa duyệt | Không |
| `02_gate2_metadata/reviewed` | `SAFE_METADATA / ALLOW` | Có |
| `03_gate3_synthetic/data_pending` | `SYNTHETIC_PENDING` | Không |
| `03_gate3_synthetic/data_safe` | `SYNTHETIC_SAFE / ALLOW` | Có |
| `90_archive` | local audit | Không |

## Quy tắc phiên bản

- Đặt tên lần chạy: `run_YYYYMMDD_HHMMSS`.
- Không ghi đè thư mục lần chạy.
- Chỉ duy trì một bản hiện hành trong `reviewed` và một bộ hiện hành trong `data_safe`.
- Trước khi thay thế bản hiện hành, chuyển bản cũ vào archive với nguyên tên và log.
- Ghi seed trong tên file giả hoặc đặc tả.

## Manifest

`MANIFEST_SHAREABLE.tsv` gồm:

```text
path    size_bytes    sha256    classification    status
```

Không đưa manifest vào chính nó. Không đưa `source_pointer.txt`, pending, archive hoặc dữ liệu thật vào manifest SHAREABLE.

`MANIFEST_LOCAL_ONLY.tsv` chỉ ghi đường dẫn runtime và lý do giữ local; không đọc dữ liệu thật để tính checksum. Không sao chép manifest này vào thư mục master skill.

## Trạng thái và gợi ý chuyển bước

Sau mỗi giai đoạn, cập nhật cuối `00_project_control/PROJECT_STATUS.md` bằng khối:

```text
GỢI Ý BƯỚC TIẾP THEO
- Trạng thái hiện tại:
- Việc làm ngay:
- Cách làm và dấu hiệu hoàn tất:
- Bước kế tiếp sau đó:
- Model / reasoning effort đề xuất:
- Điều kiện nâng hoặc hạ cấu hình:
```

Chỉ ghi khuyến nghị model trong tài liệu kiểm soát dự án; không đưa tên model vào dữ liệu giả, metadata, checksum hoặc tiêu chí phân loại an toàn.

