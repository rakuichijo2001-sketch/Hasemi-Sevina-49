`default_nettype none

module hasemi_timebase #(
    parameter integer CLK_HZ = 10000000
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_accept_pulse,
    input  wire [15:0] stale_timeout_s,
    output reg         stale_fault,
    output reg  [15:0] age_seconds
);

  localparam integer COUNTER_W = 24;
  reg [COUNTER_W-1:0] tick_count;
  reg have_sample;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick_count   <= {COUNTER_W{1'b0}};
      age_seconds  <= 16'd0;
      stale_fault  <= 1'b1;
      have_sample  <= 1'b0;
    end else if (sample_accept_pulse) begin
      tick_count   <= {COUNTER_W{1'b0}};
      age_seconds  <= 16'd0;
      stale_fault  <= 1'b0;
      have_sample  <= 1'b1;
    end else if (have_sample) begin
      if (tick_count >= CLK_HZ-1) begin
        tick_count <= {COUNTER_W{1'b0}};
        if (age_seconds != 16'hFFFF)
          age_seconds <= age_seconds + 16'd1;
        if ((stale_timeout_s != 16'd0) && ((age_seconds + 16'd1) >= stale_timeout_s))
          stale_fault <= 1'b1;
      end else begin
        tick_count <= tick_count + 1'b1;
      end
    end
  end

endmodule
