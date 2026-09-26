`default_nettype none

module hs49_spi_slave (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       spi_sclk,
    input  wire       spi_mosi,
    input  wire       spi_cs_n,
    input  wire [7:0] rd_data,
    output reg  [6:0] rd_addr,
    output reg        wr_en,
    output reg  [6:0] wr_addr,
    output reg  [7:0] wr_data,
    output wire       spi_miso
);

    reg [2:0] sclk_sync;
    reg [2:0] cs_sync;
    reg [2:0] mosi_sync;

    wire sclk_rise = (sclk_sync[2:1] == 2'b01);
    wire sclk_fall = (sclk_sync[2:1] == 2'b10);
    wire cs_active = ~cs_sync[2];

    reg [3:0] bit_count;
    reg [7:0] rx_shift;
    reg [7:0] command_byte;
    reg [7:0] tx_shift;
    reg       tx_load_pending;

    wire [7:0] rx_next = {rx_shift[6:0], mosi_sync[2]};

    assign spi_miso = cs_active ? tx_shift[7] : 1'b0;

    always @(posedge clk) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_sync   <= 3'b111;
            mosi_sync <= 3'b000;
        end else begin
            sclk_sync <= {sclk_sync[1:0], spi_sclk};
            cs_sync   <= {cs_sync[1:0], spi_cs_n};
            mosi_sync <= {mosi_sync[1:0], spi_mosi};
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_addr         <= 7'h00;
            wr_en           <= 1'b0;
            wr_addr         <= 7'h00;
            wr_data         <= 8'h00;
            bit_count       <= 4'd0;
            rx_shift        <= 8'h00;
            command_byte    <= 8'h00;
            tx_shift        <= 8'h00;
            tx_load_pending <= 1'b0;
        end else begin
            wr_en <= 1'b0;

            if (!cs_active) begin
                bit_count       <= 4'd0;
                rx_shift        <= 8'h00;
                tx_shift        <= 8'h00;
                tx_load_pending <= 1'b0;
            end else begin
                if (tx_load_pending) begin
                    tx_shift        <= rd_data;
                    tx_load_pending <= 1'b0;
                end

                if (sclk_rise) begin
                    rx_shift <= rx_next;

                    if (bit_count == 4'd7) begin
                        command_byte    <= rx_next;
                        rd_addr         <= rx_next[6:0];
                        tx_load_pending <= 1'b1;
                        bit_count       <= 4'd8;
                    end else if (bit_count == 4'd15) begin
                        if (command_byte[7]) begin
                            wr_en   <= 1'b1;
                            wr_addr <= command_byte[6:0];
                            wr_data <= rx_next;
                        end
                        bit_count <= 4'd0;
                    end else begin
                        bit_count <= bit_count + 1'b1;
                    end
                end

                if (sclk_fall && (bit_count >= 4'd8) && !command_byte[7])
                    tx_shift <= {tx_shift[6:0], 1'b0};
            end
        end
    end

endmodule
