# Yêu cầu kiến trúc V1 — Hasemi Sevina 49

## Đã quyết định

- Mục tiêu: ASIC số xử lý dữ liệu cảm biến để giám sát dấu hiệu mất ổn định taluy đường đèo tại Lâm Đồng.
- Không phát triển từ CTW-SPMS hoặc Sao Mai.
- Target Tiny Tapeout SKY26d / SKY130, mục tiêu đặt chỗ 3x2 tile.
- Cảm biến, analog front end/ADC, nguồn, truyền thông dài khoảng cách và thiết bị cảnh báo nằm ngoài chip V1.
- V1 không tích hợp MCU.
- Giao tiếp chip-trạm: SPI slave Mode 0, MSB first, trên `uio[0:3]`.
- Clock chức năng: 10 MHz từ chân `clk`; reset active-low từ `rst_n`.
- Thuật toán V1: threshold có cấu hình + hysteresis + persistence + weighted score + severe-motion override + data-quality engine.
- Trạng thái đầu ra: NORMAL, CHECK/NEED_INSPECTION, HIGH_RISK, DATA_FAULT.
- Không mô tả chip là thiết bị dự báo chắc chắn sạt lở hoặc thay thế đánh giá địa kỹ thuật.

## Đề xuất triển khai V1

Dữ liệu đầu vào sau khi số hóa và quy đổi tại trạm gồm năm feature logic:

1. Mưa gần thời điểm hiện tại.
2. Mưa tiền kỳ.
3. Chỉ số nước trong đất / áp lực nước lỗ rỗng / chỉ số tương đương tùy sensor thực tế.
4. Độ nghiêng hoặc dịch chuyển.
5. Tốc độ thay đổi của chuyển vị/nghiêng.

Một sample còn có sequence number và valid mask. Mỗi giao dịch SPI write được bảo vệ CRC-8. Sensor data được ghi vào staging registers và chỉ được xử lý khi nhận `SAMPLE_COMMIT=0xA55A` hợp lệ.

Configuration registers chứa low/high threshold của từng feature, trọng số, score threshold, hysteresis, persistence, stale timeout, required mask và optional max-range checks. Bất kỳ thay đổi configuration nào cũng làm `CONFIG_VALID=0` cho tới khi `CONFIG_COMMIT=0xC0DE` vượt qua kiểm tra cấu trúc.

Reset khởi động ở DATA_FAULT với RESULT_VALID=0. Chip chỉ rời trạng thái này sau khi có cấu hình hợp lệ và sample hợp lệ.

## Chưa xác minh bằng dữ liệu thực địa

- Vị trí taluy cụ thể và mô hình địa chất/địa kỹ thuật.
- Loại sensor chính xác, dải đo, độ phân giải, đơn vị và scaling digital.
- Chu kỳ lấy mẫu và stale timeout vận hành.
- Required sensor mask cho điểm triển khai.
- Low/high threshold, hysteresis, persistence, feature weights và score thresholds.
- Quan hệ giữa trạng thái ASIC và quy trình cảnh báo ngoài hiện trường.
- Tỷ lệ false positive/false negative và hiệu quả cảnh báo trên dữ liệu Lâm Đồng.
- Fit vật lý 3x2, timing, power và khả năng nộp fab; các mục này chỉ được xác nhận sau GDS/precheck/GL test và review kết quả flow SKY26d.
- Chi phí fab 50 triệu VND là dự toán nội bộ, chưa phải quotation Tiny Tapeout đã xác nhận.

## Quyền sở hữu / công bố

Repo hiện Public. Trước khi đưa threshold calibration, dữ liệu hiện trường, thuật toán nâng cao hoặc RTL có ý định bảo hộ lên repo, cần xác định rõ phần nào được công bố và phần nào cần giữ riêng.
