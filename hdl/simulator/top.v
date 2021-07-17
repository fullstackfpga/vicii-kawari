`timescale 1ns/1ps

`include "common.vh"

// Top level module for the simulator.
//
`ifndef SIMULATOR_BOARD
ERROR_NEED_SIMULATOR_BOARD_DEFINED See common.vh
`endif

                                   module top(
                                       input clk_col4x,     // driven by sim
                                       input clk_col16x,    // driven by sim

                                       output cpu_reset,    // reset for 6510 CPU
                                       input cpu_reset_i,
                                       input cfg_reset,
                                       input cfg1,
                                       input cfg2,
                                       input cfg3,
                                       input standard_sw,   // video standard toggle switch
                                       output clk_phi,      // output phi clock for CPU
                                       output clk_dot4x,    // pixel clock
`ifdef GEN_RGB
                                       output active,       // display active for HDMI
                                       output hsync,        // hsync signal for VGA/HDMI
                                       output vsync,        // vsync signal for VGA/HDMI
                                       output [5:0] red,    // red out
                                       output [5:0] green,  // green out
                                       output [5:0] blue,   // blue out
`endif

                                       // If we are generating luma/chroma, add outputs
`ifdef GEN_LUMA_CHROMA
                                       output [5:0] luma,    // luma out
                                       output [5:0] chroma,  // chroma out
`endif


`ifdef HAVE_FLASH
                                       output flash_s,
`endif
`ifdef WITH_SPI
                                       output spi_d,
                                       input  spi_q,
                                       output spi_c,
`endif
`ifdef HAVE_EEPROM
                                       output eeprom_s,
`endif

                                       // Verilog doesn't support inout/tri so this section is
                                       // slightly different than non-sim top
                                       input [5:0] adl,  // address (lower 6 bits)
                                       output [5:0] adh, // address (upper 6 bits)
                                       input [7:0] dbl,  // data bus lines (ram/rom)
                                       input [3:0] dbh,  // data bus lines (color)
                                       output [7:0] dbo_sim,  // for our simulator
                                       output [11:0] ado_sim, // for our simulator
                                       // End diff

                                       input ce,            // chip enable (LOW=enable, HIGH=disabled)
                                       input rw,            // read/write (LOW=write, HIGH=read)
                                       output irq,          // irq
                                       input lp,            // light pen
                                       output aec,          // aec
                                       output ba,           // ba
                                       output cas,          // column address strobe
                                       output ras,          // row address strobe
                                       output ls245_data_dir,  // DIR for data bus transceiver
                                       output ls245_addr_dir   // DIR for addr bus transceiver
`ifdef WITH_DVI
                                       ,
                                       output wire [3:0] TX0_TMDS,
                                       output wire [3:0] TX0_TMDSB
`endif

                                   );

wire rst;
wire [1:0] chip;

`ifndef GEN_RGB
// When we're not exporting these signals, we still need
// them defined as wires (for DVI for example).
`ifdef NEED_RGB
wire hsync;
wire vsync;
wire active;
wire [5:0] red;
wire [5:0] green;
wire [5:0] blue;
`endif
`endif

`ifdef WITH_DVI
// For config test only
assign TX0_TMDS[0] = 1;
assign TX0_TMDS[1] = 0;
assign TX0_TMDS[2] = 1;
assign TX0_TMDS[3] = 0;
assign TX0_TMDSB[0] = 1;
assign TX0_TMDSB[1] = 0;
assign TX0_TMDSB[2] = 1;
assign TX0_TMDSB[3] = 0;
`endif


// This is a reset line for the CPU which would have to be
// connected with a jumper.  It holds the CPU in reset
// before the clock is locked.  TODO: Find out if this is
// actually required.
assign cpu_reset = rst;

wire [7:0] dbo;
wire [11:0] ado;

// When these are true, the VIC is writing to the data
// or address bus so ab/db will be assigned from
// ado/dbo respectively.  Otherwise, we tri-state
// those lines and VIC can read from adi/dbi.
// NOTE: The VIC only ever reads the lower 6 bits from
// the address lines. This is the reason for the adl/adh
// split below.
wire vic_write_ab;
wire vic_write_db;

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
          .cpu_reset_i(cpu_reset_i),
          .standard_sw(standard_sw),
`ifdef HAVE_EEPROM
          .cfg_reset(cfg_reset),
`endif
          .spi_lock(cfg1),
          .extensions_lock(cfg2),
          .persistence_lock(cfg3),
          .clk_dot4x(clk_dot4x),
          .clk_phi(clk_phi),
`ifdef NEED_RGB
          .active(active),
          .hsync(hsync),
          .vsync(vsync),
          .red(red),
          .green(green),
          .blue(blue),
`endif
          .clk_col16x(clk_col16x),
`ifdef GEN_LUMA_CHROMA
          .luma(luma),
          .chroma(chroma),
`endif
`ifdef HAVE_FLASH
          .flash_s(flash_s),
`endif
`ifdef WITH_SPI
          .spi_d(spi_d),
          .spi_q(spi_q),
          .spi_c(spi_c),
`endif
`ifdef HAVE_EEPROM
          .eeprom_s(eeprom_s),
`endif
          .adi(adl[5:0]),
          .ado(ado),
          .dbi({dbh,dbl}),
          .dbo(dbo),
          .ce(ce),
          .rw(rw),
          .aec(aec),
          .irq(irq),
          .lp(lp),
          .ba(ba),
          .cas(cas),
          .ras(ras),
          .ls245_data_dir(ls245_data_dir),
          .ls245_addr_dir(ls245_addr_dir),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

// Diff for Verilator, no tri state so use _sim regs
assign ado_sim = ado;
assign dbo_sim = dbo;
// End diff

endmodule : top
