`default_nettype none

module hasemi_validator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        commit_pulse,
    input  wire        config_valid,
    input  wire [4:0]  required_mask,
    input  wire [4:0]  valid_mask,
    input  wire [15:0] seq,
    input  wire [15:0] rain_recent,
    input  wire [15:0] rain_ant,
    input  wire [15:0] water,
    input  wire [15:0] movement,
    input  wire [15:0] move_rate,
    input  wire [15:0] max_rr,
    input  wire [15:0] max_ra,
    input  wire [15:0] max_water,
    input  wire [15:0] max_move,
    input  wire [15:0] max_rate,
    output reg         accept_pulse,
    output reg         fault_pulse,
    output reg  [7:0]  fault_code,
    output reg  [15:0] latest_seq
);

  reg have_seq;
  reg [7:0] error_now;

  function range_bad;
    input [15:0] value;
    input [15:0] max_value;
    begin
      range_bad = (max_value != 16'd0) && (value > max_value);
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accept_pulse <= 1'b0;
      fault_pulse  <= 1'b0;
      fault_code   <= 8'd0;
      latest_seq   <= 16'd0;
      have_seq     <= 1'b0;
    end else begin
      accept_pulse <= 1'b0;
      fault_pulse  <= 1'b0;

      if (commit_pulse) begin
        error_now = 8'd0;

        if (!config_valid)
          error_now[0] = 1'b1;

        if ((valid_mask & required_mask) != required_mask)
          error_now[1] = 1'b1;

        if ((required_mask[0] && range_bad(rain_recent, max_rr)) ||
            (required_mask[1] && range_bad(rain_ant, max_ra)) ||
            (required_mask[2] && range_bad(water, max_water)) ||
            (required_mask[3] && range_bad(movement, max_move)) ||
            (required_mask[4] && range_bad(move_rate, max_rate)))
          error_now[2] = 1'b1;

        if (have_seq) begin
          if (seq == latest_seq)
            error_now[3] = 1'b1;
          else if (seq != (latest_seq + 16'd1))
            error_now[4] = 1'b1;
        end

        if (error_now != 8'd0) begin
          fault_pulse <= 1'b1;
          fault_code  <= error_now;
        end else begin
          accept_pulse <= 1'b1;
          fault_code   <= 8'd0;
          latest_seq   <= seq;
          have_seq     <= 1'b1;
        end
      end
    end
  end

endmodule
