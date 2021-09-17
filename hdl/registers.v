`timescale 1ns / 1ps

`include "common.vh"

module registers
    #(
        parameter ram_width = `VIDEO_RAM_WIDTH,
                  ram_hi_width = `VIDEO_RAM_HI_WIDTH
    )
    (
           output reg rst = 1'b1,
           input cpu_reset_i,
           input standard_sw,
`ifdef HAVE_FLASH
           output reg flash_s = 1'b1,
`endif
`ifdef HAVE_EEPROM
           input cfg_reset,
`endif
           input spi_lock,
           input extensions_lock,
           input persistence_lock,
`ifdef CMOD_BOARD
           input [1:0] btn,
           output [1:0] led,
`endif
           input clk_dot4x,
           input clk_phi,
           input phi_phase_start_dav_plus_2,
           input phi_phase_start_dav_plus_1,
           input phi_phase_start_dav,
           input ras,
           input ce,
           input rw,
           input aec,
           input [5:0] adi,
           input [7:0] dbi,
           input [8:0] raster_line,
           input irq,
           input ilp,
           input immc,
           input imbc,
           input irst,
           input [7:0] sprite_m2m,
           input [7:0] sprite_m2d,
           input [7:0] lpx,
           input [7:0] lpy,

           output reg [3:0] ec,
           output reg [3:0] b0c,
           output reg [3:0] b1c,
           output reg [3:0] b2c,
           output reg [3:0] b3c,
           output reg [2:0] xscroll,
           output reg [2:0] yscroll,
           output reg csel,
           output reg rsel,
           output reg den,
           output reg bmm,
           output reg ecm,
           output reg mcm,
           output reg irst_clr,
           output reg imbc_clr,
           output reg immc_clr,
           output reg ilp_clr,
           output reg [8:0] raster_irq_compare,
           output reg [7:0] sprite_en,
           output reg [7:0] sprite_xe,
           output reg [7:0] sprite_ye,
           output reg [7:0] sprite_pri,
           output reg [7:0] sprite_mmc,
           output reg [3:0] sprite_mc0,
           output reg [3:0] sprite_mc1,
           output [71:0] sprite_x_o,
           output [63:0] sprite_y_o,
           output [31:0] sprite_col_o,
           output reg m2m_clr,
           output reg m2d_clr,
           output reg handle_sprite_crunch,
           output reg [7:0] dbo,
           output reg [7:0] last_bus,
           output reg [2:0] cb,
           output reg [3:0] vm,
           output reg elp,
           output reg emmc,
           output reg embc,
           output reg erst,
           // pixel_color3 is from native res pixel sequencer and should be used
           // to look up luma/phase/chroma values
           input [3:0] pixel_color3,
           // pixel_color4 is from the scan doubler and should be used to look up
           // RGB color register ram, 4 bit address.
`ifdef NEED_RGB
           input [3:0] pixel_color4,
           input half_bright,
           input active,
           output reg[5:0] red,
           output reg[5:0] green,
           output reg[5:0] blue,
           // Current settings
           output reg last_raster_lines, // for dvi/vga only
           output reg last_is_native_y, // for dvi/vga only
           output reg last_is_native_x, // for dvi/vga only
           output reg last_enable_csync, // for dvi/vga only
           output reg last_hpolarity, // for vga only
           output reg last_vpolarity, // for vga only
`endif

`ifdef GEN_LUMA_CHROMA
           output reg [5:0] lumareg_o,
           output reg [7:0] phasereg_o,
           output reg [3:0] amplitudereg_o,
`ifdef CONFIGURABLE_LUMAS
           output reg [5:0] blanking_level,
           output reg [3:0] burst_amplitude,
`endif
`endif

`ifdef CONFIGURABLE_TIMING
           output reg timing_change,
           output reg [7:0] timing_h_blank_ntsc,
           output reg [7:0] timing_h_fporch_ntsc,
           output reg [7:0] timing_h_sync_ntsc,
           output reg [7:0] timing_h_bporch_ntsc,
           output reg [7:0] timing_v_blank_ntsc,
           output reg [7:0] timing_v_fporch_ntsc,
           output reg [7:0] timing_v_sync_ntsc,
           output reg [7:0] timing_v_bporch_ntsc,
           output reg [7:0] timing_h_blank_pal,
           output reg [7:0] timing_h_fporch_pal,
           output reg [7:0] timing_h_sync_pal,
           output reg [7:0] timing_h_bporch_pal,
           output reg [7:0] timing_v_blank_pal,
           output reg [7:0] timing_v_fporch_pal,
           output reg [7:0] timing_v_sync_pal,
           output reg [7:0] timing_v_bporch_pal,
`endif
           input [ram_width-1:0] video_ram_addr_b,
           output [7:0] video_ram_data_out_b,
`ifdef HIRES_MODES
           output reg [2:0] hires_char_pixel_base,
           output reg [3:0] hires_matrix_base,
           output reg [3:0] hires_color_base,
           output reg hires_enabled,
           output reg hires_allow_bad,
           output reg [1:0] hires_mode,
           output reg [7:0] hires_cursor_hi,
           output reg [7:0] hires_cursor_lo,
`endif
`ifdef WITH_SPI
           output reg    spi_d,
           input         spi_q,
           output reg    spi_c = 1'b1,
`endif
`ifdef HAVE_EEPROM
           output reg    eeprom_s = 1'b1,
`endif
           output reg [1:0] chip
       );

reg chip_initialized = 1'b0;
reg[7:0] magic_1;
reg[7:0] magic_2;
reg[7:0] magic_3;
reg[7:0] magic_4;

