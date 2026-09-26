`default_nettype none

module hs49_register_bank (
    input wire clk, rst_n,
    input wire wr_en,
    input wire [6:0] wr_addr,
    input wire [7:0] wr_data,
    input wire [6:0] rd_addr,
    output reg [7:0] rd_data,

    input wire [7:0] risk_score,
    input wire [1:0] risk_level,
    input wire [3:0] reason_code,
    input wire [7:0] severity_packed,
    input wire sensor_fault,
    input wire [7:0] sample_age_s,
    input wire [7:0] event_count,
    input wire [1:0] last_event_level,
    input wire [3:0] last_event_reason,
    input wire [7:0] last_event_score,
    input wire irq_latched,

    output reg enable,
    output reg clear_irq_pulse,
    output reg clear_events_pulse,
    output reg sample_commit_pulse,

    output reg [15:0] rain_value,
    output reg [15:0] water_value,
    output reg [15:0] tilt_value,
    output reg [15:0] displacement_value,
    output reg [3:0] valid_mask,

    output reg [15:0] rain_watch_th,
    output reg [15:0] water_watch_th,
    output reg [15:0] tilt_watch_th,
    output reg [15:0] displacement_watch_th,

    output reg [15:0] rain_critical_th,
    output reg [15:0] water_critical_th,
    output reg [15:0] tilt_critical_th,
    output reg [15:0] displacement_critical_th,

    output reg [3:0] weight_rain,
    output reg [3:0] weight_water,
    output reg [3:0] weight_tilt,
    output reg [3:0] weight_displacement,

    output reg [7:0] score_watch_th,
    output reg [7:0] score_warning_th,
    output reg [7:0] score_critical_th,
    output reg [7:0] persist_up,
    output reg [7:0] persist_down,
    output reg [3:0] required_mask,
    output reg [7:0] timeout_s
);

    localparam [6:0] REG_CHIP_ID           = 7'h00;
    localparam [6:0] REG_VERSION           = 7'h01;
    localparam [6:0] REG_CONTROL           = 7'h02;
    localparam [6:0] REG_STATUS            = 7'h03;
    localparam [6:0] REG_RAIN_L            = 7'h04;
    localparam [6:0] REG_RAIN_H            = 7'h05;
    localparam [6:0] REG_WATER_L           = 7'h06;
    localparam [6:0] REG_WATER_H           = 7'h07;
    localparam [6:0] REG_TILT_L            = 7'h08;
    localparam [6:0] REG_TILT_H            = 7'h09;
    localparam [6:0] REG_DISP_L            = 7'h0A;
    localparam [6:0] REG_DISP_H            = 7'h0B;
    localparam [6:0] REG_VALID_MASK        = 7'h0C;
    localparam [6:0] REG_COMMIT            = 7'h0D;
    localparam [6:0] REG_SAMPLE_AGE        = 7'h0E;
    localparam [6:0] REG_REASON            = 7'h0F;

    localparam [6:0] REG_RAIN_WATCH_L      = 7'h10;
    localparam [6:0] REG_RAIN_WATCH_H      = 7'h11;
    localparam [6:0] REG_WATER_WATCH_L     = 7'h12;
    localparam [6:0] REG_WATER_WATCH_H     = 7'h13;
    localparam [6:0] REG_TILT_WATCH_L      = 7'h14;
    localparam [6:0] REG_TILT_WATCH_H      = 7'h15;
    localparam [6:0] REG_DISP_WATCH_L      = 7'h16;
    localparam [6:0] REG_DISP_WATCH_H      = 7'h17;

    localparam [6:0] REG_RAIN_CRIT_L       = 7'h18;
    localparam [6:0] REG_RAIN_CRIT_H       = 7'h19;
    localparam [6:0] REG_WATER_CRIT_L      = 7'h1A;
    localparam [6:0] REG_WATER_CRIT_H      = 7'h1B;
    localparam [6:0] REG_TILT_CRIT_L       = 7'h1C;
    localparam [6:0] REG_TILT_CRIT_H       = 7'h1D;
    localparam [6:0] REG_DISP_CRIT_L       = 7'h1E;
    localparam [6:0] REG_DISP_CRIT_H       = 7'h1F;

    localparam [6:0] REG_WEIGHT_RAIN       = 7'h20;
    localparam [6:0] REG_WEIGHT_WATER      = 7'h21;
    localparam [6:0] REG_WEIGHT_TILT       = 7'h22;
    localparam [6:0] REG_WEIGHT_DISP       = 7'h23;
    localparam [6:0] REG_SCORE_WATCH       = 7'h24;
    localparam [6:0] REG_SCORE_WARNING     = 7'h25;
    localparam [6:0] REG_SCORE_CRITICAL    = 7'h26;
    localparam [6:0] REG_PERSIST_UP        = 7'h27;
    localparam [6:0] REG_PERSIST_DOWN      = 7'h28;
    localparam [6:0] REG_REQUIRED_MASK     = 7'h29;
    localparam [6:0] REG_TIMEOUT_S         = 7'h2A;

    localparam [6:0] REG_RISK_SCORE        = 7'h30;
    localparam [6:0] REG_RISK_LEVEL        = 7'h31;
    localparam [6:0] REG_LAST_EVENT_LEVEL  = 7'h32;
    localparam [6:0] REG_LAST_EVENT_REASON = 7'h33;
    localparam [6:0] REG_LAST_EVENT_SCORE  = 7'h34;
    localparam [6:0] REG_EVENT_COUNT       = 7'h35;
    localparam [6:0] REG_SEVERITY          = 7'h36;
    localparam [6:0] REG_SAMPLE_SEQ        = 7'h37;

    reg [7:0] sample_seq;

    always @(posedge clk) begin
        if (!rst_n) begin
            enable <= 1'b1;
            clear_irq_pulse <= 1'b0;
            clear_events_pulse <= 1'b0;
            sample_commit_pulse <= 1'b0;
            sample_seq <= 8'h00;

            rain_value <= 16'h0000;
            water_value <= 16'h0000;
            tilt_value <= 16'h0000;
            displacement_value <= 16'h0000;
            valid_mask <= 4'h0;

            rain_watch_th <= 16'hFFFF;
            water_watch_th <= 16'hFFFF;
            tilt_watch_th <= 16'hFFFF;
            displacement_watch_th <= 16'hFFFF;

            rain_critical_th <= 16'hFFFF;
            water_critical_th <= 16'hFFFF;
            tilt_critical_th <= 16'hFFFF;
            displacement_critical_th <= 16'hFFFF;

            weight_rain <= 4'd1;
            weight_water <= 4'd1;
            weight_tilt <= 4'd1;
            weight_displacement <= 4'd1;

            score_watch_th <= 8'd1;
            score_warning_th <= 8'd3;
            score_critical_th <= 8'd6;
            persist_up <= 8'd2;
            persist_down <= 8'd2;
            required_mask <= 4'hF;
            timeout_s <= 8'd0;
        end else begin
            clear_irq_pulse <= 1'b0;
            clear_events_pulse <= 1'b0;
            sample_commit_pulse <= 1'b0;

            if (wr_en) begin
                case (wr_addr)
                    REG_CONTROL: begin
                        enable <= wr_data[0];
                        clear_irq_pulse <= wr_data[1];
                        clear_events_pulse <= wr_data[2];
                    end

                    REG_RAIN_L:  rain_value[7:0] <= wr_data;
                    REG_RAIN_H:  rain_value[15:8] <= wr_data;
                    REG_WATER_L: water_value[7:0] <= wr_data;
                    REG_WATER_H: water_value[15:8] <= wr_data;
                    REG_TILT_L:  tilt_value[7:0] <= wr_data;
                    REG_TILT_H:  tilt_value[15:8] <= wr_data;
                    REG_DISP_L:  displacement_value[7:0] <= wr_data;
                    REG_DISP_H:  displacement_value[15:8] <= wr_data;
                    REG_VALID_MASK: valid_mask <= wr_data[3:0];

                    REG_COMMIT: begin
                        if (wr_data == 8'hA5) begin
                            sample_commit_pulse <= 1'b1;
                            sample_seq <= sample_seq + 1'b1;
                        end
                    end

                    REG_RAIN_WATCH_L:  rain_watch_th[7:0] <= wr_data;
                    REG_RAIN_WATCH_H:  rain_watch_th[15:8] <= wr_data;
                    REG_WATER_WATCH_L: water_watch_th[7:0] <= wr_data;
                    REG_WATER_WATCH_H: water_watch_th[15:8] <= wr_data;
                    REG_TILT_WATCH_L:  tilt_watch_th[7:0] <= wr_data;
                    REG_TILT_WATCH_H:  tilt_watch_th[15:8] <= wr_data;
                    REG_DISP_WATCH_L:  displacement_watch_th[7:0] <= wr_data;
                    REG_DISP_WATCH_H:  displacement_watch_th[15:8] <= wr_data;

                    REG_RAIN_CRIT_L:  rain_critical_th[7:0] <= wr_data;
                    REG_RAIN_CRIT_H:  rain_critical_th[15:8] <= wr_data;
                    REG_WATER_CRIT_L: water_critical_th[7:0] <= wr_data;
                    REG_WATER_CRIT_H: water_critical_th[15:8] <= wr_data;
                    REG_TILT_CRIT_L:  tilt_critical_th[7:0] <= wr_data;
                    REG_TILT_CRIT_H:  tilt_critical_th[15:8] <= wr_data;
                    REG_DISP_CRIT_L:  displacement_critical_th[7:0] <= wr_data;
                    REG_DISP_CRIT_H:  displacement_critical_th[15:8] <= wr_data;

                    REG_WEIGHT_RAIN:  weight_rain <= wr_data[3:0];
                    REG_WEIGHT_WATER: weight_water <= wr_data[3:0];
                    REG_WEIGHT_TILT:  weight_tilt <= wr_data[3:0];
                    REG_WEIGHT_DISP:  weight_displacement <= wr_data[3:0];

                    REG_SCORE_WATCH:    score_watch_th <= wr_data;
                    REG_SCORE_WARNING:  score_warning_th <= wr_data;
                    REG_SCORE_CRITICAL: score_critical_th <= wr_data;
                    REG_PERSIST_UP:     persist_up <= wr_data;
                    REG_PERSIST_DOWN:   persist_down <= wr_data;
                    REG_REQUIRED_MASK:  required_mask <= wr_data[3:0];
                    REG_TIMEOUT_S:      timeout_s <= wr_data;
                    default: begin end
                endcase
            end
        end
    end

    always @(*) begin
        case (rd_addr)
            REG_CHIP_ID:  rd_data = 8'h49;
            REG_VERSION:  rd_data = 8'h10;
            REG_CONTROL:  rd_data = {7'b0, enable};
            REG_STATUS:   rd_data = {3'b000, enable, irq_latched, sensor_fault, risk_level};

            REG_RAIN_L:   rd_data = rain_value[7:0];
            REG_RAIN_H:   rd_data = rain_value[15:8];
            REG_WATER_L:  rd_data = water_value[7:0];
            REG_WATER_H:  rd_data = water_value[15:8];
            REG_TILT_L:   rd_data = tilt_value[7:0];
            REG_TILT_H:   rd_data = tilt_value[15:8];
            REG_DISP_L:   rd_data = displacement_value[7:0];
            REG_DISP_H:   rd_data = displacement_value[15:8];
            REG_VALID_MASK: rd_data = {4'h0, valid_mask};
            REG_COMMIT:     rd_data = 8'h00;
            REG_SAMPLE_AGE: rd_data = sample_age_s;
            REG_REASON:     rd_data = {4'h0, reason_code};

            REG_RAIN_WATCH_L:  rd_data = rain_watch_th[7:0];
            REG_RAIN_WATCH_H:  rd_data = rain_watch_th[15:8];
            REG_WATER_WATCH_L: rd_data = water_watch_th[7:0];
            REG_WATER_WATCH_H: rd_data = water_watch_th[15:8];
            REG_TILT_WATCH_L:  rd_data = tilt_watch_th[7:0];
            REG_TILT_WATCH_H:  rd_data = tilt_watch_th[15:8];
            REG_DISP_WATCH_L:  rd_data = displacement_watch_th[7:0];
            REG_DISP_WATCH_H:  rd_data = displacement_watch_th[15:8];

            REG_RAIN_CRIT_L:  rd_data = rain_critical_th[7:0];
            REG_RAIN_CRIT_H:  rd_data = rain_critical_th[15:8];
            REG_WATER_CRIT_L: rd_data = water_critical_th[7:0];
            REG_WATER_CRIT_H: rd_data = water_critical_th[15:8];
            REG_TILT_CRIT_L:  rd_data = tilt_critical_th[7:0];
            REG_TILT_CRIT_H:  rd_data = tilt_critical_th[15:8];
            REG_DISP_CRIT_L:  rd_data = displacement_critical_th[7:0];
            REG_DISP_CRIT_H:  rd_data = displacement_critical_th[15:8];

            REG_WEIGHT_RAIN:  rd_data = {4'h0, weight_rain};
            REG_WEIGHT_WATER: rd_data = {4'h0, weight_water};
            REG_WEIGHT_TILT:  rd_data = {4'h0, weight_tilt};
            REG_WEIGHT_DISP:  rd_data = {4'h0, weight_displacement};

            REG_SCORE_WATCH:    rd_data = score_watch_th;
            REG_SCORE_WARNING:  rd_data = score_warning_th;
            REG_SCORE_CRITICAL: rd_data = score_critical_th;
            REG_PERSIST_UP:     rd_data = persist_up;
            REG_PERSIST_DOWN:   rd_data = persist_down;
            REG_REQUIRED_MASK:  rd_data = {4'h0, required_mask};
            REG_TIMEOUT_S:      rd_data = timeout_s;

            REG_RISK_SCORE:        rd_data = risk_score;
            REG_RISK_LEVEL:        rd_data = {6'b0, risk_level};
            REG_LAST_EVENT_LEVEL:  rd_data = {6'b0, last_event_level};
            REG_LAST_EVENT_REASON: rd_data = {4'h0, last_event_reason};
            REG_LAST_EVENT_SCORE:  rd_data = last_event_score;
            REG_EVENT_COUNT:       rd_data = event_count;
            REG_SEVERITY:          rd_data = severity_packed;
            REG_SAMPLE_SEQ:        rd_data = sample_seq;
            default:               rd_data = 8'h00;
        endcase
    end

endmodule
