# Yêu cầu sơ bộ — Hasemi Sevina 49

## Bài toán

Giám sát **dấu hiệu** thay đổi tại một taluy đường đèo ở Lâm Đồng. Chip xử lý dữ liệu số; cảm biến, mạch số hoá, nguồn, truyền thông và cảnh báo hiện trường có thể nằm ngoài chip. Quyết định nhúng MCU sẽ dựa trên đo diện tích, công suất và nhu cầu vận hành, không mặc định rằng MCU đã có.

## Đầu vào dự kiến

- Số liệu mưa theo khoảng thời gian xác định.
- Chỉ số nước/độ ẩm đất hoặc áp lực nước lỗ rỗng nếu cảm biến thực tế hỗ trợ.
- Độ nghiêng hoặc dịch chuyển sau khi số hoá.
- Cờ hợp lệ dữ liệu và chu kỳ lấy mẫu do trạm hiện trường cung cấp.

## Đầu ra dự kiến

- Trạng thái: bình thường, cần kiểm tra, nguy cơ cao, lỗi dữ liệu.
- Mã lý do cảnh báo và cờ dữ liệu không hợp lệ.
- Giao tiếp số tới bộ điều khiển/trạm hiện trường để ghi log và truyền thông.

## Các quyết định còn mở

- Vị trí thử nghiệm, dữ liệu nền, chủng loại cảm biến, đơn vị đo và dải giá trị.
- Giao tiếp chip–trạm, pinout, tần số clock, reset, xử lý khi mất cảm biến/nguồn.
- Định nghĩa thuật toán, ngưỡng và thời gian quan sát; các mức trên chỉ là khung yêu cầu.
- MCU tích hợp hay ngoài chip; cấu hình 3×2 tile là mục tiêu đặt chỗ, chưa phải xác nhận fit vật lý.
- Quy trình hiệu chuẩn, kiểm nghiệm địa kỹ thuật và trách nhiệm ra quyết định cảnh báo hiện trường.

Tài liệu này là bản nháp yêu cầu, không phải đặc tả cuối cùng hoặc chứng minh chip phát hiện sạt lở.
