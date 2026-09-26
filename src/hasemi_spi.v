`default_nettype none

module hasemi_spi (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs_n_i,
    input  wire        sck_i,
    input  wire        mosi_i,
    output reg         miso_o,
    output wire        miso_oe,
    output reg         wr_en,
    output reg  [6:0]  wr_addr,
    output reg  [15:0] wr_data,
    output reg         crc_error,
    output reg  [6:0]  rd_addr,
    input  wire [15:0] rd_data
);

  reg [1:0] cs_sync;
  reg [1:0] sck_sync;
  reg [1:0] mosi_sync;
  reg       sck_d;

  reg [2:0] bit_count;
  reg [1:0] byte_count;
  reg [7:0] rx_shift;
  reg [7:0] cmd_byte;
  reg [7:0] data_hi;
  reg [7:0] data_lo;
  reg [7:0] crc_calc;
  reg [15:0] read_latched;
  reg [7:0] read_crc;
  reg       is_read;

  wire cs_n = cs_sync[1];
  wire sck  = sck_sync[1];
  wire mosi = mosi_sync[1];
  wire sck_rise = sck & ~sck_d;
  wire sck_fall = ~sck & sck_d;

  assign miso_oe = (~cs_n) & is_read & (byte_count != 2'd0);

  function [7:0] crc8_byte;
    input [7:0] crc_in;
    input [7:0] data_in;
    integer i;
    reg [7:0] c;
    begin
      c = crc_in ^ data_in;
      for (i = 0; i < 8; i = i + 1) begin
        if (c[7])
          c = (c << 1) ^ 8'h07;
        else
          c = (c << 1);
      end
      crc8_byte = c;
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cs_sync   <= 2'b11;
      sck_sync  <= 2'b00;
      mosi_sync <= 2'b00;
      sck_d     <= 1'b0;
    end else begin
      cs_sync   <= {cs_sync[0], cs_n_i};
      sck_sync  <= {sck_sync[0], sck_i};
      mosi_sync <= {mosi_sync[0], mosi_i};
      sck_d     <= sck;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    reg [7:0] rx_byte;
    if (!rst_n) begin
      bit_count    <= 3'd0;
      byte_count   <= 2'd0;
      rx_shift     <= 8'd0;
      cmd_byte     <= 8'd0;
      data_hi      <= 8'd0;
      data_lo      <= 8'd0;
      crc_calc     <= 8'd0;
      read_latched <= 16'd0;
      read_crc     <= 8'd0;
      is_read      <= 1'b0;
      miso_o       <= 1'b0;
      wr_en        <= 1'b0;
      wr_addr      <= 7'd0;
      wr_data      <= 16'd0;
      crc_error    <= 1'b0;
      rd_addr      <= 7'd0;
    end else begin
      wr_en     <= 1'b0;
      crc_error <= 1'b0;

      if (cs_n) begin
        bit_count  <= 3'd0;
        byte_count <= 2'd0;
        rx_shift   <= 8'd0;
        is_read    <= 1'b0;
        miso_o     <= 1'b0;
      end else begin
        if (sck_rise) begin
          rx_byte = {rx_shift[6:0], mosi};
          rx_shift <= rx_byte;

          if (bit_count == 3'd7) begin
            bit_count <= 3'd0;
            byte_count <= byte_count + 2'd1;

            case (byte_count)
              2'd0: begin
                cmd_byte <= rx_byte;
                rd_addr  <= rx_byte[6:0];
                is_read  <= rx_byte[7];
                crc_calc <= crc8_byte(8'h00, rx_byte);
              end
              2'd1: begin
                data_hi <= rx_byte;
                if (!is_read)
                  crc_calc <= crc8_byte(crc_calc, rx_byte);
              end
              2'd2: begin
                data_lo <= rx_byte;
                if (!is_read)
                  crc_calc <= crc8_byte(crc_calc, rx_byte);
              end
              2'd3: begin
                if (!is_read) begin
                  if (rx_byte == crc_calc) begin
                    wr_en   <= 1'b1;
                    wr_addr <= cmd_byte[6:0];
                    wr_data <= {data_hi, data_lo};
                  end else begin
                    crc_error <= 1'b1;
                  end
                end
              end
            endcase
          end else begin
            bit_count <= bit_count + 3'd1;
          end
        end

        if (sck_fall) begin
          case (byte_count)
            2'd0: miso_o <= 1'b0;
            2'd1: begin
              if (bit_count == 3'd0) begin
                read_latched <= rd_data;
                read_crc <= crc8_byte(crc8_byte(crc8_byte(8'h00, cmd_byte), rd_data[15:8]), rd_data[7:0]);
                miso_o <= rd_data[15];
              end else begin
                miso_o <= read_latched[15 - bit_count];
              end
            end
            2'd2: miso_o <= read_latched[7 - bit_count];
            2'd3: miso_o <= read_crc[7 - bit_count];
          endcase
        end
      end
    end
  end

endmodule
