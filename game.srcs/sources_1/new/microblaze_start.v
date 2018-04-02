`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/05/12 19:55:31
// Design Name: 
// Module Name: microblaze_start
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module microblaze_start(
    output [12:0]DDR2_addr,
    output [2:0]DDR2_ba,
    output DDR2_cas_n,
    output [0:0]DDR2_ck_n,
    output [0:0]DDR2_ck_p,
    output [0:0]DDR2_cke,
    output [0:0]DDR2_cs_n,
    output [1:0]DDR2_dm,
    inout [15:0]DDR2_dq,
    inout [1:0]DDR2_dqs_n,
    inout [1:0]DDR2_dqs_p,
    output [0:0]DDR2_odt,
    output DDR2_ras_n,
    output DDR2_we_n,
    input PS2_CLK,
    input PS2_DATA,
    input [15:0]SW,
    inout [15:0]LED,
    inout spi_0_io0_io,
    inout spi_0_io1_io,
    inout [0:0]spi_0_ss_io,
    output VGA_HS,
    output [3:0]VGA_B,
    output [3:0]VGA_G,
    output [3:0]VGA_R,
    output VGA_VS,
    output AUD_PWM,
    output AUD_SD,
    input CLK100MHZ,
    input CPU_RESETN
    );
    wire [5:0]tft_vga_b_6;
    wire [5:0]tft_vga_g_6;
    wire [5:0]tft_vga_r_6;
    assign VGA_B=tft_vga_b_6[5:2];
    assign VGA_G=tft_vga_g_6[5:2];
    assign VGA_R=tft_vga_r_6[5:2];
 mysys_wrapper
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
       SW,
       LED,
       AUD_PWM,
       AUD_SD,
       CPU_RESETN,
       spi_0_io0_io,
       spi_0_io1_io,
       spi_0_ss_io,
       CLK100MHZ,
       VGA_HS,
       tft_vga_b_6,
       tft_vga_g_6,
       tft_vga_r_6,
       VGA_VS);
       
endmodule
