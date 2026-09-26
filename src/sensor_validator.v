`default_nettype none

module hs49_sensor_validator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_1hz,
    input  wire       sample_commit,
    input  wire [3:0] valid_mask,
    input  wire [3:0] required_mask,
    input  wire [7:0] timeout_s,
    input  wire       ext_fault,
    output reg  [7:0] sample_age_s,
    output wire       data_fault
);

    wire required_missing = ((valid_mask & required_mask) != required_mask);
    wire stale_data = (timeout_s != 8'd0) && (sample_age_s >= timeout_s);

    assign data_fault = ext_fault | required_missing | stale_data;

    always @(posedge clk) begin
        if (!rst_n)
            sample_age_s <= 8'h00;
        else if (sample_commit)
            sample_age_s <= 8'h00;
        else if (tick_1hz && (sample_age_s != 8'hFF))
            sample_age_s <= sample_age_s + 1'b1;
    end

endmodule