// 2D arrays that need to be flattened for output
reg [8:0] sprite_x[0:`NUM_SPRITES - 1];
reg [7:0] sprite_y[0:`NUM_SPRITES - 1];
reg [3:0] sprite_col[0:`NUM_SPRITES - 1];

integer n;

// Handle flattening here
assign sprite_x_o = {sprite_x[0], sprite_x[1], sprite_x[2], sprite_x[3], sprite_x[4], sprite_x[5], sprite_x[6], sprite_x[7]};
assign sprite_y_o = {sprite_y[0], sprite_y[1], sprite_y[2], sprite_y[3], sprite_y[4], sprite_y[5], sprite_y[6], sprite_y[7]};
assign sprite_col_o = {sprite_col[0], sprite_col[1], sprite_col[2], sprite_col[3], sprite_col[4], sprite_col[5], sprite_col[6],sprite_col[7]};

reg res;

// Register Read/Write
reg [5:0] addr_latched;
reg addr_latch_done;
reg read_done;
reg read_done2;

// --- BEGIN EXTENSIONS ----
reg [1:0] extra_regs_activation_ctr;
reg extra_regs_activated;

// Flags to govern read accesses causing auto inc/dec
reg video_ram_r; // also used to trigger auto inc after read
reg video_ram_r2; // also used to trigger auto inc after read
reg video_ram_aw; // auto increment after write is necessary

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
reg color_regs_r; // also used to trigger auto inc after read
reg color_regs_r2; // also used to trigger auto inc after read
reg color_regs_aw; // auto increment after write is necessary
reg [1:0] color_regs_r_nibble;
reg [1:0] color_regs_wr_nibble;
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
reg luma_regs_r; // also used to trigger auto inc after read
reg luma_regs_r2; // also used to trigger auto inc after read
reg luma_regs_aw; // auto increment after write is necessary
reg [1:0] luma_regs_r_nibble;
reg [1:0] luma_regs_wr_nibble;
`endif

`ifdef WITH_MATH
reg [31:0] result32;
reg [15:0] u_op_1;
reg [15:0] u_op_2;
reg signed [15:0] s_op_1;
reg signed [15:0] s_op_2;
wire u_div_done;
wire s_div_done;
wire [15:0] u_quotient;
wire [15:0] u_remain;
wire [15:0] s_quotient;
wire [15:0] s_remain;
reg [7:0] operator;
reg divzero;
`endif

reg auto_ram_sel; // which pointer are we auto incrementing?

reg [1:0] video_ram_flag_port_1_auto;
reg [1:0] video_ram_flag_port_2_auto;
// bit 4 is tx busy flag
reg video_ram_flag_regs_overlay;
reg video_ram_flag_persist;

// Port A used for CPU access
reg [ram_width-1:0] video_ram_addr_a;
reg video_ram_wr_a;
reg [7:0] video_ram_hi_1;
reg [7:0] video_ram_lo_1;
reg [7:0] video_ram_idx_1;
reg [7:0] video_ram_hi_2;
reg [7:0] video_ram_lo_2;
reg [7:0] video_ram_idx_2;
reg [7:0] video_ram_data_in_a;
wire [7:0] video_ram_data_out_a;

reg [15:0] video_ram_copy_src;
reg [15:0] video_ram_copy_dst;
reg [15:0] video_ram_copy_num;
reg video_ram_copy_dir;
// 0= write off, set read addr
// 1= read data, set write addr, write on
reg [1:0] video_ram_copy_state;
reg video_ram_copy_done;

reg [15:0] video_ram_fill_dst;
reg [15:0] video_ram_fill_num;
reg [7:0] video_ram_fill_val;
reg video_ram_fill_done;

// Regarding pre_wr registers below. We need an additional cycle to
// read existing values before writing. Otherwise, the data_out_a
// register will have garbage. This goes for both color and luma
// registers where we pack components inside a wider register.

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
// For CPU/MCU register read/write to color regs
reg [3:0] color_regs_addr_a; // 16 regs
reg color_regs_wr_a;
reg color_regs_pre_wr_a;
reg color_regs_pre_wr2_a;
reg [5:0] color_regs_wr_value;
reg [23:0] color_regs_data_in_a;
wire [23:0] color_regs_data_out_a;
wire [23:0] color_regs_data_out_b;
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
// For CPU/MCU register read/write to luma regs
reg [3:0] luma_regs_addr_a;
reg luma_regs_wr_a;
reg luma_regs_pre_wr_a;
reg luma_regs_pre_wr2_a;
reg [7:0] luma_regs_wr_value;
reg [17:0] luma_regs_data_in_a;
wire [17:0] luma_regs_data_out_a;
wire [17:0] luma_regs_data_out_b;
`endif

// Auto increment/decrement of extra reg addr should happen on reads/writes
// to the extra reg data port.  Some CPU instructions result in a single
// read or write.  However, some CPU instructions address the
// memory location over 2 cycles, once for a read and then again for a write.
// We defer read inc/dec until the following cycle in case it is immediately
// followed by a write. This ensures increment happens after the CPU
// instruction is complete.
VIDEO_RAM video_ram(clk_dot4x,
                    video_ram_wr_a, // CPU can read/write
                    video_ram_addr_a,
                    video_ram_data_in_a,
                    video_ram_data_out_a,
                    1'b0,          // Video can only read
                    video_ram_addr_b,
                    8'b0,          // Video can only read
                    video_ram_data_out_b
                   );

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
COLOR_REGS color_regs(clk_dot4x,
                      color_regs_wr_a, // write to color ram
                      color_regs_addr_a, // addr for color ram read/write
                      color_regs_data_in_a,
                      color_regs_data_out_a,
                      1'b0, // we never write to port b
                      pixel_color4, // read addr for color lookups
                      24'b0, // we never write to port b
                      color_regs_data_out_b // read value for color lookups
                     );
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
LUMA_REGS luma_regs(clk_dot4x,
                    luma_regs_wr_a, // write to luma ram
                    luma_regs_addr_a, // addr for luma ram read/write
                    luma_regs_data_in_a,
                    luma_regs_data_out_a,
                    1'b0, // we never write to port b
                    pixel_color3, // read addr for luma lookups
                    18'b0, // we never write to port b
                    luma_regs_data_out_b // read value for luma lookups
                   );
`endif

// --- END EXTENSIONS ----

`ifdef HAVE_EEPROM
`include "registers_eeprom.vh"
`else
`include "registers_no_eeprom.vh"
`endif

`ifdef HAVE_FLASH
`include "registers_flash.vh"
`endif

`ifdef WITH_MATH

divide u_divider(.clk(clk_dot4x),
                 .sign(1'b0),
                 .done(u_div_done),
                 .dividend(u_op_1),
                 .divider(u_op_2),
                 .quotient(u_quotient),
                 .remainder(u_remain));

divide s_divider(.clk(clk_dot4x),
                 .sign(1'b1),
                 .done(s_div_done),
                 .dividend(s_op_1),
                 .divider(s_op_2),
                 .quotient(s_quotient),
                 .remainder(s_remain));

always @(posedge clk_dot4x)
begin
    case (operator)
       `U_MULT: begin
           result32 = {16'b0, u_op_1} * {16'b0, u_op_2};
           divzero = 0;
       end
       `U_DIV: begin
           if (u_op_2 == 0)
              divzero = 1;
           else if (u_div_done) begin
              result32[15:0] = u_quotient;
              result32[31:16] = u_remain;
              divzero = 0;
           end
       end
       `S_MULT: begin
           result32 = {s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15], s_op_1[15:0]} * 
                      {s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15], s_op_2[15:0]};
           divzero = 0;
       end
       `S_DIV: begin
           if (s_op_2 == 0)
              divzero = 1;
           else if (u_div_done) begin
              result32[15:0] = s_quotient;
              result32[31:16] = s_remain;
              divzero = 0;
           end
       end
       default: ;
   endcase
end
`endif

