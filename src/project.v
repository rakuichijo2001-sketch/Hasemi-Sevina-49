/*
 * Hasemi Sevina 49 - Tiny Tapeout SKY26d / SKY130
 * Digital sensor-data condition classifier for slope monitoring research.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_rakuichijo2001_hasemi49 #(
    parameter integer CLK_HZ = 10000000
) (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire spi_miso;
  wire spi_miso_oe;
  wire spi_wr_en;
  wire [6:0] spi_wr_addr;
  wire [15:0] spi_wr_data;
  wire spi_crc_error;
  wire [6:0] spi_rd_addr;
  wire [15:0] spi_rd_data;

  wire sample_commit_pulse;
  wire [15:0] stage_rain_recent;
  wire [15:0] stage_rain_ant;
  wire [15:0] stage_water;
  wire [15:0] stage_movement;
  wire [15:0] stage_move_rate;
  wire [15:0] stage_seq;
  wire [4:0] stage_valid_mask;

  wire [15:0] th_rr_low;
  wire [15:0] th_rr_high;
  wire [15:0] th_ra_low;
  wire [15:0] th_ra_high;
  wire [15:0] th_water_low;
  wire [15:0] th_water_high;
  wire [15:0] th_move_low;
  wire [15:0] th_move_high;
  wire [15:0] th_rate_low;
  wire [15:0] th_rate_high;
  wire [15:0] score_check;
  wire [15:0] score_high;
  wire [14:0] weights;
  wire [15:0] hysteresis;
  wire [7:0] persist_n;
  wire [15:0] stale_timeout_s;
  wire [4:0] required_mask;
  wire [15:0] max_rr;
  wire [15:0] max_ra;
  wire [15:0] max_water;
  wire [15:0] max_move;
  wire [15:0] max_rate;
  wire config_valid;
  wire [15:0] crc_error_count;

  wire sample_accept_pulse;
  wire sample_fault_pulse;
  wire [7:0] validator_fault_code;
  wire [15:0] latest_seq;

  wire [1:0] rr_level;
  wire [1:0] ra_level;
  wire [1:0] water_level;
  wire [1:0] move_level;
  wire [1:0] rate_level;

  reg classify_pulse;
  reg crc_fault_active;

  wire stale_fault;
  wire [15:0] age_seconds;
  wire [1:0] state;
  wire result_valid;
  wire data_fault;
  wire state_change;
  wire [2:0] reason;
  wire [15:0] score;
  wire [7:0] fault_code = validator_fault_code |
                          (stale_fault ? 8'h20 : 8'h00) |
                          (crc_fault_active ? 8'h40 : 8'h00);

  hasemi_spi u_spi (
      .clk(clk),
      .rst_n(rst_n),
      .cs_n_i(uio_in[0]),
      .sck_i(uio_in[3]),
      .mosi_i(uio_in[1]),
      .miso_o(spi_miso),
      .miso_oe(spi_miso_oe),
      .wr_en(spi_wr_en),
      .wr_addr(spi_wr_addr),
      .wr_data(spi_wr_data),
      .crc_error(spi_crc_error),
      .rd_addr(spi_rd_addr),
      .rd_data(spi_rd_data)
  );

  hasemi_regfile u_regfile (
      .clk(clk),
      .rst_n(rst_n),
      .wr_en(spi_wr_en),
      .wr_addr(spi_wr_addr),
      .wr_data(spi_wr_data),
      .rd_addr(spi_rd_addr),
      .rd_data(spi_rd_data),
      .crc_error_pulse(spi_crc_error),
      .state(state),
      .result_valid(result_valid),
      .data_fault(data_fault),
      .state_change(state_change),
      .reason(reason),
      .fault_code(fault_code),
      .latest_seq(latest_seq),
      .score(score),
      .sample_commit_pulse(sample_commit_pulse),
      .stage_rain_recent(stage_rain_recent),
      .stage_rain_ant(stage_rain_ant),
      .stage_water(stage_water),
      .stage_movement(stage_movement),
      .stage_move_rate(stage_move_rate),
      .stage_seq(stage_seq),
      .stage_valid_mask(stage_valid_mask),
      .th_rr_low(th_rr_low),
      .th_rr_high(th_rr_high),
      .th_ra_low(th_ra_low),
      .th_ra_high(th_ra_high),
      .th_water_low(th_water_low),
      .th_water_high(th_water_high),
      .th_move_low(th_move_low),
      .th_move_high(th_move_high),
      .th_rate_low(th_rate_low),
      .th_rate_high(th_rate_high),
      .score_check(score_check),
      .score_high(score_high),
      .weights(weights),
      .hysteresis(hysteresis),
      .persist_n(persist_n),
      .stale_timeout_s(stale_timeout_s),
      .required_mask(required_mask),
      .max_rr(max_rr),
      .max_ra(max_ra),
      .max_water(max_water),
      .max_move(max_move),
      .max_rate(max_rate),
      .config_valid(config_valid),
      .crc_error_count(crc_error_count)
  );

  hasemi_validator u_validator (
      .clk(clk),
      .rst_n(rst_n),
      .commit_pulse(sample_commit_pulse),
      .config_valid(config_valid),
      .required_mask(required_mask),
      .valid_mask(stage_valid_mask),
      .seq(stage_seq),
      .rain_recent(stage_rain_recent),
      .rain_ant(stage_rain_ant),
      .water(stage_water),
      .movement(stage_movement),
      .move_rate(stage_move_rate),
      .max_rr(max_rr),
      .max_ra(max_ra),
      .max_water(max_water),
      .max_move(max_move),
      .max_rate(max_rate),
      .accept_pulse(sample_accept_pulse),
      .fault_pulse(sample_fault_pulse),
      .fault_code(validator_fault_code),
      .latest_seq(latest_seq)
  );

  hasemi_feature u_feat_rr (
      .clk(clk), .rst_n(rst_n), .sample_pulse(sample_accept_pulse),
      .value(stage_rain_recent), .th_low(th_rr_low), .th_high(th_rr_high),
      .hysteresis(hysteresis), .persist_n(persist_n), .level(rr_level));

  hasemi_feature u_feat_ra (
      .clk(clk), .rst_n(rst_n), .sample_pulse(sample_accept_pulse),
      .value(stage_rain_ant), .th_low(th_ra_low), .th_high(th_ra_high),
      .hysteresis(hysteresis), .persist_n(persist_n), .level(ra_level));

  hasemi_feature u_feat_water (
      .clk(clk), .rst_n(rst_n), .sample_pulse(sample_accept_pulse),
      .value(stage_water), .th_low(th_water_low), .th_high(th_water_high),
      .hysteresis(hysteresis), .persist_n(persist_n), .level(water_level));

  hasemi_feature u_feat_move (
      .clk(clk), .rst_n(rst_n), .sample_pulse(sample_accept_pulse),
      .value(stage_movement), .th_low(th_move_low), .th_high(th_move_high),
      .hysteresis(hysteresis), .persist_n(persist_n), .level(move_level));

  hasemi_feature u_feat_rate (
      .clk(clk), .rst_n(rst_n), .sample_pulse(sample_accept_pulse),
      .value(stage_move_rate), .th_low(th_rate_low), .th_high(th_rate_high),
      .hysteresis(hysteresis), .persist_n(persist_n), .level(rate_level));

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      classify_pulse  <= 1'b0;
      crc_fault_active <= 1'b0;
    end else begin
      classify_pulse <= sample_accept_pulse;
      if (spi_crc_error)
        crc_fault_active <= 1'b1;
      else if (spi_wr_en)
        crc_fault_active <= 1'b0;
    end
  end

  hasemi_timebase #(.CLK_HZ(CLK_HZ)) u_timebase (
      .clk(clk),
      .rst_n(rst_n),
      .sample_accept_pulse(sample_accept_pulse),
      .stale_timeout_s(stale_timeout_s),
      .stale_fault(stale_fault),
      .age_seconds(age_seconds)
  );

  hasemi_classifier u_classifier (
      .clk(clk),
      .rst_n(rst_n),
      .classify_pulse(classify_pulse),
      .fault_event(sample_fault_pulse),
      .stale_fault(stale_fault),
      .rr_level(rr_level),
      .ra_level(ra_level),
      .water_level(water_level),
      .move_level(move_level),
      .rate_level(rate_level),
      .weights(weights),
      .score_check(score_check),
      .score_high(score_high),
      .state(state),
      .result_valid(result_valid),
      .data_fault(data_fault),
      .state_change(state_change),
      .reason(reason),
      .score(score)
  );

  assign uo_out[1:0] = state;
  assign uo_out[2] = result_valid;
  assign uo_out[3] = data_fault;
  assign uo_out[4] = state_change;
  assign uo_out[5] = reason[0];
  assign uo_out[6] = reason[1];
  assign uo_out[7] = reason[2];

  assign uio_out = {5'd0, spi_miso, 2'd0};
  assign uio_oe  = {5'd0, spi_miso_oe, 2'd0};

  wire _unused = &{ena, ui_in, uio_in[7:4], age_seconds, crc_error_count, 1'b0};

endmodule
