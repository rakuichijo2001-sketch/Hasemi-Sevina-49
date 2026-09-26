`default_nettype none

module hs49_event_logger (
    input wire clk,
    input wire rst_n,
    input wire [1:0] risk_level,
    input wire [3:0] reason_code,
    input wire [7:0] risk_score,
    input wire sensor_fault,
    input wire state_change_pulse,
    input wire clear_irq,
    input wire clear_events,
    output reg [7:0] event_count,
    output reg [1:0] last_event_level,
    output reg [3:0] last_event_reason,
    output reg [7:0] last_event_score,
    output reg irq_latched
);

    reg prev_fault;
    wire fault_rise = sensor_fault & ~prev_fault;
    wire event_trigger = state_change_pulse | fault_rise;

    always @(posedge clk) begin
        if (!rst_n) begin
            event_count <= 8'h00;
            last_event_level <= 2'd0;
            last_event_reason <= 4'h0;
            last_event_score <= 8'h00;
            irq_latched <= 1'b0;
            prev_fault <= 1'b0;
        end else begin
            prev_fault <= sensor_fault;

            if (clear_events) begin
                event_count <= 8'h00;
                last_event_level <= 2'd0;
                last_event_reason <= 4'h0;
                last_event_score <= 8'h00;
            end else if (event_trigger) begin
                if (event_count != 8'hFF)
                    event_count <= event_count + 1'b1;
                last_event_level <= risk_level;
                last_event_reason <= reason_code;
                last_event_score <= risk_score;
            end

            if (clear_irq)
                irq_latched <= 1'b0;
            else if (event_trigger)
                irq_latched <= 1'b1;
        end
    end

endmodule
