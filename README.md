# Hasemi Sevina 49

ASIC thử nghiệm xử lý dữ liệu cảm biến để **giám sát dấu hiệu mất ổn định taluy đường đèo tại Lâm Đồng**. Dự kiến dùng Tiny Tapeout SKY26d trên SKY130, đặt chỗ mục tiêu **3×2 tile**.

## Trạng thái dự án

Repo được tạo từ [mẫu Verilog SKY130 của Tiny Tapeout](https://github.com/TinyTapeout/ttsky-verilog-template). Các tệp `src/project.v`, `info.yaml` và `test/` hiện vẫn là **ví dụ của mẫu**, chưa phải thiết kế Hasemi Sevina 49. Chưa có RTL hoàn chỉnh, dữ liệu đo thực địa, GDS đã kiểm tra hay chip được chế tạo. **Không nộp dự án khi các tệp này chưa được thay thế và kiểm thử.**

## Định hướng chức năng

- Nhận dữ liệu đã số hoá từ trạm cảm biến ngoài chip, dự kiến gồm mưa, điều kiện nước trong đất và độ nghiêng/dịch chuyển.
- Phát hiện dữ liệu lỗi/mất; tính chỉ số và trạng thái theo ngưỡng có thể hiệu chỉnh sau khảo sát thực địa.
- Xuất trạng thái để trạm điều khiển ghi nhật ký, truyền tin hoặc kích hoạt cảnh báo theo quy trình vận hành riêng.
- Thiết kế không tự nhận là có thể dự báo mọi vụ sạt lở hay thay thế đánh giá địa kỹ thuật.

## Việc tiếp theo

1. Chốt yêu cầu và sơ đồ giao tiếp trong [bản nháp yêu cầu](docs/requirements-draft.md).
2. Thiết kế RTL và testbench; cập nhật `info.yaml`, `docs/info.md`, pinout và `test/Makefile` nhất quán.
3. Chạy mô phỏng, CI GDS, precheck và kiểm tra timing/diện tích 3×2 tile cho SKY26d.
4. Đối chiếu ngưỡng trên dữ liệu từ vị trí triển khai trước khi đánh giá hiệu quả cảnh báo.

**Lưu ý quyền sở hữu:** Repo đang để Public và mẫu Tiny Tapeout kèm giấy phép Apache-2.0. Rà lại phạm vi công bố và quyền sở hữu trước khi đẩy thuật toán hoặc RTL dự định bảo hộ.
