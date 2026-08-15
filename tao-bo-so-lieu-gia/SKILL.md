---
name: tao-bo-so-lieu-gia
description: Master skill tái sử dụng để điều phối quy trình ba cổng tạo bộ số liệu giả an toàn từ cấu trúc dữ liệu SPSS, Stata hoặc R mà không đưa bản ghi thật lên AI; quản lý tham số runtime, thư mục theo giai đoạn, trạng thái pending/reviewed/safe, archive, manifest và gói bàn giao. Dùng cho nhiều bộ số liệu và project root khác nhau khi cần trích xuất metadata local, sinh dữ liệu tổng hợp để phát triển/kiểm thử code, kiểm tra riêng tư hoặc chuẩn bị gói chia sẻ tái lập.
---

# Tạo bộ số liệu giả

Vận hành như một master skill độc lập với từng dự án. Thực hiện đúng ba cổng và bước bàn giao. Xem dữ liệu gốc là `LOCAL_ONLY`: không mở, đọc, tải lên, sao chép hoặc yêu cầu người dùng dán bản ghi thật vào môi trường AI.

## Ranh giới master skill và cấu hình dự án

Không ghi vào thư mục skill bất kỳ giá trị runtime nào: đường dẫn nguồn, tên file nguồn, project root, tên người dùng, ổ đĩa, metadata, seed, cỡ mẫu, mã missing, timestamp hoặc đầu ra của một dự án. Chỉ giữ hướng dẫn, placeholder, tài liệu tham chiếu và script nhận tham số.

Khi bắt đầu một dự án mới, đọc `references/runtime-parameters.md` và thu thập tối thiểu:

- `source_software` và `source_format`;
- `source_path` chỉ để dùng local;
- `project_root` do người dùng chọn;
- `synthetic_n` do người dùng xác nhận trước Cổng 3;
- `seed`, `special_missing_codes`, `small_cell_threshold`, `synthesis_mode` và `output_format` khi cần.

Hỏi trực tiếp: **“Bạn muốn tạo bộ số liệu giả có bao nhiêu dòng (bao nhiêu đối tượng)?”** Ghi câu trả lời là `synthetic_n` khi đó là số nguyên dương. Không suy đoán từ số dòng dữ liệu gốc, không tái sử dụng giá trị từ dự án/cuộc hội thoại trước và không tự đặt mặc định thay người dùng. Nếu chưa có câu trả lời, ghi `synthetic_n: pending`, nhắc lại trước Cổng 3 và không bắt đầu sinh dữ liệu giả. Nếu thiếu tham số khác ảnh hưởng đến code, hỏi ngắn gọn; không yêu cầu bản ghi mẫu. Ghi cấu hình từng dự án trong project root, tuyệt đối không ghi ngược vào thư mục master skill.

Mọi đường dẫn trong tài liệu và script master phải là đường dẫn tương đối hoặc placeholder như `<project-root>` và `<source-path>`. Script tiện ích phải nhận project root qua tham số bắt buộc, không tự suy đoán thư mục làm việc hiện hành.

## Quản lý thư mục dự án

Sau khi nhận `project_root` ở runtime, đọc `references/project-layout.md` và tạo cấu trúc chuẩn bên dưới đó trước khi sinh đầu ra. Nếu project root đã có nội dung, lập danh mục và ánh xạ di chuyển trước; không tự động ghi đè hoặc xóa.

Quản lý file theo luồng:

```text
pending -> reviewed/safe -> handoff
              |
              +-> archive khi bị thay thế
```

Quy tắc bắt buộc:

- Không đặt dữ liệu thật trong project root; `01_gate1_source/source_pointer.txt` chỉ là tệp runtime `LOCAL_ONLY`, không phải thành phần của master skill hoặc gói chia sẻ.
- Mỗi lần chạy tạo thư mục timestamp mới, không ghi đè.
- Chỉ chuyển metadata đạt `SAFE_METADATA / allow` vào `02_gate2_metadata/reviewed`.
- File giả vừa sinh phải ở `03_gate3_synthetic/data_pending`.
- Chỉ chuyển file đạt `SYNTHETIC_SAFE / allow` vào `03_gate3_synthetic/data_safe`.
- Chuyển lần chạy cũ hoặc file bị thay thế vào `90_archive`; archive không thuộc gói chia sẻ.
- Cập nhật `00_project_control/PROJECT_STATUS.md` sau mỗi cổng.
- Tìm và sửa đường dẫn hard-code trước khi di chuyển file.
- Trên Windows, xác minh đường dẫn tuyệt đối nằm trong project root rồi dùng PowerShell `-LiteralPath`; không xóa đệ quy bằng đường dẫn chưa kiểm tra.

