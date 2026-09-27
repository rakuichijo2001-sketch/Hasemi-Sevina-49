`default_nettype none

module hs49_risk_fsm (
    input wire clk,
    input wire rst_n,
    input wire sample_commit,
    input wire enable,
    input wire fault_active,
    input wire [1:0] candidate_level,
    input wire [7:0] persist_up,
    input wire [7:0] persist_down,
    output reg [1:0] risk_level,
    output reg state_change_pulse
);

    reg [1:0] pending_level;
    reg [7:0] pending_count;

    wire [7:0] active_persist =
        (candidate_level > risk_level) ? persist_up : persist_down;

    always @(posedge clk) begin
        if (!rst_n) begin
            risk_level <= 2'd0;
            pending_level <= 2'd0;
            pending_count <= 8'd0;
            state_change_pulse <= 1'b0;
        end else begin
            state_change_pulse <= 1'b0;

            if (!enable) begin
                if (risk_level != 2'd0) begin
                    risk_level <= 2'd0;
                    state_change_pulse <= 1'b1;
                end
                pending_level <= 2'd0;
                pending_count <= 8'd0;
            end else if (sample_commit) begin
                if (fault_active) begin
                    pending_level <= risk_level;
                    pending_count <= 8'd0;
                end else if (candidate_level == risk_level) begin
                    pending_level <= candidate_level;
                    pending_count <= 8'd0;
                end else if (candidate_level != pending_level) begin
                    pending_level <= candidate_level;
                    pending_count <= 8'd1;
                    if (active_persist <= 8'd1) begin
                        risk_level <= candidate_level;
                        state_change_pulse <= 1'b1;
                        pending_count <= 8'd0;
                    end
                end else if ((active_persist <= 8'd1) ||
                             (pending_count >= (active_persist - 1'b1))) begin
                    risk_level <= candidate_level;
                    state_change_pulse <= 1'b1;
                    pending_count <= 8'd0;
                end else begin
                    pending_count <= pending_count + 1'b1;
                end
            end
        end
    end

endmodule
