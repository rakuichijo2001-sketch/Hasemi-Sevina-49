`default_nettype none

module hs49_risk_engine (
    input wire [15:0] rain_value, water_value, tilt_value, displacement_value,
    input wire [15:0] rain_watch_th, water_watch_th, tilt_watch_th, displacement_watch_th,
    input wire [15:0] rain_critical_th, water_critical_th, tilt_critical_th, displacement_critical_th,
    input wire [3:0] weight_rain, weight_water, weight_tilt, weight_displacement,
    input wire [7:0] score_watch_th, score_warning_th, score_critical_th,
    output wire [7:0] risk_score,
    output reg  [1:0] candidate_level,
    output wire [3:0] reason_code,
    output wire [7:0] severity_packed,
    output wire       config_fault
);

    function [1:0] severity;
        input [15:0] value;
        input [15:0] watch_th;
        input [15:0] critical_th;
        begin
            if (value >= critical_th)
                severity = 2'd2;
            else if (value >= watch_th)
                severity = 2'd1;
            else
                severity = 2'd0;
        end
    endfunction

    function [5:0] weighted_contribution;
        input [1:0] sev;
        input [3:0] weight;
        begin
            case (sev)
                2'd1: weighted_contribution = {2'b00, weight};
                2'd2: weighted_contribution = {1'b0, weight, 1'b0};
                default: weighted_contribution = 6'd0;
            endcase
        end
    endfunction

    wire [1:0] rain_sev  = severity(rain_value, rain_watch_th, rain_critical_th);
    wire [1:0] water_sev = severity(water_value, water_watch_th, water_critical_th);
    wire [1:0] tilt_sev  = severity(tilt_value, tilt_watch_th, tilt_critical_th);
    wire [1:0] disp_sev  = severity(displacement_value, displacement_watch_th, displacement_critical_th);

    wire [5:0] rain_contrib  = weighted_contribution(rain_sev, weight_rain);
    wire [5:0] water_contrib = weighted_contribution(water_sev, weight_water);
    wire [5:0] tilt_contrib  = weighted_contribution(tilt_sev, weight_tilt);
    wire [5:0] disp_contrib  = weighted_contribution(disp_sev, weight_displacement);

    wire [7:0] score_sum = {2'b00, rain_contrib} +
                           {2'b00, water_contrib} +
                           {2'b00, tilt_contrib} +
                           {2'b00, disp_contrib};

    assign risk_score = score_sum;
    assign reason_code = {
        (disp_sev != 2'd0), (tilt_sev != 2'd0),
        (water_sev != 2'd0), (rain_sev != 2'd0)
    };
    assign severity_packed = {disp_sev, tilt_sev, water_sev, rain_sev};

    assign config_fault =
        (rain_watch_th > rain_critical_th) |
        (water_watch_th > water_critical_th) |
        (tilt_watch_th > tilt_critical_th) |
        (displacement_watch_th > displacement_critical_th) |
        (score_watch_th > score_warning_th) |
        (score_warning_th > score_critical_th);

    always @(*) begin
        if (config_fault)
            candidate_level = 2'd0;
        else if (score_sum >= score_critical_th)
            candidate_level = 2'd3;
        else if (score_sum >= score_warning_th)
            candidate_level = 2'd2;
        else if (score_sum >= score_watch_th)
            candidate_level = 2'd1;
        else
            candidate_level = 2'd0;
    end

endmodule
