`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in_direct;
  reg qspi_model_enable;
  reg [2:0] qspi_latency_cfg;
  wire [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  wire [3:0] qspi_data_to_memory = {uio_out[5:4], uio_out[2:1]};
  wire [3:0] qspi_data_from_memory;
  wire [3:0] qspi_data_to_dut = rst_n ?
      qspi_data_from_memory : {1'b0, qspi_latency_cfg};

  assign uio_in = qspi_model_enable ?
      {2'b00, qspi_data_to_dut[3:2], 1'b0,
       qspi_data_to_dut[1:0], 1'b0} : uio_in_direct;

  sim_qspi_pmod qspi_model (
      .qspi_data_in(qspi_data_to_memory),
      .qspi_data_out(qspi_data_from_memory),
      .qspi_clk(uio_out[3]),
      .qspi_flash_select(uio_out[0]),
      .qspi_ram_a_select(uio_out[6]),
      .qspi_ram_b_select(uio_out[7]),
      .debug_clk(clk),
      .debug_addr(25'h0000000),
      .debug_data()
  );

  defparam qspi_model.INIT_FILE = "firmware/hasemi_v02.hex";

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  tt_um_rakuichijo2001_hasemi_sevina_49 user_project (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in(ui_in),
      .uo_out(uo_out),
      .uio_in(uio_in),
      .uio_out(uio_out),
      .uio_oe(uio_oe),
      .ena(ena),
      .clk(clk),
      .rst_n(rst_n)
  );

endmodule
