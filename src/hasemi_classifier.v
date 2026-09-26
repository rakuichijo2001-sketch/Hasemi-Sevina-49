`default_nettype none

module hasemi_classifier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        classify_pulse,
    input  wire        fault_event,
    input  wire        stale_fault,
    input  wire [1:0]  rr_level,
    input  wire [1:0]  ra_level,
    input  wire [1:0]  water_level,
    input  wire [1:0]  move_level,
    input  wire [1:0]  rate_level,
    input  wire [14:0] weights,
    input  wire [15:0] score_check,
    input  wire [15:0] score_high,
    output reg  [1:0]  state,
    output reg         result_valid,
    output reg         data_fault,
    output reg         state_change,
    output reg  [2:0]  reason,
    output reg  [15:0] score
);

  localparam [1:0] ST_NORMAL = 2'b00;
  localparam [1:0] ST_CHECK  = 2'b01;
  localparam [1:0] ST_HIGH   = 2'b10;
  localparam [1:0] ST_FAULT  = 2'b11;

  wire [2:0] w_rr    = weights[2:0];
  wire [2:0] w_ra    = weights[5:3];
  wire [2:0] w_water = weights[8:6];
  wire [2:0] w_move  = weights[11:9];
  wire [2:0] w_rate  = weights[14:12];

  reg [15:0] score_now;
  reg [1:0] target_state;
  reg [2:0] reason_now;

  always @(*) begin
    score_now =
        (rr_level    * w_rr)    +
        (ra_level    * w_ra)    +
        (water_level * w_water) +
        (move_level  * w_move)  +
        (rate_level  * w_rate);

    reason_now[0] = (rr_level != 2'd0) || (ra_level != 2'd0);
    reason_now[1] = (water_level != 2'd0);
    reason_now[2] = (move_level != 2'd0) || (rate_level != 2'd0);

    if ((move_level == 2'd2) || (rate_level == 2'd2))
      target_state = ST_HIGH;
    else if (score_now >= score_high)
      target_state = ST_HIGH;
    else if (score_now >= score_check)
      target_state = ST_CHECK;
    else
      target_state = ST_NORMAL;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state         <= ST_FAULT;
      result_valid  <= 1'b0;
      data_fault    <= 1'b1;
      state_change  <= 1'b0;
      reason        <= 3'd0;
      score         <= 16'd0;
    end else begin
      state_change <= 1'b0;

      if (fault_event || stale_fault) begin
        if (state != ST_FAULT)
          state_change <= 1'b1;
        state        <= ST_FAULT;
        result_valid <= 1'b0;
        data_fault   <= 1'b1;
        reason       <= 3'd0;
        score        <= 16'd0;
      end else if (classify_pulse) begin
        if (state != target_state)
          state_change <= 1'b1;
        state        <= target_state;
        result_valid <= 1'b1;
        data_fault   <= 1'b0;
        reason       <= reason_now;
        score        <= score_now;
      end
    end
  end

endmodule
