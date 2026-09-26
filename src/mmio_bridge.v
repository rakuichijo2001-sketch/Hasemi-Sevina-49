/*
 * Hasemi-Sevina-49 TinyQV MMIO bridge and register-bank arbiter
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module hs49_mmio_bridge (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [27:0] cpu_addr,
    input  wire  [1:0] cpu_write_n,
    input  wire  [1:0] cpu_read_n,
    input  wire [31:0] cpu_write_data,
    output wire        cpu_ready,
    output reg  [31:0] cpu_read_data,

    input  wire        spi_active,
    input  wire        spi_wr_en,
    input  wire  [6:0] spi_wr_addr,
    input  wire  [7:0] spi_wr_data,
    input  wire  [6:0] spi_rd_addr,
    output wire  [7:0] spi_rd_data,

    output wire        reg_wr_en,
    output wire  [6:0] reg_wr_addr,
    output wire  [7:0] reg_wr_data,
    output wire  [6:0] reg_rd_addr,
    input  wire  [7:0] reg_rd_data
);

    localparam [27:0] HASEMI_MMIO_BASE = 28'h8001000;

    wire cpu_window =
        (cpu_addr[27:7] == HASEMI_MMIO_BASE[27:7]);
    wire cpu_read_req = (cpu_read_n != 2'b11);
    wire cpu_write_req = (cpu_write_n != 2'b11);
    wire cpu_byte_read =
        cpu_read_req && !cpu_write_req && (cpu_read_n == 2'b00);
    wire cpu_byte_write =
        cpu_write_req && !cpu_read_req && (cpu_write_n == 2'b00);
    wire cpu_bank_access =
        cpu_window && (cpu_byte_read || cpu_byte_write);

    // The synchronized SPI transaction-active indication owns the single
    // register-bank port. TinyQV holds its request until cpu_ready is asserted.
    assign cpu_ready = !rst_n ? 1'b0 :
                       cpu_bank_access ? !spi_active : 1'b1;

    // TinyQV consumes a returned 32-bit load over several serial-core cycles,
    // after its read strobe has deasserted. Latch the granted response so an
    // external SPI transaction cannot change it while the CPU consumes it.
    // Unsupported sizes and unmapped reads complete with all ones.
    always @(posedge clk) begin
        if (!rst_n)
            cpu_read_data <= 32'hFFFF_FFFF;
        else if (cpu_read_req && cpu_ready) begin
            if (cpu_window && cpu_byte_read && !spi_active)
                cpu_read_data <= {24'h000000, reg_rd_data};
            else
                cpu_read_data <= 32'hFFFF_FFFF;
        end
    end

    assign reg_rd_addr = spi_active ? spi_rd_addr : cpu_addr[6:0];
    assign spi_rd_data = reg_rd_data;

    assign reg_wr_en = spi_wr_en |
                       (cpu_window && cpu_byte_write && !spi_active && rst_n);
    assign reg_wr_addr = spi_wr_en ? spi_wr_addr : cpu_addr[6:0];
    assign reg_wr_data = spi_wr_en ? spi_wr_data : cpu_write_data[7:0];

endmodule
