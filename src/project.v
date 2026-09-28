/*
 * Hasemi-Sevina-49
 * Configurable multi-sensor edge risk and safety processor
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_rakuichijo2001_hasemi_sevina_49 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire spi_sclk  = ui_in[0];
    wire spi_mosi  = ui_in[1];
    wire spi_cs_n  = ui_in[2];
    wire tick_1hz_async = ui_in[3];
    wire ext_fault_async = ui_in[4];

    reg tick_meta;
    reg tick_sync;
    reg tick_prev;
    reg fault_meta;
    reg fault_sync;

    always @(posedge clk) begin
        if (!rst_n) begin
            tick_meta  <= 1'b0;
            tick_sync  <= 1'b0;
            tick_prev  <= 1'b0;
            fault_meta <= 1'b0;
            fault_sync <= 1'b0;
        end else begin
            tick_meta  <= tick_1hz_async;
            tick_sync  <= tick_meta;
            tick_prev  <= tick_sync;
            fault_meta <= ext_fault_async;
            fault_sync <= fault_meta;
        end
    end

    wire tick_1hz = tick_sync & ~tick_prev;

    wire [6:0] spi_rd_addr;
    wire [7:0] spi_rd_data;
    wire       spi_wr_en;
    wire [6:0] spi_wr_addr;
    wire [7:0] spi_wr_data;
    wire       spi_miso;
    wire       spi_transaction_active;

    hs49_spi_slave u_spi (
        .clk(clk), .rst_n(rst_n),
        .spi_sclk(spi_sclk), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .rd_data(spi_rd_data), .rd_addr(spi_rd_addr),
        .wr_en(spi_wr_en), .wr_addr(spi_wr_addr), .wr_data(spi_wr_data),
        .spi_miso(spi_miso),
        .transaction_active(spi_transaction_active)
    );

    // TinyQV external transaction bus. Addresses with addr[27:25] == 0 are
    // handled by its QSPI memory controller; all others reach this bridge.
    wire [27:0] cpu_data_addr;
    wire  [1:0] cpu_data_write_n;
    wire  [1:0] cpu_data_read_n;
    wire        cpu_data_read_complete;
    wire [31:0] cpu_data_to_write;
    wire        cpu_data_ready;
    wire [31:0] cpu_data_from_read;

    wire [3:0] qspi_data_in = {uio_in[5:4], uio_in[2:1]};
    wire [3:0] qspi_data_out;
    wire [3:0] qspi_data_oe;
    wire       qspi_clk_out;
    wire       qspi_flash_select;
    wire       qspi_ram_a_select;
    wire       qspi_ram_b_select;

    wire       debug_instr_complete;
    wire       debug_instr_ready;
    wire       debug_instr_valid;
    wire       debug_fetch_restart;
    wire       debug_data_ready;
    wire       debug_interrupt_pending;
    wire       debug_branch;
    wire       debug_early_branch;
    wire       debug_ret;
    wire       debug_reg_wen;
    wire       debug_counter_0;
    wire       debug_data_continue;
    wire       debug_stall_txn;
    wire       debug_stop_txn;
    wire [3:0] debug_rd;

    tinyQV u_cpu (
        .clk(clk),
        .rstn(rst_n),
        .data_addr(cpu_data_addr),
        .data_write_n(cpu_data_write_n),
        .data_read_n(cpu_data_read_n),
        .data_read_complete(cpu_data_read_complete),
        .data_out(cpu_data_to_write),
        .data_ready(cpu_data_ready),
        .data_in(cpu_data_from_read),
        .interrupt_req(4'b0000),
        .spi_data_in(qspi_data_in),
        .spi_data_out(qspi_data_out),
        .spi_data_oe(qspi_data_oe),
        .spi_clk_out(qspi_clk_out),
        .spi_flash_select(qspi_flash_select),
        .spi_ram_a_select(qspi_ram_a_select),
        .spi_ram_b_select(qspi_ram_b_select),
        .debug_instr_complete(debug_instr_complete),
        .debug_instr_ready(debug_instr_ready),
        .debug_instr_valid(debug_instr_valid),
        .debug_fetch_restart(debug_fetch_restart),
        .debug_data_ready(debug_data_ready),
        .debug_interrupt_pending(debug_interrupt_pending),
        .debug_branch(debug_branch),
        .debug_early_branch(debug_early_branch),
        .debug_ret(debug_ret),
        .debug_reg_wen(debug_reg_wen),
        .debug_counter_0(debug_counter_0),
        .debug_data_continue(debug_data_continue),
        .debug_stall_txn(debug_stall_txn),
        .debug_stop_txn(debug_stop_txn),
        .debug_rd(debug_rd)
    );

    wire       reg_wr_en;
    wire [6:0] reg_wr_addr;
    wire [7:0] reg_wr_data;
    wire [6:0] reg_rd_addr;
    wire [7:0] reg_rd_data;

    hs49_mmio_bridge u_mmio_bridge (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_data_addr),
        .cpu_write_n(cpu_data_write_n),
        .cpu_read_n(cpu_data_read_n),
        .cpu_write_data(cpu_data_to_write),
        .cpu_ready(cpu_data_ready),
        .cpu_read_data(cpu_data_from_read),
        .spi_active(spi_transaction_active),
        .spi_wr_en(spi_wr_en),
        .spi_wr_addr(spi_wr_addr),
        .spi_wr_data(spi_wr_data),
        .spi_rd_addr(spi_rd_addr),
        .spi_rd_data(spi_rd_data),
        .reg_wr_en(reg_wr_en),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data)
    );

    wire enable;
    wire clear_irq_pulse;
    wire clear_events_pulse;
    wire sample_commit_pulse;

    wire [15:0] rain_value;
    wire [15:0] water_value;
    wire [15:0] tilt_value;
    wire [15:0] displacement_value;
    wire [3:0]  valid_mask;

    wire [15:0] rain_watch_th;
    wire [15:0] water_watch_th;
    wire [15:0] tilt_watch_th;
    wire [15:0] displacement_watch_th;
    wire [15:0] rain_critical_th;
    wire [15:0] water_critical_th;
    wire [15:0] tilt_critical_th;
    wire [15:0] displacement_critical_th;

    wire [3:0] weight_rain;
    wire [3:0] weight_water;
    wire [3:0] weight_tilt;
    wire [3:0] weight_displacement;
    wire [7:0] score_watch_th;
    wire [7:0] score_warning_th;
    wire [7:0] score_critical_th;
    wire [7:0] persist_up;
    wire [7:0] persist_down;
    wire [3:0] required_mask;
    wire [7:0] timeout_s;

    wire [7:0] risk_score;
    wire [1:0] candidate_level;
    wire [1:0] risk_level;
    wire [3:0] reason_code;
    wire [7:0] severity_packed;
    wire config_fault;

    wire [7:0] sample_age_s;
    wire data_fault;
    wire sensor_fault = data_fault | config_fault;

    wire state_change_pulse;
    wire [7:0] event_count;
    wire [1:0] last_event_level;
    wire [3:0] last_event_reason;
    wire [7:0] last_event_score;
    wire irq_latched;

    hs49_register_bank u_regs (
        .clk(clk), .rst_n(rst_n),
        .wr_en(reg_wr_en), .wr_addr(reg_wr_addr), .wr_data(reg_wr_data),
        .rd_addr(reg_rd_addr), .rd_data(reg_rd_data),
        .risk_score(risk_score), .risk_level(risk_level),
        .reason_code(reason_code), .severity_packed(severity_packed),
        .sensor_fault(sensor_fault), .sample_age_s(sample_age_s),
        .event_count(event_count), .last_event_level(last_event_level),
        .last_event_reason(last_event_reason), .last_event_score(last_event_score),
        .irq_latched(irq_latched),
        .enable(enable), .clear_irq_pulse(clear_irq_pulse),
        .clear_events_pulse(clear_events_pulse),
        .sample_commit_pulse(sample_commit_pulse),
        .rain_value(rain_value), .water_value(water_value),
        .tilt_value(tilt_value), .displacement_value(displacement_value),
        .valid_mask(valid_mask),
        .rain_watch_th(rain_watch_th), .water_watch_th(water_watch_th),
        .tilt_watch_th(tilt_watch_th), .displacement_watch_th(displacement_watch_th),
        .rain_critical_th(rain_critical_th), .water_critical_th(water_critical_th),
        .tilt_critical_th(tilt_critical_th),
        .displacement_critical_th(displacement_critical_th),
        .weight_rain(weight_rain), .weight_water(weight_water),
        .weight_tilt(weight_tilt), .weight_displacement(weight_displacement),
        .score_watch_th(score_watch_th), .score_warning_th(score_warning_th),
        .score_critical_th(score_critical_th),
        .persist_up(persist_up), .persist_down(persist_down),
        .required_mask(required_mask), .timeout_s(timeout_s)
    );

    hs49_sensor_validator u_validator (
        .clk(clk), .rst_n(rst_n), .tick_1hz(tick_1hz),
        .sample_commit(sample_commit_pulse),
        .valid_mask(valid_mask), .required_mask(required_mask),
        .timeout_s(timeout_s), .ext_fault(fault_sync),
        .sample_age_s(sample_age_s), .data_fault(data_fault)
    );

    hs49_risk_engine u_risk_engine (
        .rain_value(rain_value), .water_value(water_value),
        .tilt_value(tilt_value), .displacement_value(displacement_value),
        .rain_watch_th(rain_watch_th), .water_watch_th(water_watch_th),
        .tilt_watch_th(tilt_watch_th), .displacement_watch_th(displacement_watch_th),
        .rain_critical_th(rain_critical_th), .water_critical_th(water_critical_th),
        .tilt_critical_th(tilt_critical_th),
        .displacement_critical_th(displacement_critical_th),
        .weight_rain(weight_rain), .weight_water(weight_water),
        .weight_tilt(weight_tilt), .weight_displacement(weight_displacement),
        .score_watch_th(score_watch_th), .score_warning_th(score_warning_th),
        .score_critical_th(score_critical_th),
        .risk_score(risk_score), .candidate_level(candidate_level),
        .reason_code(reason_code), .severity_packed(severity_packed),
        .config_fault(config_fault)
    );

    hs49_risk_fsm u_risk_fsm (
        .clk(clk), .rst_n(rst_n),
        .sample_commit(sample_commit_pulse), .enable(enable),
        .fault_active(sensor_fault), .candidate_level(candidate_level),
        .persist_up(persist_up), .persist_down(persist_down),
        .risk_level(risk_level), .state_change_pulse(state_change_pulse)
    );

    hs49_event_logger u_event_logger (
        .clk(clk), .rst_n(rst_n), .risk_level(risk_level),
        .reason_code(reason_code), .risk_score(risk_score),
        .sensor_fault(sensor_fault), .state_change_pulse(state_change_pulse),
        .clear_irq(clear_irq_pulse), .clear_events(clear_events_pulse),
        .event_count(event_count), .last_event_level(last_event_level),
        .last_event_reason(last_event_reason), .last_event_score(last_event_score),
        .irq_latched(irq_latched)
    );

    reg [23:0] heartbeat_counter;
    always @(posedge clk) begin
        if (!rst_n)
            heartbeat_counter <= 24'h000000;
        else
            heartbeat_counter <= heartbeat_counter + 1'b1;
    end

    wire watch_active    = (risk_level == 2'd1);
    wire warning_active  = (risk_level == 2'd2);
    wire critical_active = (risk_level == 2'd3);
    wire alert_active    = warning_active | critical_active | sensor_fault;

    assign uo_out[0] = spi_miso;
    assign uo_out[1] = alert_active;
    assign uo_out[2] = critical_active;
    assign uo_out[3] = sensor_fault;
    assign uo_out[4] = watch_active;
    assign uo_out[5] = warning_active;
    assign uo_out[6] = heartbeat_counter[23];
    assign uo_out[7] = irq_latched;

    // QSPI mapping verified from the TT06 TinyQV top wrapper. While reset is
    // active all pads are inputs, but output values remain deterministic and
    // chip selects are represented inactive-high.
    assign uio_out = rst_n ?
        {qspi_ram_b_select, qspi_ram_a_select, qspi_data_out[3:2],
         qspi_clk_out, qspi_data_out[1:0], qspi_flash_select} : 8'hC1;
    assign uio_oe = rst_n ?
        {2'b11, qspi_data_oe[3:2], 1'b1, qspi_data_oe[1:0], 1'b1} : 8'h00;

    wire _unused = &{ena, ui_in[7:5], cpu_data_read_complete,
                     debug_instr_complete, debug_instr_ready,
                     debug_instr_valid, debug_fetch_restart,
                     debug_data_ready, debug_interrupt_pending,
                     debug_branch, debug_early_branch, debug_ret,
                     debug_reg_wen, debug_counter_0, debug_data_continue,
                     debug_stall_txn, debug_stop_txn, debug_rd, 1'b0};

endmodule