## Gợi ý chuyển bước bắt buộc

Sau mỗi giai đoạn, kể cả khi `PASS`, `PENDING`, `FAIL` hoặc bị chặn, cập nhật `00_project_control/PROJECT_STATUS.md` và trả cho người dùng một khối **Gợi ý bước tiếp theo** gồm:

- trạng thái hiện tại và điều kiện còn thiếu;
- việc cần làm ngay, cách làm ngắn gọn và dấu hiệu hoàn tất;
- bước sẽ làm sau khi việc trước mắt hoàn tất để người dùng thấy trước lộ trình;
- model và reasoning effort đề xuất, kèm điều kiện cần nâng hoặc hạ mức.

Đọc `references/model-effort-routing.md` trước khi đề xuất. Kiểm tra model thực sự khả dụng tại runtime; không khẳng định một tên model là tối ưu vĩnh viễn. Ưu tiên cấu hình nhỏ nhất vẫn đạt yêu cầu an toàn và chất lượng, rồi tăng model/effort khi độ phức tạp, rủi ro riêng tư hoặc yêu cầu kiểm định tăng. Khuyến nghị chỉ là gợi ý vận hành, không tự ý đổi model hay phát sinh chi phí thay người dùng.

## 1. Xác định loại số liệu gốc

Hỏi trước một câu ngắn: **“Bộ số liệu gốc được lưu ở SPSS, Stata hay R?”**

Sau khi có câu trả lời, xác nhận định dạng dự kiến:

- SPSS: `.sav` và script `.sps`.
- Stata: `.dta` và script `.do`.
- R: `.rds`, `.RData` hoặc định dạng được đọc bằng R, với script `.R`.

Sau khi biết phần mềm/định dạng, hỏi đường dẫn local, mã missing đặc biệt khi có, và luôn hỏi: **“Bạn muốn tạo bộ số liệu giả có bao nhiêu dòng (bao nhiêu đối tượng)?”** Không thay câu trả lời bằng cỡ mẫu dữ liệu gốc hoặc một giá trị mặc định. Có thể để `synthetic_n: pending` khi chuyển sang trích xuất metadata, nhưng phải hỏi lại trước khi sinh. Không yêu cầu file thật, ảnh Data Editor, bản ghi mẫu, ID hoặc văn bản tự do.

Ghi cấu hình không nhạy cảm của lần chạy vào `01_gate1_source/project_config.yaml`; ghi đường dẫn nguồn vào `source_pointer.txt` với nhãn `LOCAL_ONLY`. Hai tệp này thuộc dự án đang chạy, không thuộc master skill. Không tính checksum và không sao chép file nguồn.

**Cổng 1:** chỉ chuyển tiếp khi đã biết phần mềm/định dạng, đã hỏi cỡ mẫu giả và người dùng hiểu rằng file thật phải ở lại local. Có thể tiếp tục Cổng 2 khi `synthetic_n` còn `pending`, nhưng Cổng 3 bị chặn cho đến khi người dùng xác nhận số nguyên dương.

Phát hành khối **Gợi ý bước tiếp theo** cho việc tạo/chạy script metadata và xem trước bước duyệt an toàn metadata.

## 2. Viết code lấy biến và mô hình dữ liệu

Áp dụng `$trich-xuat-cau-truc-du-lieu-local` để tạo script chỉ đọc trong `02_gate2_metadata/scripts`. Script phải:

