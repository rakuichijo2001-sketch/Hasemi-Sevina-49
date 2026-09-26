`default_nettype none

module hasemi_regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr_en,
    input  wire [6:0]  wr_addr,
    input  wire [15:0] wr_data,
    input  wire [6:0]  rd_addr,
    output reg  [15:0] rd_data,
    input  wire        crc_error_pulse,

    input  wire [1:0]  state,
    input  wire        result_valid,
    input  wire        data_fault,
    input  wire        state_change,
    input  wire [2:0]  reason,
    input  wire [7:0]  fault_code,
    input  wire [15:0] latest_seq,
    input  wire [15:0] score,

    output reg         sample_commit_pulse,
    output reg  [15:0] stage_rain_recent,
    output reg  [15:0] stage_rain_ant,
    output reg  [15:0] stage_water,
    output reg  [15:0] stage_movement,
    output reg  [15:0] stage_move_rate,
    output reg  [15:0] stage_seq,
    output reg  [4:0]  stage_valid_mask,

    output reg  [15:0] th_rr_low,
    output reg  [15:0] th_rr_high,
    output reg  [15:0] th_ra_low,
    output reg  [15:0] th_ra_high,
    output reg  [15:0] th_water_low,
    output reg  [15:0] th_water_high,
    output reg  [15:0] th_move_low,
    output reg  [15:0] th_move_high,
    output reg  [15:0] th_rate_low,
    output reg  [15:0] th_rate_high,
    output reg  [15:0] score_check,
    output reg  [15:0] score_high,
    output reg  [14:0] weights,
    output reg  [15:0] hysteresis,
    output reg  [7:0]  persist_n,
    output reg  [15:0] stale_timeout_s,
    output reg  [4:0]  required_mask,
    output reg  [15:0] max_rr,
    output reg  [15:0] max_ra,
    output reg  [15:0] max_water,
    output reg  [15:0] max_move,
    output reg  [15:0] max_rate,
    output reg         config_valid,
    output reg  [15:0] crc_error_count
);

  localparam [15:0] SAMPLE_COMMIT_MAGIC = 16'hA55A;
  localparam [15:0] CONFIG_COMMIT_MAGIC = 16'hC0DE;

  wire config_structure_ok =
      (th_rr_low    <= th_rr_high)    &&
      (th_ra_low    <= th_ra_high)    &&
      (th_water_low <= th_water_high) &&
      (th_move_low  <= th_move_high)  &&
      (th_rate_low  <= th_rate_high)  &&
      (score_check  <  score_high)    &&
      (persist_n    != 8'd0)          &&
      (stale_timeout_s != 16'd0)      &&
      (required_mask != 5'd0);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sample_commit_pulse <= 1'b0;
      stage_rain_recent <= 16'd0;
      stage_rain_ant    <= 16'd0;
      stage_water       <= 16'd0;
      stage_movement    <= 16'd0;
      stage_move_rate   <= 16'd0;
      stage_seq         <= 16'd0;
      stage_valid_mask  <= 5'd0;

      th_rr_low    <= 16'd0;
      th_rr_high   <= 16'd0;
      th_ra_low    <= 16'd0;
      th_ra_high   <= 16'd0;
      th_water_low <= 16'd0;
      th_water_high<= 16'd0;
      th_move_low  <= 16'd0;
      th_move_high <= 16'd0;
      th_rate_low  <= 16'd0;
      th_rate_high <= 16'd0;
      score_check  <= 16'd0;
      score_high   <= 16'd0;
      weights      <= 15'd0;
      hysteresis   <= 16'd0;
      persist_n    <= 8'd0;
      stale_timeout_s <= 16'd0;
      required_mask <= 5'd0;
      max_rr       <= 16'd0;
      max_ra       <= 16'd0;
      max_water    <= 16'd0;
      max_move     <= 16'd0;
      max_rate     <= 16'd0;
      config_valid <= 1'b0;
      crc_error_count <= 16'd0;
    end else begin
      sample_commit_pulse <= 1'b0;

      if (crc_error_pulse && crc_error_count != 16'hFFFF)
        crc_error_count <= crc_error_count + 16'd1;

      if (wr_en) begin
        case (wr_addr)
          7'h10: stage_rain_recent <= wr_data;
          7'h11: stage_rain_ant    <= wr_data;
          7'h12: stage_water       <= wr_data;
          7'h13: stage_movement    <= wr_data;
          7'h14: stage_move_rate   <= wr_data;
          7'h15: stage_seq         <= wr_data;
          7'h16: stage_valid_mask  <= wr_data[4:0];
          7'h17: if (wr_data == SAMPLE_COMMIT_MAGIC) sample_commit_pulse <= 1'b1;

          7'h20: begin th_rr_low     <= wr_data; config_valid <= 1'b0; end
          7'h21: begin th_rr_high    <= wr_data; config_valid <= 1'b0; end
          7'h22: begin th_ra_low     <= wr_data; config_valid <= 1'b0; end
          7'h23: begin th_ra_high    <= wr_data; config_valid <= 1'b0; end
          7'h24: begin th_water_low  <= wr_data; config_valid <= 1'b0; end
          7'h25: begin th_water_high <= wr_data; config_valid <= 1'b0; end
          7'h26: begin th_move_low   <= wr_data; config_valid <= 1'b0; end
          7'h27: begin th_move_high  <= wr_data; config_valid <= 1'b0; end
          7'h28: begin th_rate_low   <= wr_data; config_valid <= 1'b0; end
          7'h29: begin th_rate_high  <= wr_data; config_valid <= 1'b0; end
          7'h2A: begin score_check   <= wr_data; config_valid <= 1'b0; end
          7'h2B: begin score_high    <= wr_data; config_valid <= 1'b0; end
          7'h2C: begin weights       <= wr_data[14:0]; config_valid <= 1'b0; end
          7'h2D: begin hysteresis    <= wr_data; config_valid <= 1'b0; end
          7'h2E: begin persist_n     <= wr_data[7:0]; config_valid <= 1'b0; end
          7'h2F: begin stale_timeout_s <= wr_data; config_valid <= 1'b0; end
          7'h30: begin required_mask <= wr_data[4:0]; config_valid <= 1'b0; end
          7'h31: begin max_rr        <= wr_data; config_valid <= 1'b0; end
          7'h32: begin max_ra        <= wr_data; config_valid <= 1'b0; end
          7'h33: begin max_water     <= wr_data; config_valid <= 1'b0; end
          7'h34: begin max_move      <= wr_data; config_valid <= 1'b0; end
          7'h35: begin max_rate      <= wr_data; config_valid <= 1'b0; end
          7'h36: begin
            if (wr_data == CONFIG_COMMIT_MAGIC && config_structure_ok)
              config_valid <= 1'b1;
            else
              config_valid <= 1'b0;
          end
          default: ;
        endcase
      end
    end
  end

  always @(*) begin
    case (rd_addr)
      7'h00: rd_data = {11'd0, state_change, data_fault, result_valid, state};
      7'h01: rd_data = {13'd0, reason};
      7'h02: rd_data = {8'd0, fault_code};
      7'h03: rd_data = latest_seq;
      7'h04: rd_data = crc_error_count;
      7'h05: rd_data = {11'd0, stage_valid_mask};
      7'h06: rd_data = score;
      7'h07: rd_data = {15'd0, config_valid};
      7'h10: rd_data = stage_rain_recent;
      7'h11: rd_data = stage_rain_ant;
      7'h12: rd_data = stage_water;
      7'h13: rd_data = stage_movement;
      7'h14: rd_data = stage_move_rate;
      7'h15: rd_data = stage_seq;
      7'h16: rd_data = {11'd0, stage_valid_mask};
      7'h20: rd_data = th_rr_low;
      7'h21: rd_data = th_rr_high;
      7'h22: rd_data = th_ra_low;
      7'h23: rd_data = th_ra_high;
      7'h24: rd_data = th_water_low;
      7'h25: rd_data = th_water_high;
      7'h26: rd_data = th_move_low;
      7'h27: rd_data = th_move_high;
      7'h28: rd_data = th_rate_low;
      7'h29: rd_data = th_rate_high;
      7'h2A: rd_data = score_check;
      7'h2B: rd_data = score_high;
      7'h2C: rd_data = {1'b0, weights};
      7'h2D: rd_data = hysteresis;
      7'h2E: rd_data = {8'd0, persist_n};
      7'h2F: rd_data = stale_timeout_s;
      7'h30: rd_data = {11'd0, required_mask};
      7'h31: rd_data = max_rr;
      7'h32: rd_data = max_ra;
      7'h33: rd_data = max_water;
      7'h34: rd_data = max_move;
      7'h35: rd_data = max_rate;
      7'h36: rd_data = {15'd0, config_valid};
      7'h7F: rd_data = 16'h4849;
      default: rd_data = 16'd0;
    endcase
  end

endmodule
