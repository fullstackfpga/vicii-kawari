#include <stdio.h>
#include <stdlib.h>

int for_comp = 0;

typedef void (*def_func)();

void test_pattern_0() { printf ("`define TEST_PATTERN 1\n"); }
void have_color_clocks_0() { printf ("`define HAVE_COLOR_CLOCKS 1\n"); }
void have_sys_clock_0() { printf ("`define HAVE_SYS_CLOCK 1\n"); }
void gen_luma_chroma_0() { printf ("`define GEN_LUMA_CHROMA 1\n"); }
void configurable_rgb_0() { printf ("`define CONFIGURABLE_RGB 1\n"); }
void configurable_lumas_0() { printf ("`define CONFIGURABLE_LUMAS 1\n"); }
void configurable_timing_0() { printf ("`define CONFIGURABLE_TIMING 1\n"); }
void average_lumas_0() { printf ("`define AVERAGE_LUMAS 1\n"); }
void have_mcu_eeprom_0() { printf ("`define HAVE_MCU_EEPROM 1\n"); have_sys_clock_0(); }
void with_spi_0() { printf ("`define WITH_SPI 1\n"); }
void have_eeprom_0() { printf ("`define HAVE_EEPROM 1\n"); with_spi_0(); }
void have_flash_0() { printf ("`define HAVE_FLASH 1\n"); with_spi_0(); }
void need_rgb_0() { printf ("`define NEED_RGB 1\n"); }
void gen_rgb_0() { printf ("`define GEN_RGB 1\n"); need_rgb_0(); }
void with_dvi_0() { printf ("`define WITH_DVI 1\n"); need_rgb_0(); }
void hires_modes_0() { printf ("`define HIRES_MODES 1\n"); }
void hide_sync_0() { printf ("`define HIDE_SYNC 1\n"); }

void test_pattern_1() { printf ("-DTEST_PATTERN=1 "); }
void have_color_clocks_1() { printf ("-DHAVE_COLOR_CLOCKS=1 "); }
void have_sys_clock_1() { printf ("-DHAVE_SYS_CLOCK=1 "); }
void gen_luma_chroma_1() { printf ("-DGEN_LUMA_CHROMA=1 "); }
void configurable_rgb_1() { printf ("-DCONFIGURABLE_RGB=1 "); }
void configurable_lumas_1() { printf ("-DCONFIGURABLE_LUMAS=1 "); }
void configurable_timing_1() { printf ("-DCONFIGURABLE_TIMING=1 "); }
void average_lumas_1() { printf ("-DAVERAGE_LUMAS=1 "); }
void have_mcu_eeprom_1() { printf ("-DHAVE_MCU_EEPROM=1 "); have_sys_clock_1(); }
void with_spi_1() { printf ("-DWITH_SPI=1 "); }
void have_eeprom_1() { printf ("-DHAVE_EEPROM=1 "); with_spi_1(); }
void have_flash_1() { printf ("-DHAVE_FLASH=1 "); with_spi_1(); }
void need_rgb_1() { printf ("-DNEED_RGB=1 "); }
void gen_rgb_1() { printf ("-DGEN_RGB=1 "); need_rgb_1(); }
void with_dvi_1() { printf ("-DWITH_DVI=1 "); need_rgb_1(); }
void hires_modes_1() { printf ("-DHIRES_MODES=1 "); }
void hide_sync_1() { printf ("-DHIDE_SYNC=1 "); }

void main(int argc, char* argv[]) {

	def_func test_pattern;
	def_func with_dvi;
	def_func have_color_clocks;
	def_func have_sys_clock;
	def_func gen_luma_chroma;
	def_func configurable_rgb;
	def_func configurable_lumas;
	def_func configurable_timing;
	def_func average_lumas;
	def_func have_mcu_eeprom;
	def_func have_eeprom;
	def_func have_flash;
	def_func need_rgb;
	def_func gen_rgb;
	def_func hires_modes;
	def_func hide_sync;

    char defines[] = {
    };

    int config = -1;
    if (argc > 1)
       config = atoi(argv[1]);

    test_pattern = test_pattern_0;
    with_dvi = with_dvi_0;
    have_color_clocks = have_color_clocks_0;
    have_sys_clock = have_sys_clock_0;
    gen_luma_chroma = gen_luma_chroma_0;
    configurable_rgb = configurable_rgb_0;
    configurable_lumas = configurable_lumas_0;
    configurable_timing  = configurable_timing_0;
    average_lumas = average_lumas_0;
    have_mcu_eeprom = have_mcu_eeprom_0;
    have_eeprom = have_eeprom_0;
    have_flash = have_flash_0;
    need_rgb = need_rgb_0;
    gen_rgb = gen_rgb_0;
    hires_modes = hires_modes_0;
    hide_sync = hide_sync_0;

    if (argc > 2) {
        test_pattern = test_pattern_1;
        with_dvi = with_dvi_1;
        have_color_clocks = have_color_clocks_1;
        have_sys_clock = have_sys_clock;
        gen_luma_chroma = gen_luma_chroma_1;
        configurable_rgb = configurable_rgb_1;
        configurable_lumas = configurable_lumas_1;
        configurable_timing  = configurable_timing_1;
        average_lumas = average_lumas_1;
        have_mcu_eeprom = have_mcu_eeprom_1;
        have_eeprom = have_eeprom_1;
        have_flash = have_flash_1;
        need_rgb = need_rgb_1;
        gen_rgb = gen_rgb_1;
        hires_modes = hires_modes_1;
        hide_sync = hide_sync_1;
    }
    else {
       printf ("`define VERSION_MAJOR 4'd0\n");
       printf ("`define VERSION_MINOR 4'd2\n");
       printf ("`define SIMULATOR_BOARD 1\n");
    }

    switch (config) {
	    case 0:
		    have_color_clocks();
		    gen_luma_chroma();
		    have_mcu_eeprom();
		    gen_rgb();
		    hires_modes();
have_flash();
		    break;
	    case 1:
		    // Use this config for generating test results
		    // since it hides sync lines.
		    have_color_clocks();
		    gen_luma_chroma();
		    have_flash();
		    with_dvi();
		    hires_modes();
		    hide_sync();
		    break;
	    case 2:
		    have_color_clocks();
		    gen_luma_chroma();
		    have_eeprom();
		    break;
	    case 3:
		    with_dvi();
		    gen_rgb();
		    break;
	    case 4:
		    test_pattern();
		    break;
	    case 5:
		    have_color_clocks();
		    with_dvi();
		    break;
	    case 6:
		    have_color_clocks();
		    gen_luma_chroma();
		    gen_rgb();
		    configurable_rgb();
		    configurable_lumas();
		    configurable_timing();
		    break;
	    case 7:
		    have_color_clocks();
		    gen_luma_chroma();
		    average_lumas();
		    break;
	    default:
		    break;

    }
}