// Master process block for registers
always @(posedge clk_dot4x)
    if (rst) begin

        handle_persist(1'b1);

`ifdef TEST_PATTERN
        ec <= `LIGHT_BLUE;
        b0c <= `BLUE;
        den <= `TRUE;
`endif
`ifdef HAVE_FLASH
        flash_busy <= 1'b0;
`endif
        //ec <= `BLACK;
        //b0c <= `BLACK;
        //den <= `FALSE;
        //b1c <= BLACK;
        //b2c <= BLACK;
        //b3c <= BLACK;
        //xscroll <= 3'd0;
        //yscroll <= 3'd3;
        //csel <= `FALSE;
        //rsel <= `FALSE;
        //bmm <= `FALSE;
        //ecm <= `FALSE;
        //res <= `FALSE;
        //mcm <= `FALSE;
        //irst_clr <= `FALSE;
        //imbc_clr <= `FALSE;
        //immc_clr <= `FALSE;
        //ilp_clr <= `FALSE;
        //raster_irq_compare <= 9'b0;
        //sprite_en <= 8'b0;
        //sprite_xe <= 8'b0;
        //sprite_ye <= 8'b0;
        //sprite_pri <= 8'b0;
        //sprite_mmc <= 8'b0;
        //sprite_mc0 <= BLACK;
        //sprite_mc1 <= BLACK;
        //for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
        //    sprite_x[n] <= 9'b0;
        //    sprite_y[n] <= 8'b0;
        //    sprite_col[n] <= BLACK;
        // end
        //m2m_clr <= `FALSE;
        //m2d_clr <= `FALSE;
        //erst <= `FALSE;
        //embc <= `FALSE;
        //emmc <= `FALSE;
        //elp <= `FALSE;
        //dbo[7:0] <= 8'd0;
        //handle_sprite_crunch <= `FALSE;

`ifdef CONFIGURABLE_LUMAS
        blanking_level <= 6'd12;
        burst_amplitude <= 4'd12;
`endif
`ifdef CONFIGURABLE_TIMING
        timing_change <= 1'b0;
        timing_h_blank_ntsc <= 0;
        timing_h_fporch_ntsc <= 10;
        timing_h_sync_ntsc <= 60;
        timing_h_bporch_ntsc <= 10;
        timing_v_blank_ntsc <= 11;
        timing_v_fporch_ntsc <= 8;
        timing_v_sync_ntsc <= 3;
        timing_v_bporch_ntsc <= 2;
        timing_h_blank_pal <= 0;
        timing_h_fporch_pal <= 10;
        timing_h_sync_pal <= 60;
        timing_h_bporch_pal <= 20;
        timing_v_blank_pal <= 28; // represents 284 (284-256)
        timing_v_fporch_pal <= 5;
        timing_v_sync_pal <= 2;
        timing_v_bporch_pal <= 40; // NOTE: crosses 0, we sub 311 and invert sta/end
`endif
        // --- BEGIN EXTENSIONS ----
        extra_regs_activation_ctr <= 2'b0;

        // Latch these config registers during reset
`ifdef NEED_RGB
        last_raster_lines <= 1'b0;
        last_is_native_y <= 1'b0;
        last_is_native_x <= 1'b0;
        last_enable_csync <= 1'b0;
        last_hpolarity <= 1'b0;
        last_vpolarity <= 1'b0;
`endif
        video_ram_flag_port_1_auto <= 2'b0;
        video_ram_flag_port_2_auto <= 2'b0;
        video_ram_flag_regs_overlay <= 1'b0;
        video_ram_flag_persist <= 1'b0;
`ifdef SIMULATOR_BOARD
        extra_regs_activated <= 0'b1;
`ifdef HIRES_MODES
	`ifdef HIRES_TEXT
        // Test mode 0 : Text
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 2'b00;
        // char pixels @0000(4K)
        hires_char_pixel_base <= 3'b0;
        // color table @1000(2K)
        hires_color_base <= 4'b10;
        // matrix @1800(2K)
        hires_matrix_base <= 4'b11;
        // Cursor top left
        hires_cursor_hi <= 8'h18;
        hires_cursor_lo <= 8'b00;
	`endif
	`ifdef HIRES_BITMAP1
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 2'b01;
        hires_char_pixel_base <= 3'b0; // ignored
        // pixels @0000(16k)
        hires_matrix_base <= 4'b0000;
        // color table @8000(2K)
        hires_color_base <= 4'b1000;
	`endif
	`ifdef HIRES_BITMAP2
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 2'b10;
        hires_char_pixel_base <= 3'b0; // ignored
        hires_matrix_base <= 4'b0000; // 32k bank
        hires_color_base <= 4'b0000; // ignored
	`endif
	`ifdef HIRES_BITMAP3
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 2'b11;
        hires_char_pixel_base <= 3'b0; // ignored
        hires_matrix_base <= 4'b0000; // 32k bank
        hires_color_base <= 4'b0000; // 4 color bank
	`endif
`endif // HIRES_MODES

/*
`ifdef HAVE_FLASH
       //FOR TESTING FLASH WRITE IN SIM
       if (spi_lock) begin
         flash_begin <= `FLASH_WRITE;
         // Grab the write address from 0x35,0x36,0x3a
         flash_vmem_addr <= 0;
         flash_addr <= 24'h7d000;
         flash_command_ctr <= `FLASH_CMD_WREN;
         flash_bit_ctr <= 6'd0;
         flash_busy <= 1'b1;
         flash_verify_error <= 1'b0;
         flash_page_ctr = 6'b0;
       end
`endif
*/
/*
`ifdef HAVE_FLASH
       //FOR TESTING FLASH READ IN SIM
       if (spi_lock) begin
         flash_begin <= `FLASH_READ;
         // Grab the write address from 0x35,0x36,0x3a
         flash_vmem_addr <= 0;
         flash_addr <= 24'h7d000;
         flash_command_ctr <= `FLASH_CMD_READ;
         flash_bit_ctr <= 6'd0;
         flash_busy <= 1'b1;
         flash_verify_error <= 1'b0;
         flash_page_ctr = 6'b0;
       end
`endif
*/

`else
        extra_regs_activated <= 1'b0;
`ifdef HIRES_MODES
        hires_mode <= 2'b00;
        hires_enabled <= 1'b0;
        hires_allow_bad <= 1'b0;
        hires_char_pixel_base <= 3'b0;
        hires_matrix_base <= 4'b0000; // ignored
        hires_color_base <= 4'b0000; // ignored
        hires_cursor_hi <= 8'b0;
        hires_cursor_lo <= 8'b0;
`endif


`endif // SIMULATOR_BOARD

        if (~chip_initialized) begin
            chip <= {1'b0, ~standard_sw};
`ifdef HAVE_EEPROM
            // EEPROM bank always starts off same as chip
            eeprom_bank <= {1'b0, ~standard_sw};
`endif
            chip_initialized <= 1'b1;
        end

    end else
    begin

        handle_persist(1'b0);

`ifdef HAVE_FLASH
        handle_flash();
`endif

`ifdef HIRES_MODES
`ifdef HIRES_RESET

`ifdef HAVE_EEPROM
        if (!cpu_reset_i && extra_regs_activated && !eeprom_busy) begin
`else
        if (!cpu_reset_i && extra_regs_activated) begin
`endif
           hires_mode <= 2'b00;
           hires_enabled <= 1'b0;
           hires_allow_bad <= 1'b0;
           hires_char_pixel_base <= 3'b0;
           hires_matrix_base <= 4'b0000;
           hires_color_base <= 4'b0000;
           hires_cursor_hi <= 8'b0;
           hires_cursor_lo <= 8'b0;
`ifdef HAVE_EEPROM
           state_ctr_reset_for_read <= 1;
`endif
        end
`endif
`endif

`ifdef HAVE_EEPROM
     if (!cfg_reset && !eeprom_busy) begin
        eeprom_busy <= 1'b1;
        eeprom_w_addr <= { 2'b0, `EXT_REG_MAGIC_0 };
        eeprom_w_value <= 8'h00;
        state_ctr_reset_for_write <= 1'b1;
     end
`endif

        if (phi_phase_start_dav_plus_1) begin
            if (!clk_phi) begin
                // always clear these immediately after they may
                // have been used. This should be DAV + 1
                irst_clr <= `FALSE;
                imbc_clr <= `FALSE;
                immc_clr <= `FALSE;
                ilp_clr <= `FALSE;
                m2m_clr <= `FALSE;
                m2d_clr <= `FALSE;
            end

            addr_latch_done <= `FALSE;
            read_done <= `FALSE;
            read_done2 <= `FALSE;
            last_bus <= 8'hff;
            // clear sprite crunch immediately after it may
            // have been used
            handle_sprite_crunch <= `FALSE;
        end
        if (!ras && clk_phi && !addr_latch_done) begin
            addr_latched <= adi[5:0];
            addr_latch_done <= `TRUE;
        end
        if (aec && !ce && addr_latch_done) begin
            // READ from register
            // For registers that clear collisions, we do it on [dav].
            // Otherwise, we'd do it way too early if we did it at the
            // same time we assert dbo in the block below.  VICE sync
            // complains it is too early.
            if (rw && phi_phase_start_dav) begin
                case (addr_latched[5:0])
                    /* 0x1e */ `REG_SPRITE_2_SPRITE_COLLISION: begin
                        // reading this register clears the value
                        m2m_clr <= 1;
                    end
                    /* 0x1f */ `REG_SPRITE_2_DATA_COLLISION: begin
                        // reading this register clears the value
                        m2d_clr <= 1;
                    end
                    default: ;
                endcase
            end

            if (read_done && !read_done2) begin
               last_bus <= dbo;
               read_done2 <= `TRUE;
            end

            if (rw && !read_done) begin
                read_done <= `TRUE;
                case (addr_latched[5:0])
                    /* 0x00 */ `REG_SPRITE_X_0:
                        dbo[7:0] <= sprite_x[0][7:0];
                    /* 0x02 */ `REG_SPRITE_X_1:
                        dbo[7:0] <= sprite_x[1][7:0];
                    /* 0x04 */ `REG_SPRITE_X_2:
                        dbo[7:0] <= sprite_x[2][7:0];
                    /* 0x06 */ `REG_SPRITE_X_3:
                        dbo[7:0] <= sprite_x[3][7:0];
                    /* 0x08 */ `REG_SPRITE_X_4:
                        dbo[7:0] <= sprite_x[4][7:0];
                    /* 0x0a */ `REG_SPRITE_X_5:
                        dbo[7:0] <= sprite_x[5][7:0];
                    /* 0x0c */ `REG_SPRITE_X_6:
                        dbo[7:0] <= sprite_x[6][7:0];
                    /* 0x0e */ `REG_SPRITE_X_7:
                        dbo[7:0] <= sprite_x[7][7:0];
                    /* 0x01 */ `REG_SPRITE_Y_0:
                        dbo[7:0] <= sprite_y[0];
                    /* 0x03 */ `REG_SPRITE_Y_1:
                        dbo[7:0] <= sprite_y[1];
                    /* 0x05 */ `REG_SPRITE_Y_2:
                        dbo[7:0] <= sprite_y[2];
                    /* 0x07 */ `REG_SPRITE_Y_3:
                        dbo[7:0] <= sprite_y[3];
                    /* 0x09 */ `REG_SPRITE_Y_4:
                        dbo[7:0] <= sprite_y[4];
                    /* 0x0b */ `REG_SPRITE_Y_5:
                        dbo[7:0] <= sprite_y[5];
                    /* 0x0d */ `REG_SPRITE_Y_6:
                        dbo[7:0] <= sprite_y[6];
                    /* 0x0f */ `REG_SPRITE_Y_7:
                        dbo[7:0] <= sprite_y[7];
                    /* 0x10 */ `REG_SPRITE_X_BIT_8:
                        dbo[7:0] <= {sprite_x[7][8],
                                     sprite_x[6][8],
                                     sprite_x[5][8],
                                     sprite_x[4][8],
                                     sprite_x[3][8],
                                     sprite_x[2][8],
                                     sprite_x[1][8],
                                     sprite_x[0][8]};
                    /* 0x11 */ `REG_SCREEN_CONTROL_1: begin
                        dbo[2:0] <= yscroll;
                        dbo[3] <= rsel;
                        dbo[4] <= den;
                        dbo[5] <= bmm;
                        dbo[6] <= ecm;
                        dbo[7] <= raster_line[8];
                    end
                    /* 0x12 */ `REG_RASTER_LINE: dbo[7:0] <= raster_line[7:0];
                    /* 0x13 */ `REG_LIGHT_PEN_X: dbo[7:0] <= lpx;
                    /* 0x14 */ `REG_LIGHT_PEN_Y: dbo[7:0] <= lpy;
                    /* 0x15 */ `REG_SPRITE_ENABLE: dbo[7:0] <= sprite_en;
                    /* 0x16 */ `REG_SCREEN_CONTROL_2:
                        dbo[7:0] <= {2'b11, res, mcm, csel, xscroll};
                    /* 0x17 */ `REG_SPRITE_EXPAND_Y:
                        dbo[7:0] <= sprite_ye;
                    /* 0x18 */ `REG_MEMORY_SETUP: begin
                        dbo[0] <= 1'b1;
                        dbo[3:1] <= cb[2:0];
                        dbo[7:4] <= vm[3:0];
                    end
                    // NOTE: Our irq is inverted already
                    /* 0x19 */ `REG_INTERRUPT_STATUS:
                        dbo[7:0] <= {irq, 3'b111, ilp, immc, imbc, irst};
                    /* 0x1a */ `REG_INTERRUPT_CONTROL:
                        dbo[7:0] <= {4'b1111, elp, emmc, embc, erst};
                    /* 0x1b */ `REG_SPRITE_PRIORITY:
                        dbo[7:0] <= sprite_pri;
                    /* 0x1c */ `REG_SPRITE_MULTICOLOR_MODE:
                        dbo[7:0] <= sprite_mmc;
                    /* 0x1d */ `REG_SPRITE_EXPAND_X:
                        dbo[7:0] <= sprite_xe;
                    /* 0x1e */ `REG_SPRITE_2_SPRITE_COLLISION:
                        dbo[7:0] <= sprite_m2m;
                    /* 0x1f */ `REG_SPRITE_2_DATA_COLLISION:
                        dbo[7:0] <= sprite_m2d;
                    /* 0x20 */ `REG_BORDER_COLOR:
                        dbo[7:0] <= {4'b1111, ec};
                    /* 0x21 */ `REG_BACKGROUND_COLOR_0:
                        dbo[7:0] <= {4'b1111, b0c};
                    /* 0x22 */ `REG_BACKGROUND_COLOR_1:
                        dbo[7:0] <= {4'b1111, b1c};
                    /* 0x23 */ `REG_BACKGROUND_COLOR_2:
                        dbo[7:0] <= {4'b1111, b2c};
                    /* 0x24 */ `REG_BACKGROUND_COLOR_3:
                        dbo[7:0] <= {4'b1111, b3c};
                    /* 0x25 */ `REG_SPRITE_MULTI_COLOR_0:
                        dbo[7:0] <= {4'b1111, sprite_mc0};
                    /* 0x26 */ `REG_SPRITE_MULTI_COLOR_1:
                        dbo[7:0] <= {4'b1111, sprite_mc1};
                    /* 0x27 */ `REG_SPRITE_COLOR_0:
                        dbo[7:0] <= {4'b1111, sprite_col[0]};
                    /* 0x28 */ `REG_SPRITE_COLOR_1:
                        dbo[7:0] <= {4'b1111, sprite_col[1]};
                    /* 0x29 */ `REG_SPRITE_COLOR_2:
                        dbo[7:0] <= {4'b1111, sprite_col[2]};
                    /* 0x2a */ `REG_SPRITE_COLOR_3:
                        dbo[7:0] <= {4'b1111, sprite_col[3]};
                    /* 0x2b */ `REG_SPRITE_COLOR_4:
                        dbo[7:0] <= {4'b1111, sprite_col[4]};
                    /* 0x2c */ `REG_SPRITE_COLOR_5:
                        dbo[7:0] <= {4'b1111, sprite_col[5]};
                    /* 0x2d */ `REG_SPRITE_COLOR_6:
                        dbo[7:0] <= {4'b1111, sprite_col[6]};
                    /* 0x2e */ `REG_SPRITE_COLOR_7:
                        dbo[7:0] <= {4'b1111, sprite_col[7]};

                    // --- BEGIN EXTENSIONS ----
`ifdef WITH_MATH
                    /* 0x2f */ 6'h2f: begin
                        if (extra_regs_activated) begin
                          dbo[7:0] <= result32[31:24];
                        end
                    end
                    /* 0x30 */ 6'h30: begin
                        if (extra_regs_activated) begin
                          dbo[7:0] <= result32[23:16];
                        end
                    end
                    /* 0x31 */ 6'h31: begin
                        if (extra_regs_activated) begin
                          dbo[7:0] <= result32[15:8];
                        end
                    end
                    /* 0x32 */ 6'h32: begin
                        if (extra_regs_activated) begin
                          dbo[7:0] <= result32[7:0];
                        end
                    end
                    /* 0x33 */ 6'h33: begin
                        if (extra_regs_activated)
                           dbo[1] <= divzero;
                    end
`endif
                    `SPI_REG:
                        if (extra_regs_activated)
                           dbo[7:0] <= {
                                  2'b0,
                                  persistence_lock,
                                  extensions_lock,
                                  spi_lock,
`ifdef HAVE_FLASH
                                  flash_verify_error,
                                  flash_busy,
`else
                                  1'b0,
                                  1'b0,
`endif
`ifdef WITH_SPI
                                  spi_q
`else
                                  1'b0
`endif
                           };
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_IDX:
                        if (extra_regs_activated)
                            dbo[7:0] <= video_ram_idx_1;
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_IDX:
                        if (extra_regs_activated)
                            dbo[7:0] <= video_ram_idx_2;
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MODE1:
                        if (extra_regs_activated)
`ifdef HIRES_MODES
                            dbo[7:0] <= { 1'b0,
                                          hires_mode,
                                          hires_enabled,
                                          hires_allow_bad, 
                                          hires_char_pixel_base };
`else
                            dbo[7:0] <= { 1'b0,
                                          2'b0,
                                          1'b0,
                                          1'b0,
                                          3'b0 };
`endif
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MODE2:
                        if (extra_regs_activated)
`ifdef HIRES_MODES
                            dbo[7:0] <= { hires_color_base, hires_matrix_base };
`else
                            dbo[7:0] <= { 4'b0, 4'b0 };
`endif
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_HI:
                        if (extra_regs_activated)
                            dbo[7:0] <= video_ram_hi_1;
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_LO:
                        if (extra_regs_activated)
                            dbo[7:0] <= video_ram_lo_1;
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_VAL:
                        if (extra_regs_activated) begin
                            // reg overlay or video mem
                            auto_ram_sel <= 0;
                            read_ram(
                                .overlay(video_ram_flag_regs_overlay),
                                .ram_lo(video_ram_lo_1),
                                .ram_hi(video_ram_hi_1),
                                .ram_idx(video_ram_idx_1));
                        end else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_HI:
                        if (extra_regs_activated)
                            dbo[7:0] <= video_ram_hi_2;
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_LO:
                        if (extra_regs_activated)
                            dbo[7:0] <= video_ram_lo_2;
                        else
                            dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_VAL:
                        if (extra_regs_activated) begin
                            // reg overlay or video mem
                            auto_ram_sel <= 1;
                            read_ram(
                                .overlay(video_ram_flag_regs_overlay),
                                .ram_lo(video_ram_lo_2),
                                .ram_hi(video_ram_hi_2),
                                .ram_idx(video_ram_idx_2));
                        end else
                            dbo[7:0] <= 8'hFF;
                    /* 0x3F */ `VIDEO_MEM_FLAGS:
                        if (extra_regs_activated)
                            dbo[7:0] <= { 1'b0,
                                          video_ram_flag_persist,
                                          video_ram_flag_regs_overlay,
`ifdef HAVE_EEPROM
                                          eeprom_busy, // eeprom busy
`else
                                          1'b0,
`endif
                                          video_ram_flag_port_2_auto,
                                          video_ram_flag_port_1_auto
                                        };
                        else
                            dbo[7:0] <= 8'hFF;

                    // --- END EXTENSIONS ----

                    default:
                        dbo[7:0] <= 8'hFF;
                endcase
            end
            // WRITE to register
            else if (!rw && phi_phase_start_dav) begin
                last_bus <= dbi;
                case (addr_latched[5:0])
                    /* 0x00 */ `REG_SPRITE_X_0:
                        sprite_x[0][7:0] <= dbi[7:0];
                    /* 0x02 */ `REG_SPRITE_X_1:
                        sprite_x[1][7:0] <= dbi[7:0];
                    /* 0x04 */ `REG_SPRITE_X_2:
                        sprite_x[2][7:0] <= dbi[7:0];
                    /* 0x06 */ `REG_SPRITE_X_3:
                        sprite_x[3][7:0] <= dbi[7:0];
                    /* 0x08 */ `REG_SPRITE_X_4:
                        sprite_x[4][7:0] <= dbi[7:0];
                    /* 0x0a */ `REG_SPRITE_X_5:
                        sprite_x[5][7:0] <= dbi[7:0];
                    /* 0x0c */ `REG_SPRITE_X_6:
                        sprite_x[6][7:0] <= dbi[7:0];
                    /* 0x0e */ `REG_SPRITE_X_7:
                        sprite_x[7][7:0] <= dbi[7:0];
                    /* 0x01 */ `REG_SPRITE_Y_0:
                        sprite_y[0] <= dbi[7:0];
                    /* 0x03 */ `REG_SPRITE_Y_1:
                        sprite_y[1] <= dbi[7:0];
                    /* 0x05 */ `REG_SPRITE_Y_2:
                        sprite_y[2] <= dbi[7:0];
                    /* 0x07 */ `REG_SPRITE_Y_3:
                        sprite_y[3] <= dbi[7:0];
                    /* 0x09 */ `REG_SPRITE_Y_4:
                        sprite_y[4] <= dbi[7:0];
                    /* 0x0b */ `REG_SPRITE_Y_5:
                        sprite_y[5] <= dbi[7:0];
                    /* 0x0d */ `REG_SPRITE_Y_6:
                        sprite_y[6] <= dbi[7:0];
                    /* 0x0f */ `REG_SPRITE_Y_7:
                        sprite_y[7] <= dbi[7:0];
                    /* 0x10 */ `REG_SPRITE_X_BIT_8: begin
                        sprite_x[7][8] <= dbi[7];
                        sprite_x[6][8] <= dbi[6];
                        sprite_x[5][8] <= dbi[5];
                        sprite_x[4][8] <= dbi[4];
                        sprite_x[3][8] <= dbi[3];
                        sprite_x[2][8] <= dbi[2];
                        sprite_x[1][8] <= dbi[1];
                        sprite_x[0][8] <= dbi[0];
                    end
                    /* 0x11 */ `REG_SCREEN_CONTROL_1: begin
                        yscroll <= dbi[2:0];
                        rsel <= dbi[3];
`ifdef TEST_PATTERN
                        den <= `TRUE;
`else
                        den <= dbi[4];
`endif
                        bmm <= dbi[5];
                        ecm <= dbi[6];
                        raster_irq_compare[8] <= dbi[7];
                    end
                    /* 0x12 */ `REG_RASTER_LINE: raster_irq_compare[7:0] <= dbi[7:0];
                    /* 0x15 */ `REG_SPRITE_ENABLE: sprite_en <= dbi[7:0];
                    /* 0x16 */ `REG_SCREEN_CONTROL_2: begin
                        xscroll <= dbi[2:0];
                        csel <= dbi[3];
                        mcm <= dbi[4];
                        res <= dbi[5];
                    end
                    /* 0x17 */ `REG_SPRITE_EXPAND_Y: begin
                        // must be handled before end of phase (before reset)
                        handle_sprite_crunch <= `TRUE;
                        sprite_ye <= dbi[7:0];
                    end
                    /* 0x18 */ `REG_MEMORY_SETUP: begin
                        cb[2:0] <= dbi[3:1];
                        vm[3:0] <= dbi[7:4];
                    end
                    /* 0x19 */ `REG_INTERRUPT_STATUS: begin
                        irst_clr <= dbi[0];
                        imbc_clr <= dbi[1];
                        immc_clr <= dbi[2];
                        ilp_clr <= dbi[3];
                    end
                    /* 0x1a */ `REG_INTERRUPT_CONTROL: begin
                        erst <= dbi[0];
                        embc <= dbi[1];
                        emmc <= dbi[2];
                        elp <= dbi[3];
                    end
                    /* 0x1b */ `REG_SPRITE_PRIORITY:
                        sprite_pri <= dbi[7:0];
                    /* 0x1c */ `REG_SPRITE_MULTICOLOR_MODE:
                        sprite_mmc <= dbi[7:0];
                    /* 0x1d */ `REG_SPRITE_EXPAND_X:
                        sprite_xe <= dbi[7:0];
`ifndef TEST_PATTERN
                    /* 0x20 */ `REG_BORDER_COLOR:
                        ec <= dbi[3:0];
                    /* 0x21 */ `REG_BACKGROUND_COLOR_0:
                        b0c <= dbi[3:0];
`endif
                    /* 0x22 */ `REG_BACKGROUND_COLOR_1:
                        b1c <= dbi[3:0];
                    /* 0x23 */ `REG_BACKGROUND_COLOR_2:
                        b2c <= dbi[3:0];
                    /* 0x24 */ `REG_BACKGROUND_COLOR_3:
                        b3c <= dbi[3:0];
                    /* 0x25 */ `REG_SPRITE_MULTI_COLOR_0:
                        sprite_mc0 <= dbi[3:0];
                    /* 0x26 */ `REG_SPRITE_MULTI_COLOR_1:
                        sprite_mc1 <= dbi[3:0];
                    /* 0x27 */ `REG_SPRITE_COLOR_0:
                        sprite_col[0] <= dbi[3:0];
                    /* 0x28 */ `REG_SPRITE_COLOR_1:
                        sprite_col[1] <= dbi[3:0];
                    /* 0x29 */ `REG_SPRITE_COLOR_2:
                        sprite_col[2] <= dbi[3:0];
                    /* 0x2a */ `REG_SPRITE_COLOR_3:
                        sprite_col[3] <= dbi[3:0];
                    /* 0x2b */ `REG_SPRITE_COLOR_4:
                        sprite_col[4] <= dbi[3:0];
                    /* 0x2c */ `REG_SPRITE_COLOR_5:
                        sprite_col[5] <= dbi[3:0];
                    /* 0x2d */ `REG_SPRITE_COLOR_6:
                        sprite_col[6] <= dbi[3:0];
                    /* 0x2e */ `REG_SPRITE_COLOR_7:
                        sprite_col[7] <= dbi[3:0];

                    // --- BEGIN EXTENSIONS ----
`ifdef WITH_MATH
                    /* 0x2f */ 6'h2f: begin
                        u_op_1[15:8] <= dbi[7:0];
                        s_op_1[15:8] <= dbi[7:0];
                    end
                    /* 0x30 */ 6'h30: begin
                        u_op_1[7:0] <= dbi[7:0];
                        s_op_1[7:0] <= dbi[7:0];
                    end
                    /* 0x31 */ 6'h31: begin
                        u_op_2[15:8] <= dbi[7:0];
                        s_op_2[15:8] <= dbi[7:0];
                    end
                    /* 0x32 */ 6'h32: begin
                        u_op_2[7:0] <= dbi[7:0];
                        s_op_2[7:0] <= dbi[7:0];
                    end
                    /* 0x33 */ 6'h33: begin
                        operator <= dbi[7:0];
                    end
`endif

                    /* 0x34 */ `SPI_REG:
                        if (extra_regs_activated)
                        begin
                            if (dbi[7]) begin
`ifdef HAVE_FLASH
                              // spi_lock must be OPEN for SPI access
                              if (!flash_busy && spi_lock) begin
                                // This is a bulk flash command. Last two
                                // bits of dbi represent the operation.
                                // FLASH_WRITE 01
                                // FLASH_READ  10
                                flash_begin <= dbi[1:0];
                                // Greb vmem address
                                flash_vmem_addr <= {video_ram_hi_2[ram_hi_width-1:0], video_ram_lo_2};
                                // Grab the flash write address
                                flash_addr <=
                                    {video_ram_idx_1,
                                     video_ram_hi_1,
                                     video_ram_lo_1};
                                if (dbi[1:0] == `FLASH_WRITE)
                                   flash_command_ctr <= `FLASH_CMD_WREN;
                                else
                                   flash_command_ctr <= `FLASH_CMD_READ;
                                flash_bit_ctr <= 6'd0;
                                flash_busy <= 1'b1;
                                flash_verify_error <= 1'b0;
                                flash_page_ctr = 6'b0;
                                $display("start flash");
                              end
`endif
                            end else begin
                               // Directly set SPI lines
                               // spi_lock must be OPEN for SPI access
                               if (spi_lock) begin
`ifdef HAVE_FLASH
                                  flash_s <= dbi[0];
`endif
`ifdef WITH_SPI
                                  spi_c <= dbi[1];
                                  spi_d <= dbi[2];
`endif
`ifdef HAVE_EEPROM
                                  eeprom_s <= dbi[3];
`endif
                               end
                            end
                        end
                    `VIDEO_MEM_1_IDX:
                        if (extra_regs_activated)
                            video_ram_idx_1 <= dbi;
                    `VIDEO_MEM_2_IDX:
                        if (extra_regs_activated)
                            video_ram_idx_2 <= dbi;
                    `VIDEO_MODE1:
                        if (extra_regs_activated) begin
`ifdef HIRES_MODES
                            hires_mode <= dbi[6:5];
                            hires_enabled <= dbi[`HIRES_ENABLE];
                            hires_allow_bad <= dbi[`HIRES_ALLOW_BAD];
                            hires_char_pixel_base <= dbi[2:0];
`endif
                        end
                    `VIDEO_MODE2:
                        if (extra_regs_activated) begin
`ifdef HIRES_MODES
                            hires_matrix_base <= dbi[3:0];
                            hires_color_base <= dbi[7:4];
`endif
                        end
                    /* 0x3f */ `VIDEO_MEM_FLAGS:
                        if (~extra_regs_activated) begin
                            case (dbi[7:0])
                                /* "V" */ 8'd86:
                                    if (extra_regs_activation_ctr == 2'd0)
                                        extra_regs_activation_ctr <= extra_regs_activation_ctr + 2'b1;
                                /* "I" */ 8'd73:
                                    if (extra_regs_activation_ctr == 2'd1)
                                        extra_regs_activation_ctr <= extra_regs_activation_ctr + 2'b1;
                                    else
                                        extra_regs_activation_ctr <= 2'd0;
                                /* "C" */ 8'd67:
                                    if (extra_regs_activation_ctr == 2'd2)
                                        extra_regs_activation_ctr <= extra_regs_activation_ctr + 2'b1;
                                    else
                                        extra_regs_activation_ctr <= 2'd0;
                                /* "2" */ 8'd50:
                                    // extensions_lock must CLOSED
                                    if (extra_regs_activation_ctr == 2'd3
                                            && ~extensions_lock)
                                        extra_regs_activated <= 1'b1;
                                    else
                                        extra_regs_activation_ctr <= 2'd0;
                                default:
                                    extra_regs_activation_ctr <= 2'd0;
                            endcase
                        end else begin
                            video_ram_flag_port_1_auto <= dbi[`VMEM_FLAG_PORT1_FUNCTION];
                            video_ram_flag_port_2_auto <= dbi[`VMEM_FLAG_PORT2_FUNCTION];
                            video_ram_flag_regs_overlay <= dbi[`VMEM_FLAG_REGS_OVERLAY_BIT];
                            video_ram_flag_persist <= dbi[`VMEM_FLAG_PERSIST_BIT];
                            if (dbi[`VMEM_FLAG_DISABLE_BIT])
                                extra_regs_activated <= 1'b0;
                        end
                    `VIDEO_MEM_1_HI:
                        if (extra_regs_activated)
                            video_ram_hi_1 <= dbi[7:0];
                    `VIDEO_MEM_1_LO:
                        if (extra_regs_activated)
                            video_ram_lo_1 <= dbi[7:0];
                    `VIDEO_MEM_1_VAL:
                        if (extra_regs_activated) begin
                            if (!video_ram_flag_regs_overlay &&
                                    video_ram_flag_port_1_auto == 2'b11 &&
                                    video_ram_flag_port_2_auto == 2'b11)
                            begin
                                // block copy or fill operation
                                if (dbi[0]) begin
                                    // copy low to high
                                    video_ram_copy_dst <= { video_ram_hi_1, video_ram_lo_1 };
                                    video_ram_copy_src <= { video_ram_hi_2, video_ram_lo_2 };
                                    video_ram_copy_num <= { video_ram_idx_2, video_ram_idx_1 };
                                    video_ram_copy_state <= 2'b0;
                                    video_ram_copy_dir <= 1'b0;
                                    video_ram_copy_done <= 1'b0;
                                end else if (dbi[1]) begin
                                    // copy high to low
                                    video_ram_copy_dst <= { video_ram_hi_1, video_ram_lo_1 } + { video_ram_idx_2, video_ram_idx_1 } - 1'b1;
                                    video_ram_copy_src <= { video_ram_hi_2, video_ram_lo_2 } + { video_ram_idx_2, video_ram_idx_1 } - 1'b1;
                                    video_ram_copy_num <= { video_ram_idx_2, video_ram_idx_1 };
                                    video_ram_copy_state <= 2'b0;
                                    video_ram_copy_dir <= 1'b1;
                                    video_ram_copy_done <= 1'b0;
                                end else if (dbi[2]) begin
                                    // fill
                                    video_ram_fill_dst <= { video_ram_hi_1, video_ram_lo_1 };
                                    video_ram_fill_num <= { video_ram_idx_2, video_ram_idx_1 };
                                    video_ram_fill_val <= video_ram_lo_2;
                                    video_ram_fill_done <= 1'b0;
                                end
                            end else begin
                                // reg overlay or video mem
                                // persistence lock must be open to allow
                                auto_ram_sel <= 0;
                                write_ram(
                                    .overlay(video_ram_flag_regs_overlay),
                                    .ram_lo(video_ram_lo_1),
                                    .ram_hi(video_ram_hi_1),
                                    .ram_idx(video_ram_idx_1),
                                    .data(dbi),
                                    .from_cpu(1'b1),
                                    .do_persist(video_ram_flag_persist));
                            end
                        end
                    `VIDEO_MEM_2_HI:
                        if (extra_regs_activated)
                            video_ram_hi_2 <= dbi[7:0];
                    `VIDEO_MEM_2_LO:
                        if (extra_regs_activated)
                            video_ram_lo_2 <= dbi[7:0];
                    `VIDEO_MEM_2_VAL:
                        if (extra_regs_activated) begin
                            // reg overlay or video mem
                            // persistence lock must be open to allow
                            auto_ram_sel <= 1;
                            write_ram(
                                .overlay(video_ram_flag_regs_overlay),
                                .ram_lo(video_ram_lo_2),
                                .ram_hi(video_ram_hi_2),
                                .ram_idx(video_ram_idx_2),
                                .data(dbi),
                                .from_cpu(1'b1),
                                .do_persist(video_ram_flag_persist));
                        end
                    // --- END EXTENSIONS ----

                    default:;
                endcase
            end
        end

        // --- BEGIN EXTENSIONS ----

        // CPU read from video mem
        if (video_ram_r)
            dbo[7:0] <= video_ram_data_out_a;

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
        // CPU write to color register ram
        if (color_regs_pre_wr2_a) begin
            color_regs_pre_wr_a <= 1'b1;
            color_regs_pre_wr2_a <= 1'b0;
        end
        if (color_regs_pre_wr_a) begin
            // Now we can do the write
            color_regs_pre_wr_a <= 1'b0;
            color_regs_wr_a <= 1'b1;
            color_regs_aw <= 1'b1;
            case (color_regs_wr_nibble)
                2'b00:
                    color_regs_data_in_a <= {color_regs_wr_value, color_regs_data_out_a[17:0]};
                2'b01:
                    color_regs_data_in_a <= {color_regs_data_out_a[23:18] , color_regs_wr_value, color_regs_data_out_a[11:0]};
                2'b10:
                    color_regs_data_in_a <= {color_regs_data_out_a[23:12], color_regs_wr_value, color_regs_data_out_a[5:0]};
                2'b11:
                    color_regs_data_in_a <= {color_regs_data_out_a[23:6], color_regs_wr_value}; // never used
            endcase
        end
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
        // CPU write to luma register ram
        if (luma_regs_pre_wr2_a) begin
            luma_regs_pre_wr_a <= 1'b1;
            luma_regs_pre_wr2_a <= 1'b0;
        end
        if (luma_regs_pre_wr_a) begin
            // Now we can do the write
            luma_regs_pre_wr_a <= 1'b0;
            luma_regs_wr_a <= 1'b1;
            luma_regs_aw <= 1'b1;
            // 18-bits : llllllppppppppaaaa
            case (luma_regs_wr_nibble)
                2'b00: //luma
                    luma_regs_data_in_a <= {luma_regs_wr_value[5:0], luma_regs_data_out_a[11:0]};
                2'b01: // phase
                    luma_regs_data_in_a <= {luma_regs_data_out_a[17:12] , luma_regs_wr_value[7:0], luma_regs_data_out_a[3:0]};
                2'b10: // amplitude
                    luma_regs_data_in_a <= {luma_regs_data_out_a[17:4], luma_regs_wr_value[3:0]};
                default:
                    ;
            endcase
        end
`endif

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
        // CPU read from color regs
        if (color_regs_r) begin
            case (color_regs_r_nibble)
                2'b00: dbo[7:0] <= { 2'b0, color_regs_data_out_a[23:18] };
                2'b01: dbo[7:0] <= { 2'b0, color_regs_data_out_a[17:12] };
                2'b10: dbo[7:0] <= { 2'b0, color_regs_data_out_a[11:6] };
                2'b11: dbo[7:0] <= { 2'b0, color_regs_data_out_a[5:0] };
            endcase
        end
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
        // CPU read from luma regs
        if (luma_regs_r) begin
            case (luma_regs_r_nibble)
                2'b00: dbo[7:0] <= { 2'b0, luma_regs_data_out_a[17:12] };
                2'b01: dbo[7:0] <= luma_regs_data_out_a[11:4];
                2'b10: dbo[7:0] <= { 4'b0, luma_regs_data_out_a[3:0] };
                default: ;
            endcase
        end
`endif

        // Only need 1 tick to write to video ram
        if (video_ram_wr_a)
            video_ram_wr_a <= 1'b0;

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
        // Only need 1 tick to write to color ram
        if (color_regs_wr_a)
            color_regs_wr_a <= 1'b0;
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
        // Only need 1 tick to write to color ram
        if (luma_regs_wr_a)
            luma_regs_wr_a <= 1'b0;
`endif

        // Near the start of the low cycle, handle auto increment of
        // our vram pointers.
        if (~clk_phi && phi_phase_start_dav_plus_2) begin
            // Always clear both flags and propagate r to r2 here.
            video_ram_r <= 0;
            video_ram_r2 <= video_ram_r;
            video_ram_aw <= 1'b0;

`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
            color_regs_r <= 0;
            color_regs_r2 <= color_regs_r;
            color_regs_aw <= 1'b0;
`endif
`endif

`ifdef CONFIGURABLE_LUMAS
            luma_regs_r <= 0;
            luma_regs_r2 <= luma_regs_r;
            luma_regs_aw <= 1'b0;
`endif

            // We propagated r to r2 on reads so that we auto increment
            // two cycles after a read due to some instructions reading first,
            // then writing.  If we didn't do this, those instructions would
            // cause two increments when we only wanted one.  So this effectively
            // waits a full cycle before commiting to increment after a read.
            if (video_ram_r2 || video_ram_aw
`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
                    || color_regs_r2 || color_regs_aw
`endif
`endif
`ifdef CONFIGURABLE_LUMAS
                    || luma_regs_r2 || luma_regs_aw
`endif
               ) begin
                // Handle auto increment /decrement after port access
                if (auto_ram_sel == 0) begin // loc 1 of port a
                    case(video_ram_flag_port_1_auto) // auto inc port a
                        2'd1: begin
                            if (video_ram_lo_1 < 8'hff)
                                video_ram_lo_1 <= video_ram_lo_1 + 8'b1;
                            else begin
                                video_ram_lo_1 <= 8'h00;
                                video_ram_hi_1 <= video_ram_hi_1 + 8'b1;
                            end
                        end
                        2'd2: begin
                            if (video_ram_lo_1 > 8'h00)
                                video_ram_lo_1 <= video_ram_lo_1 - 8'b1;
                            else begin
                                video_ram_lo_1 <= 8'hff;
                                video_ram_hi_1 <= video_ram_hi_1 - 8'b1;
                            end
                        end
                        default:
                            ;
                    endcase
                end else begin // loc 2 of port a
                    case(video_ram_flag_port_2_auto) // auto inc port b
                        2'd1: begin
                            if (video_ram_lo_2 < 8'hff)
                                video_ram_lo_2 <= video_ram_lo_2 + 8'b1;
                            else begin
                                video_ram_lo_2 <= 8'h00;
                                video_ram_hi_2 <= video_ram_hi_2 + 8'b1;
                            end
                        end
                        2'd2: begin
                            if (video_ram_lo_2 > 8'h00)
                                video_ram_lo_2 <= video_ram_lo_2 - 8'b1;
                            else begin
                                video_ram_lo_2 <= 8'hff;
                                video_ram_hi_2 <= video_ram_hi_2 - 8'b1;
                            end
                        end
                        default:
                            ;
                    endcase
                end
            end
        end

        // Handle block copy here
        if (video_ram_copy_num > 0) begin
            if (video_ram_copy_state == 2'b0) begin
                // read
                video_ram_wr_a <= 1'b0;
                video_ram_addr_a <= video_ram_copy_src[ram_width-1:0];
            end else if (video_ram_copy_state == 2'b10) begin
                // write
                video_ram_wr_a <= 1'b1;
                video_ram_addr_a <= video_ram_copy_dst[ram_width-1:0];
                video_ram_data_in_a <= video_ram_data_out_a;
                video_ram_copy_num <= video_ram_copy_num - 16'b1;
                if (video_ram_copy_dir) begin
                    video_ram_copy_src <= video_ram_copy_src - 16'b1;
                    video_ram_copy_dst <= video_ram_copy_dst - 16'b1;
                end else begin
                    video_ram_copy_src <= video_ram_copy_src + 16'b1;
                    video_ram_copy_dst <= video_ram_copy_dst + 16'b1;
                end
            end
            video_ram_copy_state <= video_ram_copy_state + 2'b1;
        end
        else if (video_ram_copy_num == 0 && !video_ram_copy_done) begin
            video_ram_copy_done <= 1'b1;
            video_ram_wr_a <= 1'b0;
            video_ram_idx_1 <= 8'b0; // signal done
            video_ram_idx_2 <= 8'b0;
        end
        // Handle block fill here
        if (video_ram_fill_num > 0) begin
            video_ram_wr_a <= 1'b1;
            video_ram_addr_a <= video_ram_fill_dst[ram_width-1:0];
            video_ram_data_in_a <= video_ram_fill_val;
            video_ram_fill_dst <= video_ram_fill_dst + 16'b1;
            video_ram_fill_num <= video_ram_fill_num - 16'b1;
        end
        else if (video_ram_fill_num == 0 && !video_ram_fill_done) begin
            video_ram_fill_done <= 1'b1;
            video_ram_wr_a <= 1'b0;
            video_ram_idx_1 <= 8'b0; // signal done
            video_ram_idx_2 <= 8'b0;
        end

        // --- END EXTENSIONS ----
    end

`ifdef NEED_RGB
// At every pixel clock tick, set red,green,blue from color
// register ram according to the pixel_color4 address.
always @(posedge clk_dot4x)
begin
`ifndef HIDE_SYNC
    if (active) begin
`endif
`ifdef CONFIGURABLE_RGB
        if (half_bright) begin
            red <= {1'b0, color_regs_data_out_b[23:19]};
            green <= {1'b0, color_regs_data_out_b[17:13]};
            blue <= {1'b0, color_regs_data_out_b[11:7]};
        end else begin
            red <= color_regs_data_out_b[23:18];
            green <= color_regs_data_out_b[17:12];
            blue <= color_regs_data_out_b[11:6];
        end
`else
        if (half_bright)
        case (pixel_color4)
            `BLACK:{red, green, blue} <= {6'h00, 6'h00, 6'h00};
            `WHITE:{red, green, blue} <= {6'h3f, 6'h3f, 6'h3f};
            `RED:{red, green, blue} <= {6'h2b, 6'h0a, 6'h0a};
            `CYAN:{red, green, blue} <= {6'h18, 6'h36, 6'h33};
            `PURPLE:{red, green, blue} <= {6'h2c, 6'h0f, 6'h2d};
            `GREEN:{red, green, blue} <= {6'h12, 6'h31, 6'h12};
            `BLUE:{red, green, blue} <= {6'h0d, 6'h0e, 6'h31};
            `YELLOW:{red, green, blue} <= {6'h39, 6'h3b, 6'h13};
            `ORANGE:{red, green, blue} <= {6'h2d, 6'h16, 6'h07};
            `BROWN:{red, green, blue} <= {6'h1a, 6'h0e, 6'h02};
            `PINK:{red, green, blue} <= {6'h3a, 6'h1d, 6'h1b};
            `DARK_GREY:{red, green, blue} <= {6'h13, 6'h13, 6'h13};
            `GREY:{red, green, blue} <= {6'h21, 6'h21, 6'h21};
            `LIGHT_GREEN:{red, green, blue} <= {6'h29, 6'h3e, 6'h27};
            `LIGHT_BLUE:{red, green, blue} <= {6'h1c, 6'h1f, 6'h39};
            `LIGHT_GREY:{red, green, blue} <= {6'h2d, 6'h2d, 6'h2d};
        endcase
        else
        case (pixel_color4)
            `BLACK:{red, green, blue} <= {6'h00, 6'h00, 6'h00};
            `WHITE:{red, green, blue} <= {6'h1f, 6'h1f, 6'h1f};
            `RED:{red, green, blue} <= {6'h15, 6'h05, 6'h05};
            `CYAN:{red, green, blue} <= {6'h0c, 6'h1b, 6'h19};
            `PURPLE:{red, green, blue} <= {6'h16, 6'h07, 6'h16};
            `GREEN:{red, green, blue} <= {6'h09, 6'h18, 6'h09};
            `BLUE:{red, green, blue} <= {6'h06, 6'h07, 6'h18};
            `YELLOW:{red, green, blue} <= {6'h1c, 6'h1d, 6'h09};
            `ORANGE:{red, green, blue} <= {6'h16, 6'h0b, 6'h03};
            `BROWN:{red, green, blue} <= {6'h0d, 6'h07, 6'h01};
            `PINK:{red, green, blue} <= {6'h1d, 6'h0e, 6'h0d};
            `DARK_GREY:{red, green, blue} <= {6'h09, 6'h09, 6'h09};
            `GREY:{red, green, blue} <= {6'h10, 6'h10, 6'h10};
            `LIGHT_GREEN:{red, green, blue} <= {6'h14, 6'h1f, 6'h13};
            `LIGHT_BLUE:{red, green, blue} <= {6'h0e, 6'h0f, 6'h1c};
            `LIGHT_GREY:{red, green, blue} <= {6'h16, 6'h16, 6'h16};
        endcase
`endif
`ifndef HIDE_SYNC
    end else begin
        red <= 6'b0;
        green <= 6'b0;
        blue <= 6'b0;
    end
`endif
end
`endif

// Use make_luma_bin.c to generate the code
// for the non-configurable sections.
`ifdef GEN_LUMA_CHROMA
always @(posedge clk_dot4x)
begin
`ifdef CONFIGURABLE_LUMAS
    lumareg_o <= luma_regs_data_out_b[17:12];
    phasereg_o <= luma_regs_data_out_b[11:4];
    amplitudereg_o <= luma_regs_data_out_b[3:0];
`else
    case (pixel_color3)
        `BLACK      : lumareg_o <= 6'h0c;
        `WHITE      : lumareg_o <= 6'h3f;
        `RED        : lumareg_o <= 6'h18;
        `CYAN       : lumareg_o <= 6'h2a;
        `PURPLE     : lumareg_o <= 6'h1b;
        `GREEN      : lumareg_o <= 6'h23;
        `BLUE       : lumareg_o <= 6'h15;
        `YELLOW     : lumareg_o <= 6'h32;
        `ORANGE     : lumareg_o <= 6'h1b;
        `BROWN      : lumareg_o <= 6'h15;
        `PINK       : lumareg_o <= 6'h23;
        `DARK_GREY  : lumareg_o <= 6'h18;
        `GREY       : lumareg_o <= 6'h21;
        `LIGHT_GREEN: lumareg_o <= 6'h32;
        `LIGHT_BLUE : lumareg_o <= 6'h21;
        `LIGHT_GREY : lumareg_o <= 6'h2a;
    endcase

    case (pixel_color3)
        `BLACK      : phasereg_o <= 8'h00; // unmodulated
        `WHITE      : phasereg_o <= 8'h00; // unmodulated
        `RED        : phasereg_o <= 8'h50; // 112.5 degrees
        `CYAN       : phasereg_o <= 8'hd0; // 292.5 degrees
        `PURPLE     : phasereg_o <= 8'h20; // 45.0 degrees
        `GREEN      : phasereg_o <= 8'ha0; // 225.0 degrees
        `BLUE       : phasereg_o <= 8'hf1; // 338.9 degrees
        `YELLOW     : phasereg_o <= 8'h80; // 180.0 degrees
        `ORANGE     : phasereg_o <= 8'h60; // 135.0 degrees
        `BROWN      : phasereg_o <= 8'h70; // 157.5 degrees
        `PINK       : phasereg_o <= 8'h50; // 112.5 degrees
        `DARK_GREY  : phasereg_o <= 8'h00; // unmodulated
        `GREY       : phasereg_o <= 8'h00; // unmodulated
        `LIGHT_GREEN: phasereg_o <= 8'ha0; // 225.0 degrees
        `LIGHT_BLUE : phasereg_o <= 8'hf1; // 338.9 degrees
        `LIGHT_GREY : phasereg_o <= 8'h00; // unmodulated
    endcase

    case (pixel_color3)
        `BLACK      : amplitudereg_o <= 4'h00; // unmodulated
        `WHITE      : amplitudereg_o <= 4'h00; // unmodulated
        `RED        : amplitudereg_o <= 4'h0d;
        `CYAN       : amplitudereg_o <= 4'h0a;
        `PURPLE     : amplitudereg_o <= 4'h0c;
        `GREEN      : amplitudereg_o <= 4'h0b;
        `BLUE       : amplitudereg_o <= 4'h0b;
        `YELLOW     : amplitudereg_o <= 4'h0f;
        `ORANGE     : amplitudereg_o <= 4'h0f;
        `BROWN      : amplitudereg_o <= 4'h0b;
        `PINK       : amplitudereg_o <= 4'h0c;
        `DARK_GREY  : amplitudereg_o <= 4'h00; // unmodulated
        `GREY       : amplitudereg_o <= 4'h00; // unmodulated
        `LIGHT_GREEN: amplitudereg_o <= 4'h0d;
        `LIGHT_BLUE : amplitudereg_o <= 4'h0d;
        `LIGHT_GREY : amplitudereg_o <= 4'h00; // unmodulated
    endcase
`endif
end
`endif

// read_ram and write_ram task definitions
`include "registers_ram.v"

// Handle init and settings retrieval for boards
// with MCU + SERIAL

`ifdef HAVE_EEPROM
`include "registers_eeprom.v"
`else
`include "registers_no_eeprom.v"
`endif

`ifdef HAVE_FLASH
`include "registers_flash.v"
`endif

endmodule
