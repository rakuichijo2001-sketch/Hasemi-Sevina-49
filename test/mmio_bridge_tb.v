`default_nettype none
`timescale 1ns / 1ps

module mmio_bridge_tb;
    reg clk;
    reg rst_n;
    reg [27:0] cpu_addr;
    reg [1:0] cpu_write_n;
    reg [1:0] cpu_read_n;
    reg [31:0] cpu_write_data;
    wire cpu_ready;
    wire [31:0] cpu_read_data;
    reg spi_active;
    reg spi_wr_en;
    reg [6:0] spi_wr_addr;
    reg [7:0] spi_wr_data;
    reg [6:0] spi_rd_addr;
    wire [7:0] spi_rd_data;
    wire reg_wr_en;
    wire [6:0] reg_wr_addr;
    wire [7:0] reg_wr_data;
    wire [6:0] reg_rd_addr;
    reg [7:0] reg_rd_data;

    hs49_mmio_bridge dut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_addr), .cpu_write_n(cpu_write_n),
        .cpu_read_n(cpu_read_n), .cpu_write_data(cpu_write_data),
        .cpu_ready(cpu_ready), .cpu_read_data(cpu_read_data),
        .spi_active(spi_active), .spi_wr_en(spi_wr_en),
        .spi_wr_addr(spi_wr_addr), .spi_wr_data(spi_wr_data),
        .spi_rd_addr(spi_rd_addr), .spi_rd_data(spi_rd_data),
        .reg_wr_en(reg_wr_en), .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data), .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data)
    );

    task check;
        input condition;
        input [255:0] message;
        begin
            if (!condition) begin
                $display("FAIL: %0s", message);
                $fatal(1);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        cpu_addr = 0;
        cpu_write_n = 2'b11;
        cpu_read_n = 2'b11;
        cpu_write_data = 0;
        spi_active = 0;
        spi_wr_en = 0;
        spi_wr_addr = 0;
        spi_wr_data = 0;
        spi_rd_addr = 0;
        reg_rd_data = 8'hA5;
        #1;
        check(cpu_ready == 0, "reset must deassert CPU ready");
        clk = 1;
        #1;
        clk = 0;
        #1;

        rst_n = 1;
        cpu_addr = 28'h7000000;
        cpu_read_n = 2'b00;
        #1;
        check(cpu_ready == 1, "unmapped read must complete");
        check(cpu_read_data == 32'hFFFF_FFFF,
              "unmapped read must return all ones");

        cpu_addr = 28'h8001031;
        #1;
        check(cpu_ready == 1, "byte MMIO read must complete");
        clk = 1;
        #1;
        clk = 0;
        #1;
        check(cpu_read_data == 32'h000000A5,
              "byte MMIO read must zero extend register data");
        check(reg_rd_addr == 7'h31, "CPU read offset must reach bank");

        cpu_read_n = 2'b10;
        clk = 1;
        #1;
        clk = 0;
        #1;
        check(cpu_read_data == 32'hFFFF_FFFF,
              "word MMIO read must return deterministic error value");

        cpu_read_n = 2'b11;
        cpu_write_n = 2'b00;
        cpu_addr = 28'h8001024;
        cpu_write_data = 32'h0000005A;
        #1;
        check(reg_wr_en == 1, "byte MMIO write must pulse bank write");
        check(reg_wr_addr == 7'h24 && reg_wr_data == 8'h5A,
              "byte MMIO write address/data mismatch");

        cpu_write_n = 2'b01;
        #1;
        check(reg_wr_en == 0, "halfword MMIO write must be ignored");

        cpu_write_n = 2'b00;
        spi_active = 1;
        spi_rd_addr = 7'h03;
        #1;
        check(cpu_ready == 0, "SPI must stall concurrent CPU byte MMIO");
        check(reg_wr_en == 0, "stalled CPU write must not reach bank");
        check(reg_rd_addr == 7'h03, "SPI read address must have priority");
        check(spi_rd_data == 8'hA5, "SPI read data must remain connected");

        spi_wr_en = 1;
        spi_wr_addr = 7'h10;
        spi_wr_data = 8'h66;
        #1;
        check(reg_wr_en == 1, "SPI write must reach bank");
        check(reg_wr_addr == 7'h10 && reg_wr_data == 8'h66,
              "SPI write address/data must have priority");

        spi_active = 0;
        spi_wr_en = 0;
        rst_n = 0;
        #1;
        check(reg_wr_en == 0, "reset during CPU write must suppress write");

        $display("PASS: MMIO bridge deterministic semantics and arbitration");
        $finish;
    end
endmodule