1. Không ghi đè dữ liệu nguồn và không xuất bất kỳ dòng dữ liệu nào.
2. Lấy tên biến, nhãn không nhạy cảm, kiểu, format, số quan sát, số/tỷ lệ missing và phạm vi đã làm thô.
3. Với biến phân loại, chỉ xuất mã và tần số đã gộp; mặc định che nhóm có `n < 10`.
4. Chỉ đánh dấu sự tồn tại của ID, ngày chi tiết, địa chỉ, tọa độ và văn bản tự do; không xuất giá trị.
5. Mô tả phân phối biên, quan hệ phụ thuộc, biến dẫn xuất, nhánh bảng hỏi, quan hệ thời gian/cụm và quy tắc missing.
6. Nếu cần ước lượng từ dữ liệu thật, thực hiện khớp mô hình và sinh dữ liệu trong cùng quy trình local; không xuất tham số hiếm có thể suy ngược cá thể.
7. Ghi mỗi lần chạy vào `02_gate2_metadata/runs_pending/<timestamp>` với metadata, đặc tả và log tự kiểm tra.

Với script SPSS, ưu tiên bỏ tùy chọn `WINDOW` khỏi `DATASET NAME`; nếu cần chỉ định thì dùng `WINDOW=ASIS`. Không dùng `WINDOW=HIDDEN`: SPSS 27 dừng lệnh vì chỉ chấp nhận `FRONT` hoặc `ASIS`. Trước khi bàn giao `.sps`, tìm chuỗi `WINDOW=HIDDEN`; nếu còn thì coi kiểm tra tương thích là `FAIL` và sửa trước khi người dùng chạy.

Dùng chế độ an toàn nhất đủ cho mục tiêu:

- `schema_only`: mặc định; mô phỏng từ kiểu, miền và quy tắc.
- `approved_aggregates`: chỉ dùng số tổng hợp đã được phê duyệt.
- `local_fit`: chỉ khi thật sự cần giữ quan hệ phức tạp; học mô hình và sinh dữ liệu đều chạy local.

Áp dụng `$kiem-tra-an-toan-du-lieu`. Khi đạt, chuyển nguyên thư mục chạy vào `02_gate2_metadata/reviewed`; nếu đã có bản hiện hành, chuyển bản cũ vào `90_archive/metadata_runs` trước.

**Cổng 2:** không chuyển metadata sang AI nếu có ID, dòng dữ liệu, chuỗi tự do, ngày/địa chỉ chi tiết, danh sách giá trị duy nhất hoặc tổ hợp hiếm chưa gộp.

Phát hành khối **Gợi ý bước tiếp theo** cho việc đặc tả/sinh dữ liệu giả và xem trước các kiểm tra Cổng 3.

## 3. Tạo và kiểm tra bộ số liệu giả

Chỉ bắt đầu khi `synthetic_n` là số nguyên dương do người dùng xác nhận trong `project_config.yaml`. Nếu còn `pending`, hỏi lại: **“Bạn muốn tạo bộ số liệu giả có bao nhiêu dòng (bao nhiêu đối tượng)?”** rồi dừng trước Cổng 3. Áp dụng `$mo-phong-du-lieu-nghien-cuu`. Lưu đặc tả trong `03_gate3_synthetic/specification`, script trong `scripts`, hướng dẫn trong `guides`. Code phải:

1. Dùng seed cố định và tạo ID hoàn toàn giả.
2. Khớp schema, mã hóa, miền, missing, ràng buộc logic và quan hệ cần thiết để chạy thử phân tích.
3. Không sao chép bản ghi thật; không tự động chọn `local_fit` chỉ để dữ liệu “giống thật”.
4. Tạo tình huống biên như missing, nhóm thưa và giá trị giới hạn khi phù hợp.
5. Gắn nhãn `SYNTHETIC—NOT FOR SCIENTIFIC INFERENCE` trong file, log và báo cáo.
6. Ghi file mới sinh vào `03_gate3_synthetic/data_pending`; ghi validation vào `03_gate3_synthetic/validation`.

Nếu dùng `local_fit`, yêu cầu chạy local kiểm tra exact/near duplicate, tổ hợp bán định danh duy nhất, nhóm hiếm, cực trị và khoảng cách láng giềng so với dữ liệu thật.

