//Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
//Date        : Thu Dec 21 00:36:49 2017
//Host        : DESKTOP-27DIMJ4 running 64-bit major release  (build 9200)
//Command     : generate_target mysys_wrapper.bd
//Design      : mysys_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module mysys_wrapper
   (DDR2_addr,
    DDR2_ba,
    DDR2_cas_n,
    DDR2_ck_n,
    DDR2_ck_p,
    DDR2_cke,
    DDR2_cs_n,
    DDR2_dm,
    DDR2_dq,
    DDR2_dqs_n,
    DDR2_dqs_p,
    DDR2_odt,
    DDR2_ras_n,
    DDR2_we_n,
    PS2_CLK,
    PS2_DATA,
    dip_switches_16bits_tri_i,
    gpio_led_tri_io,
    pwm_out,
    pwm_sd,
    reset,
    spi_0_io0_io,
    spi_0_io1_io,
    spi_0_ss_io,
    sys_clock,
    tft_hsync,
    tft_vga_b,
    tft_vga_g,
    tft_vga_r,
    tft_vsync);
  output [12:0]DDR2_addr;
  output [2:0]DDR2_ba;
  output DDR2_cas_n;
  output [0:0]DDR2_ck_n;
  output [0:0]DDR2_ck_p;
  output [0:0]DDR2_cke;
  output [0:0]DDR2_cs_n;
  output [1:0]DDR2_dm;
  inout [15:0]DDR2_dq;
  inout [1:0]DDR2_dqs_n;
  inout [1:0]DDR2_dqs_p;
  output [0:0]DDR2_odt;
  output DDR2_ras_n;
  output DDR2_we_n;
  input PS2_CLK;
  input PS2_DATA;
  input [15:0]dip_switches_16bits_tri_i;
  inout [15:0]gpio_led_tri_io;
  output pwm_out;
  output pwm_sd;
  input reset;
  inout spi_0_io0_io;
  inout spi_0_io1_io;
  inout [0:0]spi_0_ss_io;
  input sys_clock;
  output tft_hsync;
  output [5:0]tft_vga_b;
  output [5:0]tft_vga_g;
  output [5:0]tft_vga_r;
  output tft_vsync;

  wire [12:0]DDR2_addr;
  wire [2:0]DDR2_ba;
  wire DDR2_cas_n;
  wire [0:0]DDR2_ck_n;
  wire [0:0]DDR2_ck_p;
  wire [0:0]DDR2_cke;
  wire [0:0]DDR2_cs_n;
  wire [1:0]DDR2_dm;
  wire [15:0]DDR2_dq;
  wire [1:0]DDR2_dqs_n;
  wire [1:0]DDR2_dqs_p;
  wire [0:0]DDR2_odt;
  wire DDR2_ras_n;
  wire DDR2_we_n;
  wire PS2_CLK;
  wire PS2_DATA;
  wire [15:0]dip_switches_16bits_tri_i;
  wire [0:0]gpio_led_tri_i_0;
  wire [1:1]gpio_led_tri_i_1;
  wire [10:10]gpio_led_tri_i_10;
  wire [11:11]gpio_led_tri_i_11;
  wire [12:12]gpio_led_tri_i_12;
  wire [13:13]gpio_led_tri_i_13;
  wire [14:14]gpio_led_tri_i_14;
  wire [15:15]gpio_led_tri_i_15;
  wire [2:2]gpio_led_tri_i_2;
  wire [3:3]gpio_led_tri_i_3;
  wire [4:4]gpio_led_tri_i_4;
  wire [5:5]gpio_led_tri_i_5;
  wire [6:6]gpio_led_tri_i_6;
  wire [7:7]gpio_led_tri_i_7;
  wire [8:8]gpio_led_tri_i_8;
  wire [9:9]gpio_led_tri_i_9;
  wire [0:0]gpio_led_tri_io_0;
  wire [1:1]gpio_led_tri_io_1;
  wire [10:10]gpio_led_tri_io_10;
  wire [11:11]gpio_led_tri_io_11;
  wire [12:12]gpio_led_tri_io_12;
  wire [13:13]gpio_led_tri_io_13;
  wire [14:14]gpio_led_tri_io_14;
  wire [15:15]gpio_led_tri_io_15;
  wire [2:2]gpio_led_tri_io_2;
  wire [3:3]gpio_led_tri_io_3;
  wire [4:4]gpio_led_tri_io_4;
  wire [5:5]gpio_led_tri_io_5;
  wire [6:6]gpio_led_tri_io_6;
  wire [7:7]gpio_led_tri_io_7;
  wire [8:8]gpio_led_tri_io_8;
  wire [9:9]gpio_led_tri_io_9;
  wire [0:0]gpio_led_tri_o_0;
  wire [1:1]gpio_led_tri_o_1;
  wire [10:10]gpio_led_tri_o_10;
  wire [11:11]gpio_led_tri_o_11;
  wire [12:12]gpio_led_tri_o_12;
  wire [13:13]gpio_led_tri_o_13;
  wire [14:14]gpio_led_tri_o_14;
  wire [15:15]gpio_led_tri_o_15;
  wire [2:2]gpio_led_tri_o_2;
  wire [3:3]gpio_led_tri_o_3;
  wire [4:4]gpio_led_tri_o_4;
  wire [5:5]gpio_led_tri_o_5;
  wire [6:6]gpio_led_tri_o_6;
  wire [7:7]gpio_led_tri_o_7;
  wire [8:8]gpio_led_tri_o_8;
  wire [9:9]gpio_led_tri_o_9;
  wire [0:0]gpio_led_tri_t_0;
  wire [1:1]gpio_led_tri_t_1;
  wire [10:10]gpio_led_tri_t_10;
  wire [11:11]gpio_led_tri_t_11;
  wire [12:12]gpio_led_tri_t_12;
  wire [13:13]gpio_led_tri_t_13;
  wire [14:14]gpio_led_tri_t_14;
  wire [15:15]gpio_led_tri_t_15;
  wire [2:2]gpio_led_tri_t_2;
  wire [3:3]gpio_led_tri_t_3;
  wire [4:4]gpio_led_tri_t_4;
  wire [5:5]gpio_led_tri_t_5;
  wire [6:6]gpio_led_tri_t_6;
  wire [7:7]gpio_led_tri_t_7;
  wire [8:8]gpio_led_tri_t_8;
  wire [9:9]gpio_led_tri_t_9;
  wire pwm_out;
  wire pwm_sd;
  wire reset;
  wire spi_0_io0_i;
  wire spi_0_io0_io;
  wire spi_0_io0_o;
  wire spi_0_io0_t;
  wire spi_0_io1_i;
  wire spi_0_io1_io;
  wire spi_0_io1_o;
  wire spi_0_io1_t;
  wire [0:0]spi_0_ss_i_0;
  wire [0:0]spi_0_ss_io_0;
  wire [0:0]spi_0_ss_o_0;
  wire spi_0_ss_t;
  wire sys_clock;
  wire tft_hsync;
  wire [5:0]tft_vga_b;
  wire [5:0]tft_vga_g;
  wire [5:0]tft_vga_r;
  wire tft_vsync;

  IOBUF gpio_led_tri_iobuf_0
       (.I(gpio_led_tri_o_0),
        .IO(gpio_led_tri_io[0]),
        .O(gpio_led_tri_i_0),
        .T(gpio_led_tri_t_0));
  IOBUF gpio_led_tri_iobuf_1
       (.I(gpio_led_tri_o_1),
        .IO(gpio_led_tri_io[1]),
        .O(gpio_led_tri_i_1),
        .T(gpio_led_tri_t_1));
  IOBUF gpio_led_tri_iobuf_10
       (.I(gpio_led_tri_o_10),
        .IO(gpio_led_tri_io[10]),
        .O(gpio_led_tri_i_10),
        .T(gpio_led_tri_t_10));
  IOBUF gpio_led_tri_iobuf_11
       (.I(gpio_led_tri_o_11),
        .IO(gpio_led_tri_io[11]),
        .O(gpio_led_tri_i_11),
        .T(gpio_led_tri_t_11));
  IOBUF gpio_led_tri_iobuf_12
       (.I(gpio_led_tri_o_12),
        .IO(gpio_led_tri_io[12]),
        .O(gpio_led_tri_i_12),
        .T(gpio_led_tri_t_12));
  IOBUF gpio_led_tri_iobuf_13
       (.I(gpio_led_tri_o_13),
        .IO(gpio_led_tri_io[13]),
        .O(gpio_led_tri_i_13),
        .T(gpio_led_tri_t_13));
  IOBUF gpio_led_tri_iobuf_14
       (.I(gpio_led_tri_o_14),
        .IO(gpio_led_tri_io[14]),
        .O(gpio_led_tri_i_14),
        .T(gpio_led_tri_t_14));
  IOBUF gpio_led_tri_iobuf_15
       (.I(gpio_led_tri_o_15),
        .IO(gpio_led_tri_io[15]),
        .O(gpio_led_tri_i_15),
        .T(gpio_led_tri_t_15));
  IOBUF gpio_led_tri_iobuf_2
       (.I(gpio_led_tri_o_2),
        .IO(gpio_led_tri_io[2]),
        .O(gpio_led_tri_i_2),
        .T(gpio_led_tri_t_2));
  IOBUF gpio_led_tri_iobuf_3
       (.I(gpio_led_tri_o_3),
        .IO(gpio_led_tri_io[3]),
        .O(gpio_led_tri_i_3),
        .T(gpio_led_tri_t_3));
  IOBUF gpio_led_tri_iobuf_4
       (.I(gpio_led_tri_o_4),
        .IO(gpio_led_tri_io[4]),
        .O(gpio_led_tri_i_4),
        .T(gpio_led_tri_t_4));
  IOBUF gpio_led_tri_iobuf_5
       (.I(gpio_led_tri_o_5),
        .IO(gpio_led_tri_io[5]),
        .O(gpio_led_tri_i_5),
        .T(gpio_led_tri_t_5));
  IOBUF gpio_led_tri_iobuf_6
       (.I(gpio_led_tri_o_6),
        .IO(gpio_led_tri_io[6]),
        .O(gpio_led_tri_i_6),
        .T(gpio_led_tri_t_6));
  IOBUF gpio_led_tri_iobuf_7
       (.I(gpio_led_tri_o_7),
        .IO(gpio_led_tri_io[7]),
        .O(gpio_led_tri_i_7),
        .T(gpio_led_tri_t_7));
  IOBUF gpio_led_tri_iobuf_8
       (.I(gpio_led_tri_o_8),
        .IO(gpio_led_tri_io[8]),
        .O(gpio_led_tri_i_8),
        .T(gpio_led_tri_t_8));
  IOBUF gpio_led_tri_iobuf_9
       (.I(gpio_led_tri_o_9),
        .IO(gpio_led_tri_io[9]),
        .O(gpio_led_tri_i_9),
        .T(gpio_led_tri_t_9));
  mysys mysys_i
       (.DDR2_addr(DDR2_addr),
        .DDR2_ba(DDR2_ba),
        .DDR2_cas_n(DDR2_cas_n),
        .DDR2_ck_n(DDR2_ck_n),
        .DDR2_ck_p(DDR2_ck_p),
        .DDR2_cke(DDR2_cke),
        .DDR2_cs_n(DDR2_cs_n),
        .DDR2_dm(DDR2_dm),
        .DDR2_dq(DDR2_dq),
        .DDR2_dqs_n(DDR2_dqs_n),
        .DDR2_dqs_p(DDR2_dqs_p),
        .DDR2_odt(DDR2_odt),
        .DDR2_ras_n(DDR2_ras_n),
        .DDR2_we_n(DDR2_we_n),
        .GPIO_LED_tri_i({gpio_led_tri_i_15,gpio_led_tri_i_14,gpio_led_tri_i_13,gpio_led_tri_i_12,gpio_led_tri_i_11,gpio_led_tri_i_10,gpio_led_tri_i_9,gpio_led_tri_i_8,gpio_led_tri_i_7,gpio_led_tri_i_6,gpio_led_tri_i_5,gpio_led_tri_i_4,gpio_led_tri_i_3,gpio_led_tri_i_2,gpio_led_tri_i_1,gpio_led_tri_i_0}),
        .GPIO_LED_tri_o({gpio_led_tri_o_15,gpio_led_tri_o_14,gpio_led_tri_o_13,gpio_led_tri_o_12,gpio_led_tri_o_11,gpio_led_tri_o_10,gpio_led_tri_o_9,gpio_led_tri_o_8,gpio_led_tri_o_7,gpio_led_tri_o_6,gpio_led_tri_o_5,gpio_led_tri_o_4,gpio_led_tri_o_3,gpio_led_tri_o_2,gpio_led_tri_o_1,gpio_led_tri_o_0}),
        .GPIO_LED_tri_t({gpio_led_tri_t_15,gpio_led_tri_t_14,gpio_led_tri_t_13,gpio_led_tri_t_12,gpio_led_tri_t_11,gpio_led_tri_t_10,gpio_led_tri_t_9,gpio_led_tri_t_8,gpio_led_tri_t_7,gpio_led_tri_t_6,gpio_led_tri_t_5,gpio_led_tri_t_4,gpio_led_tri_t_3,gpio_led_tri_t_2,gpio_led_tri_t_1,gpio_led_tri_t_0}),
        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA),
        .SPI_0_io0_i(spi_0_io0_i),
        .SPI_0_io0_o(spi_0_io0_o),
        .SPI_0_io0_t(spi_0_io0_t),
        .SPI_0_io1_i(spi_0_io1_i),
        .SPI_0_io1_o(spi_0_io1_o),
        .SPI_0_io1_t(spi_0_io1_t),
        .SPI_0_ss_i(spi_0_ss_i_0),
        .SPI_0_ss_o(spi_0_ss_o_0),
        .SPI_0_ss_t(spi_0_ss_t),
        .dip_switches_16bits_tri_i(dip_switches_16bits_tri_i),
        .pwm_out(pwm_out),
        .pwm_sd(pwm_sd),
        .reset(reset),
        .sys_clock(sys_clock),
        .tft_hsync(tft_hsync),
        .tft_vga_b(tft_vga_b),
        .tft_vga_g(tft_vga_g),
        .tft_vga_r(tft_vga_r),
        .tft_vsync(tft_vsync));
  IOBUF spi_0_io0_iobuf
       (.I(spi_0_io0_o),
        .IO(spi_0_io0_io),
        .O(spi_0_io0_i),
        .T(spi_0_io0_t));
  IOBUF spi_0_io1_iobuf
       (.I(spi_0_io1_o),
        .IO(spi_0_io1_io),
        .O(spi_0_io1_i),
        .T(spi_0_io1_t));
  IOBUF spi_0_ss_iobuf_0
       (.I(spi_0_ss_o_0),
        .IO(spi_0_ss_io[0]),
        .O(spi_0_ss_i_0),
        .T(spi_0_ss_t));
endmodule
