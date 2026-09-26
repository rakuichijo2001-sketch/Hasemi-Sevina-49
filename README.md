# Hasemi Sevina 49

ASIC thử nghiệm xử lý dữ liệu cảm biến để **giám sát dấu hiệu mất ổn định taluy đường đèo tại Lâm Đồng**. Target hiện tại là Tiny Tapeout **SKY26d / SKY130**, mục tiêu allocation **3×2 tile**.

## Kiến trúc V1 đã chốt

- Digital ASIC; cảm biến, ADC/AFE, nguồn, MCU/data logger, truyền thông và cảnh báo hiện trường nằm ngoài chip.
- Không tích hợp MCU trong V1.
- SPI slave Mode 0 trên `uio[0:3]`, core clock 10 MHz.
- Dữ liệu logic: recent rainfall, antecedent rainfall, water/pore-pressure or moisture indicator, movement/tilt, movement rate, valid mask và sequence number.
- Data-quality checks: CRC-8, required-channel mask, optional range checks, sequence continuity và stale-data timeout.
- Classification: configurable low/high thresholds, hysteresis, persistence, weighted score và severe-motion override.
- Output states: NORMAL, CHECK/NEED_INSPECTION, HIGH_RISK, DATA_FAULT.

Đây là chip phân loại **trạng thái dữ liệu/điều kiện theo cấu hình**, không phải thiết bị khẳng định chắc chắn một vụ sạt lở sẽ xảy ra và không thay thế đánh giá địa kỹ thuật.

## Trạng thái kiểm chứng

RTL V1, testbench và tài liệu đang được triển khai trên branch `hasemi-v1-rtl`. Không xem dự án là sẵn sàng nộp fab cho tới khi có bằng chứng tương ứng từ RTL regression, SKY26d GDS build, precheck, gate-level test và review timing/area.

## Tài liệu

- [`docs/requirements-draft.md`](docs/requirements-draft.md): yêu cầu kiến trúc và các giả định cần xác minh.
- [`docs/info.md`](docs/info.md): datasheet-style description, SPI protocol và register map.

## Lưu ý quyền sở hữu

Repo hiện Public và template Tiny Tapeout dùng Apache-2.0. Cần rà phạm vi công bố trước khi đưa dữ liệu thực địa, calibration, thuật toán nâng cao hoặc RTL dự định bảo hộ lên GitHub.