Áp dụng `$kiem-tra-an-toan-du-lieu`. Khi tất cả kiểm tra đạt `SYNTHETIC_SAFE / allow`, chuyển file từ `data_pending` sang `data_safe`. File fail hoặc bị thay thế chuyển vào `90_archive/synthetic_runs`.

**Cổng 3:** nếu chưa kiểm tra xong, giữ `SYNTHETIC_PENDING` trong `data_pending` và không khuyên tải file lên AI.

Phát hành khối **Gợi ý bước tiếp theo** cho việc sửa/kiểm định lại hoặc đóng gói bàn giao, đồng thời xem trước audit cuối.

## 4. Đóng gói bàn giao

Chỉ bắt đầu sau Cổng 3. Tạo:

- `00_project_control/RUN_ORDER.md`;
- `00_project_control/MANIFEST_LOCAL_ONLY.tsv`;
- `00_project_control/MANIFEST_SHAREABLE.tsv`;
- `04_handoff/audit/FINAL_AUDIT_REPORT.md`;
- `04_handoff/checksums/` khi cần tệp checksum riêng;
- `04_handoff/package/` chỉ chứa bản đóng băng lấy từ manifest SHAREABLE.

Không đưa `runs_pending`, `data_pending`, `90_archive`, dữ liệu thật hoặc khóa liên kết vào gói chia sẻ.

Dùng các script đi kèm khi cấu trúc đã đầy đủ:

```powershell
& '<skill-dir>\scripts\build-shareable-manifest.ps1' -ProjectRoot '<project-root>'
& '<skill-dir>\scripts\verify-package.ps1' -ProjectRoot '<project-root>'
```

Chỉ kết luận hoàn tất khi checksum khớp, không còn đường dẫn legacy, validation là `PASS`, phân loại là `SYNTHETIC_SAFE / ALLOW`, và không có file dữ liệu thật trong project root.

Sau bàn giao, phát hành khối **Gợi ý bước tiếp theo** cho cách chạy lại tái lập, lưu trữ/phiên bản hóa an toàn và bước phân tích kế tiếp phù hợp; luôn nhắc dữ liệu giả không dùng để suy luận khoa học.

## Kiểm tra khả năng tái sử dụng của master skill

Sau khi sửa skill, kiểm tra toàn bộ thư mục skill trước khi chia sẻ:

- không có đường dẫn tuyệt đối, tên file nguồn, project root hoặc thông tin người dùng cụ thể;
- không có metadata, dữ liệu hoặc đầu ra của một dự án;
- ví dụ chỉ dùng placeholder;
- script tiện ích yêu cầu tham số đầu vào và không phụ thuộc thư mục làm việc hiện hành;
- script SPSS không chứa `WINDOW=HIDDEN`; dùng `WINDOW=ASIS` hoặc bỏ tùy chọn `WINDOW`;
- `agents/openai.yaml` mô tả cách dùng chung;
- hướng dẫn từng cổng đều dẫn đến khối gợi ý việc làm ngay, bước sau đó, model và effort theo `references/model-effort-routing.md`;
- skill vượt qua `quick_validate.py` và các script đi kèm được kiểm thử bằng fixture tạm không chứa dữ liệu thật.

## Đầu ra bắt buộc

Trả về:

- cấu trúc thư mục và trạng thái từng cổng;
- câu trả lời `synthetic_n` đã xác nhận trước khi sinh dữ liệu giả;
- script local trích xuất cấu trúc/mô hình;
- hướng dẫn chạy và rà soát metadata;
- đặc tả và script sinh dữ liệu giả;
- file giả trong `data_safe` nếu đã đạt cổng;
- báo cáo validation và phân loại an toàn;
- RUN_ORDER, hai manifest, checksum và audit khi bàn giao;
- khối **Gợi ý bước tiếp theo** sau mỗi giai đoạn, gồm cả bước ngay sau đó, bước kế tiếp nữa, model và reasoning effort đề xuất;
- cảnh báo dữ liệu giả chỉ phục vụ phát triển/kiểm thử code, không dùng để suy luận khoa học hoặc báo cáo kết quả nghiên cứu.

Nếu người dùng chưa chạy được script local, dừng ở code và hướng dẫn; không bịa metadata, tham số hoặc kết quả từ dữ liệu gốc.
