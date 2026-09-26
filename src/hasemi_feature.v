`default_nettype none

module hasemi_feature (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_pulse,
    input  wire [15:0] value,
    input  wire [15:0] th_low,
    input  wire [15:0] th_high,
    input  wire [15:0] hysteresis,
    input  wire [7:0]  persist_n,
    output reg  [1:0]  level
);

  reg [1:0] pending_level;
  reg [7:0] pending_count;
  reg [1:0] target_level;
  reg [15:0] low_clear;
  reg [15:0] high_clear;

  always @(*) begin
    low_clear  = (th_low  > hysteresis) ? (th_low  - hysteresis) : 16'd0;
    high_clear = (th_high > hysteresis) ? (th_high - hysteresis) : 16'd0;

    case (level)
      2'd0: begin
        if (value >= th_high)
          target_level = 2'd2;
        else if (value >= th_low)
          target_level = 2'd1;
        else
          target_level = 2'd0;
      end
      2'd1: begin
        if (value >= th_high)
          target_level = 2'd2;
        else if (value < low_clear)
          target_level = 2'd0;
        else
          target_level = 2'd1;
      end
      default: begin
        if (value >= high_clear)
          target_level = 2'd2;
        else if (value >= low_clear)
          target_level = 2'd1;
        else
          target_level = 2'd0;
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      level         <= 2'd0;
      pending_level <= 2'd0;
      pending_count <= 8'd0;
    end else if (sample_pulse) begin
      if (target_level == level) begin
        pending_level <= target_level;
        pending_count <= 8'd0;
      end else if (persist_n <= 8'd1) begin
        level         <= target_level;
        pending_level <= target_level;
        pending_count <= 8'd0;
      end else if (target_level != pending_level) begin
        pending_level <= target_level;
        pending_count <= 8'd1;
      end else if (pending_count + 8'd1 >= persist_n) begin
        level         <= target_level;
        pending_count <= 8'd0;
      end else begin
        pending_count <= pending_count + 8'd1;
      end
    end
  end

endmodule
