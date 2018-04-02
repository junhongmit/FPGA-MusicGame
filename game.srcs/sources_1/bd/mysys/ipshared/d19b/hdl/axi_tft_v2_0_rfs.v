// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_iic_init.v   
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_iic_init.v
// Version:         v1.00.a
// Description:     This module consists of logic to configur the Chrontel 
//                  CH-7301 DVI transmitter chip through I2C interface.
//
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- tft_control.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
 `timescale 1 ps / 1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_iic_init( 
  Clk,                          // Clock input
  Reset_n,                      // Reset input
  SDA,                          // I2C data
  SCL,                          // I2C clock
  Done,                         // I2C configuration done
  IIC_xfer_done,                // IIC configuration done
  TFT_iic_xfer,                 // IIC configuration request
  TFT_iic_reg_addr,             // IIC register address
  TFT_iic_reg_data              // IIC register data
  );

///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////
                 
parameter C_I2C_SLAVE_ADDR = "1110110";

parameter CLK_RATE_MHZ = 50,  
          SCK_PERIOD_US = 30, 
          TRANSITION_CYCLE = (CLK_RATE_MHZ * SCK_PERIOD_US) / 2,
          TRANSITION_CYCLE_MSB = 11;  



input          Clk;
input          Reset_n;
inout          SDA;
inout          SCL;
output         Done;
output         IIC_xfer_done;
input          TFT_iic_xfer;
input [0:7]    TFT_iic_reg_addr;
input [0:7]    TFT_iic_reg_data;

  
          
localparam    IDLE           = 3'd0,
              INIT           = 3'd1,
              START          = 3'd2,
              CLK_FALL       = 3'd3,
              SETUP          = 3'd4,
              CLK_RISE       = 3'd5,
              WAIT_IIC       = 3'd6,
              XFER_DONE      = 3'd7,
              START_BIT      = 1'b1,
              ACK            = 1'b1,
              WRITE          = 1'b0,
              REG_ADDR0      = 8'h49,
              REG_ADDR1      = 8'h21,
              REG_ADDR2      = 8'h33,
              REG_ADDR3      = 8'h34,
              REG_ADDR4      = 8'h36,
              DATA0          = 8'hC0,
              DATA1          = 8'h09,
              DATA2a         = 8'h06,
              DATA3a         = 8'h26,
              DATA4a         = 8'hA0,
              DATA2b         = 8'h08,
              DATA3b         = 8'h16,
              DATA4b         = 8'h60,
              STOP_BIT       = 1'b0,            
              SDA_BUFFER_MSB = 27; 
          
wire [6:0]    SLAVE_ADDR = C_I2C_SLAVE_ADDR ;
          

reg                          SDA_out; 
reg                          SCL_out;  
reg [TRANSITION_CYCLE_MSB:0] cycle_count;
reg [2:0]                    c_state;
reg [2:0]                    n_state;
reg                          Done;   
reg [2:0]                    write_count;
reg [31:0]                   bit_count;
reg [SDA_BUFFER_MSB:0]       SDA_BUFFER;
wire                         transition; 
reg                          IIC_xfer_done;


// Generate I2C clock and data 
always @ (posedge Clk) 
begin : I2C_CLK_DATA
    if (~Reset_n || c_state == IDLE )
      begin
        SDA_out <= 1'b1;
        SCL_out <= 1'b1;
      end
    else if (c_state == INIT && transition) 
      begin 
        SDA_out <= 1'b0;
      end
    else if (c_state == SETUP) 
      begin
        SDA_out <= SDA_BUFFER[SDA_BUFFER_MSB];
      end
    else if (c_state == CLK_RISE && cycle_count == TRANSITION_CYCLE/2 
                                 && bit_count == SDA_BUFFER_MSB) 
      begin
        SDA_out <= 1'b1;
      end
    else if (c_state == CLK_FALL) 
      begin
        SCL_out <= 1'b0;
      end
    
    else if (c_state == CLK_RISE) 
      begin
        SCL_out <= 1'b1;
      end
end

assign SDA = SDA_out;
assign SCL = SCL_out;
                        

// Fill the SDA buffer 
always @ (posedge Clk) 
begin : SDA_BUF
    //reset or end condition
    if(~Reset_n) 
      begin
        SDA_BUFFER  <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR0,ACK,DATA0,ACK,STOP_BIT};
        cycle_count <= 0;
      end
    //setup sda for sck rise
    else if ( c_state==SETUP && cycle_count==TRANSITION_CYCLE)
      begin
        SDA_BUFFER <= {SDA_BUFFER[SDA_BUFFER_MSB-1:0],1'b0};
        cycle_count <= 0; 
      end
    //reset count at end of state
    else if ( cycle_count==TRANSITION_CYCLE)
       cycle_count <= 0; 
    //reset sda_buffer   
    else if (c_state==INIT && TFT_iic_xfer==1'b1 && Done) 
      begin
       SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,TFT_iic_reg_addr,
                                       ACK,TFT_iic_reg_data, ACK,STOP_BIT};
       cycle_count <= cycle_count+1;
      end   
    else if (c_state==WAIT_IIC )
      begin
        case(write_count)
          0:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR1,ACK,DATA1, 
                                                          ACK,STOP_BIT};
          1:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR2,ACK,DATA2b,
                                                          ACK,STOP_BIT};
          2:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR3,ACK,DATA3b,
                                                          ACK,STOP_BIT};
          3:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR4,ACK,DATA4b,
                                                          ACK,STOP_BIT};
        default: SDA_BUFFER <=28'dx;
        endcase 
        cycle_count <= cycle_count+1;
      end
    else
      cycle_count <= cycle_count+1;
end


// Generate write_count signal
always @ (posedge Clk)
begin : GEN_WRITE_CNT
 if(~Reset_n)
   write_count<=3'd0;
 else if (c_state == WAIT_IIC && cycle_count == TRANSITION_CYCLE && IIC_xfer_done==1'b0 )
   write_count <= write_count+1;
end    

// Transaction done signal                        
always @ (posedge Clk) 
begin : TRANS_DONE
    if(~Reset_n)
      Done <= 1'b0;
    else if (c_state == IDLE)
      Done <= 1'b1;
end
 
       
// Generate bit_count signal
always @ (posedge Clk) 
begin : BIT_CNT
    if(~Reset_n || (c_state == WAIT_IIC)) 
       bit_count <= 0;
    else if ( c_state == CLK_RISE && cycle_count == TRANSITION_CYCLE)
       bit_count <= bit_count+1;
end    

// Next state block
always @ (posedge Clk) 
begin : NEXT_STATE
    if(~Reset_n)
       c_state <= INIT;
    else 
       c_state <= n_state;
end    

// generate transition for I2C
assign transition = (cycle_count == TRANSITION_CYCLE); 
              
//Next state              
//always @ (*) 
always @ (Reset_n, TFT_iic_xfer, transition, bit_count, write_count,
          c_state, Done) 
begin : I2C_SM_CMB
   case(c_state) 
       //////////////////////////////////////////////////////////////
       //  IDLE STATE
       //////////////////////////////////////////////////////////////
       IDLE: begin
           if(~Reset_n | TFT_iic_xfer) 
             n_state = INIT;
           else 
             n_state = IDLE;
           IIC_xfer_done = 1'b0;

       end
       //////////////////////////////////////////////////////////////
       //  INIT STATE
       //////////////////////////////////////////////////////////////
       INIT: begin
          if (transition) 
            n_state = START;
          else 
            n_state = INIT;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  START STATE
       //////////////////////////////////////////////////////////////
       START: begin
          if( transition) 
            n_state = CLK_FALL;
          else 
            n_state = START;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  CLK_FALL STATE
       //////////////////////////////////////////////////////////////
       CLK_FALL: begin
          if( transition) 
            n_state = SETUP;
          else 
            n_state = CLK_FALL;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  SETUP STATE
       //////////////////////////////////////////////////////////////
       SETUP: begin
          if( transition) 
            n_state = CLK_RISE;
          else 
            n_state = SETUP;
          IIC_xfer_done = 1'b0;
       end
       //////////////////////////////////////////////////////////////
       //  CLK_RISE STATE
       //////////////////////////////////////////////////////////////
       CLK_RISE: begin
          if( transition && bit_count == SDA_BUFFER_MSB) 
            n_state = WAIT_IIC;
          else if (transition )
            n_state = CLK_FALL;  
          else 
            n_state = CLK_RISE;
          IIC_xfer_done = 1'b0;
       end  
       //////////////////////////////////////////////////////////////
       //  WAIT_IIC STATE
       //////////////////////////////////////////////////////////////
       WAIT_IIC: begin
          IIC_xfer_done = 1'b0;          
          if((transition && write_count <= 3'd3))
            begin
              n_state = INIT;
            end
          else if (transition ) 
            begin
              n_state = XFER_DONE;
            end  
          else 
            begin 
              n_state = WAIT_IIC;
            end  
         end 

       //////////////////////////////////////////////////////////////
       //  XFER_DONE STATE
       //////////////////////////////////////////////////////////////
       XFER_DONE: begin
          
          IIC_xfer_done = Done;
          
          if(transition)
              n_state = IDLE;
          else 
              n_state = XFER_DONE;
         end 

       default: n_state = IDLE;


     
   endcase
end


endmodule


// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_v_sync.v   
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_v_sync.v
// Version:         v1.00a
// Description:     This is the VSYNC signal generator.  It generates
//                  the appropriate VSYNC signal for the target TFT display.
//                  The core of this module is a state machine that controls 
//                  4 counters and the VSYNC and V_DE signals.  
//
//                                   
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK           06/10/08    First Version
// ^^^^^^
//        
//         -- Input clock is (~HSYNC)
//         -- Input Rst is vsync_rst signal generated from the h_sync.v module.
//         -- V_DE and H_DE is used to generate DE signal for the TFT display.      
//         -- V_bp_cnt_tc and V_l_cnt_tc are the terminal count for the back 
//         -- porch time counter and Line time counter respectively and are 
//         -- used to generate get_line_start pulse.
// ~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_v_sync(
    Clk,          // Clock 
    Clk_stb,      // Hsync clock strobe
    Rst,          // Reset
    VSYNC,        // Vertical Sync output
    V_DE,         // Vertical Data enable
    V_bp_cnt_tc,  // Vertical back porch terminal count pulse
    V_p_cnt_tc,   // Vertical pulse terminal count 
    V_l_cnt_tc);  // Vertical line terminal count pulse

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
    input         Clk;
    input         Clk_stb;
    input         Rst;     
    output        VSYNC;
    output        V_DE;
    output        V_bp_cnt_tc;
    output        V_p_cnt_tc;
    output        V_l_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
    reg           V_DE;
    reg           VSYNC;
    reg   [0:1]   v_p_cnt;  // 2-bit counter (2   HSYNCs for pulse time)
    reg   [0:4]   v_bp_cnt; // 5-bit counter (31  HSYNCs for back porch time)
    reg   [0:8]   v_l_cnt;  // 9-bit counter (480 HSYNCs for line time)
    reg   [0:3]   v_fp_cnt; // 4-bit counter (12  HSYNCs for front porch time) 
    reg           v_p_cnt_clr;
    reg           v_bp_cnt_clr;
    reg           v_l_cnt_clr;
    reg           v_fp_cnt_clr;
    reg           V_p_cnt_tc;
    reg           V_bp_cnt_tc;
    reg           V_l_cnt_tc;
    reg           v_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

    parameter [0:4] SET_COUNTERS    = 5'b00001;
    parameter [0:4] PULSE           = 5'b00010;
    parameter [0:4] BACK_PORCH      = 5'b00100;
    parameter [0:4] LINE            = 5'b01000;
    parameter [0:4] FRONT_PORCH     = 5'b10000;     

    reg [0:4]       VSYNC_cs;
    reg [0:4]       VSYNC_ns;

///////////////////////////////////////////////////////////////////////////////
// clock enable State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////

    reg clk_stb_d1;
    reg clk_ce_neg;
    reg clk_ce_pos;

    // posedge and negedge of clock strobe
    always @ (posedge Clk)
    begin : CLOCK_STRB_GEN
      clk_stb_d1 <=  Clk_stb;
      clk_ce_pos <=  Clk_stb & ~clk_stb_d1;
      clk_ce_neg <= ~Clk_stb & clk_stb_d1;
    end

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
    always @ (posedge Clk)
    begin : VSYNC_REG_STATE
      if (Rst) 
        VSYNC_cs <= SET_COUNTERS;
      else if (clk_ce_pos) 
        VSYNC_cs <= VSYNC_ns;
    end

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
    always @ (VSYNC_cs or V_p_cnt_tc or V_bp_cnt_tc or V_l_cnt_tc or 
                                                       v_fp_cnt_tc)
    begin : VSYNC_SM_CMB 
      case (VSYNC_cs)
        ///////////////////////////////////////////////////////////////////
        //      SET COUNTERS STATE
        // -- Clear and de-enable all counters on frame_start signal 
        ///////////////////////////////////////////////////////////////////
        SET_COUNTERS: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 1;
          VSYNC        = 1;
          V_DE         = 0;                               
          VSYNC_ns     = PULSE;
        end
        ///////////////////////////////////////////////////////////////////
        //      PULSE STATE
        // -- Enable pulse counter
        // -- De-enable others
        ///////////////////////////////////////////////////////////////////
        PULSE: begin
          v_p_cnt_clr  = 0;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 1;
          VSYNC        = 0;
          V_DE         = 0;
          
          if (V_p_cnt_tc == 0) 
            VSYNC_ns = PULSE;                     
          else 
            VSYNC_ns = BACK_PORCH;
        end
        ///////////////////////////////////////////////////////////////////
        //      BACK PORCH STATE
        // -- Enable back porch counter
        // -- De-enable others
        ///////////////////////////////////////////////////////////////////
        BACK_PORCH: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 0;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 1;
          VSYNC        = 1;
          V_DE         = 0;                               
          
          if (V_bp_cnt_tc == 0) 
            VSYNC_ns = BACK_PORCH;                                                 
          else 
            VSYNC_ns = LINE;
        end
        ///////////////////////////////////////////////////////////////////
        //      LINE STATE
        // -- Enable line counter
        // -- De-enable others
        ///////////////////////////////////////////////////////////////////
        LINE: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 0;
          v_fp_cnt_clr = 1;
          VSYNC        = 1;
          V_DE         = 1;  
          
          if (V_l_cnt_tc == 0) 
            VSYNC_ns = LINE;                                                      
          else 
            VSYNC_ns = FRONT_PORCH;
        end
        ///////////////////////////////////////////////////////////////////
        //      FRONT PORCH STATE
        // -- Enable front porch counter
        // -- De-enable others
        // -- Wraps to PULSE state
        ///////////////////////////////////////////////////////////////////
        FRONT_PORCH: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 0;
          VSYNC        = 1;
          V_DE         = 0;       
          
          if (v_fp_cnt_tc == 0) 
            VSYNC_ns = FRONT_PORCH;                                                
          else 
            VSYNC_ns = PULSE;
        end
        ///////////////////////////////////////////////////////////////////
        //      DEFAULT STATE
        ///////////////////////////////////////////////////////////////////
        // added coverage off to disable the coverage for default state
        // as state machine will never enter in defualt state while doing
        // verification. 
        // coverage off
        default: begin
          v_p_cnt_clr  = 1;
          v_bp_cnt_clr = 1;
          v_l_cnt_clr  = 1;
          v_fp_cnt_clr = 0;
          VSYNC        = 1;      
          V_DE         = 0;
          VSYNC_ns     = SET_COUNTERS;
        end
        // coverage on         
      endcase
    end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Pulse Counter - Counts 2 clocks(~HSYNC) for pulse time                                                                                                                                 
///////////////////////////////////////////////////////////////////////////////
        always @(posedge Clk)
        begin : VSYNC_PULSE_CNTR
          if (Rst || v_p_cnt_clr ) 
            begin
              v_p_cnt <= 2'b0;
              V_p_cnt_tc <= 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_p_cnt == 1) 
                begin
                  v_p_cnt <= v_p_cnt + 1;
                  V_p_cnt_tc <= 1;
                end
              else 
                begin
                  v_p_cnt <= v_p_cnt + 1;
                  V_p_cnt_tc <= 0;
                end
            end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Back Porch Counter - Counts 31 clocks(~HSYNC) for pulse time                                                                   
///////////////////////////////////////////////////////////////////////////////
        always @(posedge Clk)
        begin : VSYNC_BP_CNTR
          if (Rst || v_bp_cnt_clr) 
            begin
              v_bp_cnt <= 5'b0;
              V_bp_cnt_tc <= 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_bp_cnt == 30)
                begin
                  v_bp_cnt <= v_bp_cnt + 1;
                  V_bp_cnt_tc <= 1;
                end
              else 
                begin
                  v_bp_cnt <= v_bp_cnt + 1;
                  V_bp_cnt_tc <= 0;
                end
            end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Line Counter - Counts 480 clocks(~HSYNC) for pulse time                                                                                                                                
///////////////////////////////////////////////////////////////////////////////                                                                                                                                 
        always @(posedge Clk)
        begin : VSYNC_LINE_CNTR
          if (Rst || v_l_cnt_clr) 
            begin
              v_l_cnt <= 9'b0;
              V_l_cnt_tc <= 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_l_cnt == 479)  
                begin
                  v_l_cnt <= v_l_cnt + 1;
                  V_l_cnt_tc <= 1;
                end
              else 
                begin
                  v_l_cnt <= v_l_cnt + 1;
                  V_l_cnt_tc <= 0;
                end
            end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Front Porch Counter - Counts 12 clocks(~HSYNC) for pulse time
///////////////////////////////////////////////////////////////////////////////
        always @(posedge Clk)
        begin : VSYNC_FP_CNTR
          if (Rst || v_fp_cnt_clr) 
            begin
              v_fp_cnt <= 4'b0;
              v_fp_cnt_tc <= 0;
            end
          else if (clk_ce_neg) 
            begin
              if (v_fp_cnt == 11) 
                begin
                  v_fp_cnt <= v_fp_cnt + 1;
                  v_fp_cnt_tc <= 1;
                end
              else 
                begin
                  v_fp_cnt <= v_fp_cnt + 1;
                  v_fp_cnt_tc <= 0;
                end
            end
        end
endmodule



// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_tft_interface.v   
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_tft_interface.vhd
// Version:         v1.00a
// Description:     This module provides external interface(VGA/DVI) to TFT 
//                  Display
//                                   
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK           06/10/08    First Version
// ^^^^^^
//  PVK             08/05/09    v2.00.a
// ^^^^^^^
//  Changed the DDR alignment for ODDR2 for Spartan6 DVI mode.
// ~~~~~~~~~
//  PVK             09/15/09    v2.01.a
// ^^^^^^^
//  Reverted back DDR alignment for ODDR2 for Spartan6 DVI mode. Added 
//  flexibilty for Chrontel Chip configuration through register interface.
// ~~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------


///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_tft_interface (
    TFT_Clk,                // TFT Clock
    TFT_Rst,                // TFT Reset
    TFT_Rst_8s,             // TFT Reset for 8 seriese OSERDESE3
    Bus2IP_Clk,             // Slave Clock
    Bus2IP_Rst,             // Slave Reset
    HSYNC,                  // Hsync input
    VSYNC,                  // Vsync input
    DE,                     // Data Enable
    RED,                    // RED pixel data 
    GREEN,                  // Green pixel data
    BLUE,                   // Blue pixel data
    TFT_HSYNC,              // TFT Hsync
    TFT_VSYNC,              // TFT Vsync
    TFT_DE,                 // TFT data enable
    TFT_VGA_CLK,            // TFT VGA clock
    TFT_VGA_R,              // TFT VGA Red pixel data 
    TFT_VGA_G,              // TFT VGA Green pixel data
    TFT_VGA_B,              // TFT VGA Blue pixel data
    TFT_DVI_CLK_P,          // TFT DVI differential clock
    TFT_DVI_CLK_N,          // TFT DVI differential clock
    TFT_DVI_DATA,           // TFT DVI pixel data
    
    //IIC init state machine for Chrontel CH7301C
    I2C_done,               // I2C configuration done
    TFT_IIC_SCL_I,          // I2C Clock input 
    TFT_IIC_SCL_O,          // I2C Clock output
    TFT_IIC_SCL_T,          // I2C Clock control
    TFT_IIC_SDA_I,          // I2C data input
    TFT_IIC_SDA_O,          // I2C data output 
    TFT_IIC_SDA_T,          // I2C data control
    IIC_xfer_done,          // IIC configuration done
    TFT_iic_xfer,           // IIC configuration request
    TFT_iic_reg_addr,       // IIC register address 
    TFT_iic_reg_data        // IIC register data
);

///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////
    parameter         C_FAMILY         = "virtex7";
    parameter         C_I2C_SLAVE_ADDR = "1110110";
    parameter integer C_TFT_INTERFACE  = 1;
    parameter integer C_IOREG_STYLE    = 1;
    parameter integer C_EN_I2C_INTF    = 1;

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

// Inputs Ports
    input             TFT_Clk;
    input             TFT_Rst;
    input             TFT_Rst_8s;
    input             Bus2IP_Rst;
    input             Bus2IP_Clk;
    input             HSYNC;                          
    input             VSYNC;                          
    input             DE;     
    input    [5:0]    RED;
    input    [5:0]    GREEN;
    input    [5:0]    BLUE;
    
// Output Ports    
    output            TFT_HSYNC;
    output            TFT_VSYNC;
    output            TFT_DE;
    output            TFT_VGA_CLK;
    output   [5:0]    TFT_VGA_R;
    output   [5:0]    TFT_VGA_G;
    output   [5:0]    TFT_VGA_B;
    output            TFT_DVI_CLK_P;
    output            TFT_DVI_CLK_N;
    output   [11:0]   TFT_DVI_DATA;

// I2C Ports
    output            I2C_done;
    input             TFT_IIC_SCL_I;
    output            TFT_IIC_SCL_O;
    output            TFT_IIC_SCL_T;
    input             TFT_IIC_SDA_I;
    output            TFT_IIC_SDA_O;
    output            TFT_IIC_SDA_T;
    output            IIC_xfer_done;
    input             TFT_iic_xfer;
    input  [0:7]      TFT_iic_reg_addr;
    input  [0:7]      TFT_iic_reg_data;


///////////////////////////////////////////////////////////////////////////////
// Implementation
///////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // FDS/FDR COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
    // -- All output to TFT are registered
    ///////////////////////////////////////////////////////////////////////////
    
    // Generate TFT HSYNC
    FDS FDS_HSYNC (.Q(TFT_HSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(HSYNC)); 


    // Generate TFT VSYNC
    FDS FDS_VSYNC (.Q(TFT_VSYNC), 
                   .C(~TFT_Clk), 
                   .S(TFT_Rst), 
                   .D(VSYNC));
                     
    // Generate TFT DE
    FDR FDR_DE    (.Q(TFT_DE),    
                   .C(~TFT_Clk), 
                   .R(TFT_Rst), 
                   .D(DE));

    
      
    generate
      if (C_TFT_INTERFACE == 1) // Selects DVI interface
        begin : gen_dvi_if
        
          wire        tft_iic_sda_t_i;
          wire        tft_iic_scl_t_i;
          wire [11:0] dvi_data_a;
          wire [11:0] dvi_data_b;
          genvar i;


          // Generating 24-bit DVI data
          // from 18-bit RGB
          assign dvi_data_a[0]  = GREEN[2];
          assign dvi_data_a[1]  = GREEN[3];
          assign dvi_data_a[2]  = GREEN[4];
          assign dvi_data_a[3]  = GREEN[5];
          assign dvi_data_a[4]  = 1'b0;
          assign dvi_data_a[5]  = 1'b0;
          assign dvi_data_a[6]  = RED[0];
          assign dvi_data_a[7]  = RED[1];
          assign dvi_data_a[8]  = RED[2];
          assign dvi_data_a[9]  = RED[3];
          assign dvi_data_a[10] = RED[4];
          assign dvi_data_a[11] = RED[5];
          assign dvi_data_b[0]  = 1'b0;
          assign dvi_data_b[1]  = 1'b0;
          assign dvi_data_b[2]  = BLUE[0];
          assign dvi_data_b[3]  = BLUE[1];
          assign dvi_data_b[4]  = BLUE[2];
          assign dvi_data_b[5]  = BLUE[3];
          assign dvi_data_b[6]  = BLUE[4];
          assign dvi_data_b[7]  = BLUE[5];
          assign dvi_data_b[8]  = 1'b0;
          assign dvi_data_b[9]  = 1'b0;
          assign dvi_data_b[10] = GREEN[0];
          assign dvi_data_b[11] = GREEN[1];

          /////////////////////////////////////////////////////////////////////
          // ODDR COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
          // -- All output to TFT are registered
          /////////////////////////////////////////////////////////////////////           


          if (C_IOREG_STYLE == 0)            // Virtex-4 style IO generation
            begin : gen_7s                // Uses ODDR component 
              // DVI Clock P
              ODDR TFT_CLKP_ODDR (.Q(TFT_DVI_CLK_P), 
                                  .C(TFT_Clk), 
                                  .CE(1'b1), 
                                  .R(TFT_Rst), 
                                  .D1(1'b1), 
                                  .D2(1'b0), 
                                  .S(1'b0));
                                  
              // DVI Clock N                    
              ODDR TFT_CLKN_ODDR (.Q(TFT_DVI_CLK_N), 
                                  .C(TFT_Clk), 
                                  .CE(1'b1), 
                                  .R(TFT_Rst), 
                                  .D1(1'b0), 
                                  .D2(1'b1), 
                                  .S(1'b0));

              /////////////////////////////////////////////////////////////////
              // Generate DVI data 
              /////////////////////////////////////////////////////////////////
              for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
         
                ODDR ODDR_TFT_DATA (.Q(TFT_DVI_DATA[i]),  
                                    .C(TFT_Clk), 
                                    .CE(1'b1), 
                                    .R(~DE|TFT_Rst), 
                                    .D2(dvi_data_b[i]),      
                                    .D1(dvi_data_a[i]),  
                                    .S(1'b0));
               end 
            end 
          else if (C_FAMILY == "virtexu" || C_FAMILY == "kintexu" || C_FAMILY == "artixu" || C_FAMILY == "zynqu")
            begin : gen_8s
          OSERDESE3 
        	   #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_CLKP_OSERDESE3 (
                   .CLK (TFT_Clk),
                   .CLKDIV (TFT_Clk),
                   .D (8'b00000011),
                   .OQ (TFT_DVI_CLK_P),
                   .RST (TFT_Rst_8s),
                   .T (1'b0),
                   .T_OUT ());
            
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_CLKN_OSERDESE3 (
                   .CLK (TFT_Clk),
                   .CLKDIV (TFT_Clk),
                   .D (8'b00110000),
                   .OQ (TFT_DVI_CLK_N),
                   .RST (TFT_Rst_8s),
                   .T (1'b0),
                   .T_OUT ());

              for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
         
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_DATA_OSERDESE3 (
                   .CLK (~TFT_Clk),
                   .CLKDIV (~TFT_Clk),
                   .D ({2'b00,dvi_data_a[i],dvi_data_a[i],2'b00,dvi_data_b[i],dvi_data_b[i]}),
                   .OQ (TFT_DVI_DATA[i]),
                   .RST (TFT_Rst),
                   .T (1'b0),
                   .T_OUT ());

               end 

          end else 
            begin : gen_usp
             
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .SIM_DEVICE("ULTRASCALE_PLUS_ES1"),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_CLKP_OSERDESE3 (
                   .CLK (TFT_Clk),
                   .CLKDIV (TFT_Clk),
                   .D (8'b00000011),
                   .OQ (TFT_DVI_CLK_P),
                   .RST (TFT_Rst_8s),
                   .T (1'b0),
                   .T_OUT ());
            
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .SIM_DEVICE("ULTRASCALE_PLUS_ES1"),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_CLKN_OSERDESE3 (
                   .CLK (TFT_Clk),
                   .CLKDIV (TFT_Clk),
                   .D (8'b00110000),
                   .OQ (TFT_DVI_CLK_N),
                   .RST (TFT_Rst_8s),
                   .T (1'b0),
                   .T_OUT ());

              for (i=0;i<12;i=i+1) begin : replicate_tft_dvi_data
         
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .SIM_DEVICE("ULTRASCALE_PLUS_ES1"),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_DATA_OSERDESE3 (
                   .CLK (~TFT_Clk),
                   .CLKDIV (~TFT_Clk),
                   .D ({2'b00,dvi_data_a[i],dvi_data_a[i],2'b00,dvi_data_b[i],dvi_data_b[i]}),
                   .OQ (TFT_DVI_DATA[i]),
                   .RST (TFT_Rst),
                   .T (1'b0),
                   .T_OUT ());

               end 
            
            end 
              /////////////////////////////////////////////////////////////////
                 
            //end        
            
          
          // All TFT ports are grounded
          assign TFT_VGA_CLK = 1'b0;
          assign TFT_VGA_R   = 6'b0;
          assign TFT_VGA_G   = 6'b0;
          assign TFT_VGA_B   = 6'b0;
          
          if (C_EN_I2C_INTF == 1)            // Enable I2C logic for chrontel chip
          begin : EN_I2C
                /////////////////////////////////////////////////////////////////////
                // IIC INIT COMPONENT INSTANTIATION for Chrontel CH-7301
                /////////////////////////////////////////////////////////////////////
                axi_tft_v2_0_16_iic_init 
                  # (.C_I2C_SLAVE_ADDR(C_I2C_SLAVE_ADDR))
                  iic_init
                    (
                      .Clk              (Bus2IP_Clk),
                      .Reset_n          (~Bus2IP_Rst),
                      .SDA              (tft_iic_sda_t_i),
                      .SCL              (tft_iic_scl_t_i),
                      .Done             (I2C_done),
                      .IIC_xfer_done    (IIC_xfer_done),
                      .TFT_iic_xfer     (TFT_iic_xfer),
                      .TFT_iic_reg_addr (TFT_iic_reg_addr),
                      .TFT_iic_reg_data (TFT_iic_reg_data)
                     );
                             
                assign TFT_IIC_SCL_O = 1'b0;
                assign TFT_IIC_SDA_O = 1'b0;
                assign TFT_IIC_SDA_T = tft_iic_sda_t_i ;
                assign TFT_IIC_SCL_T = tft_iic_scl_t_i ;
                /////////////////////////////////////////////////////////////////////
          end else 
          begin : DIS_I2C
                assign I2C_done       = 1'b1;
                assign IIC_xfer_done  = 1'b0;
                assign TFT_IIC_SCL_O  = 1'b0;
                assign TFT_IIC_SDA_O  = 1'b0;
                assign TFT_IIC_SDA_T  = 1'b1;
                assign TFT_IIC_SCL_T  = 1'b1;
          end 
          
           
        end // End DVI Interface 

      else  // Selects VGA Interface

        begin : gen_vga_if
          
          /////////////////////////////////////////////////////////////////////
          // Generate TFT VGA Clock
          /////////////////////////////////////////////////////////////////////
          if (C_IOREG_STYLE == 0)            // Virtex-4 style IO generation
            begin : gen_7s                // Uses ODDR component 
              
              // TFT VGA Clock 
              ODDR TFT_CLK_ODDR   (.Q(TFT_VGA_CLK), 
                                   .C(TFT_Clk), 
                                   .CE(1'b1), 
                                   .R(TFT_Rst), 
                                   .D1(1'b0), 
                                   .D2(1'b1), 
                                   .S(1'b0));
              
            end                              // Spartan3e style IO generation
          else if (C_FAMILY == "virtexu" || C_FAMILY == "kintexu" || C_FAMILY == "artixu" || C_FAMILY == "zynqu")
            begin : gen_8s
             
              // TFT VGA Clock 
              //ODDR2 TFT_CLK_ODDR2 (.Q(TFT_VGA_CLK), 
              //                     .C0(TFT_Clk),
              //                     .C1(~TFT_Clk), 
              //                     .CE(1'b1), 
              //                     .R(TFT_Rst), 
              //                     .D0(1'b0), 
              //                     .D1(1'b1), 
              //                     .S(1'b0));
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_CLK_OSERDESE3 (
                   .CLK (TFT_Clk),
                   .CLKDIV (TFT_Clk),
                   .D (8'b00110000),
                   .OQ (TFT_VGA_CLK),
                   .RST (TFT_Rst_8s),
                   .T (1'b0),
                   .T_OUT ());
            
            end else 
              begin : gen_usp
      //                     .S(1'b0));
             OSERDESE3 
        	 #(
                 .DATA_WIDTH (4),
                 .INIT (0),
                 .IS_CLKDIV_INVERTED (0),
                 .IS_CLK_INVERTED (0),
                 .ODDR_MODE ("TRUE"),
                 .IS_RST_INVERTED (0),
                 .OSERDES_D_BYPASS ("TRUE"),
                 .SIM_DEVICE("ULTRASCALE_PLUS_ES1"),
                 .OSERDES_T_BYPASS ("TRUE"))
                  TFT_CLK_OSERDESE3 (
                   .CLK (TFT_Clk),
                   .CLKDIV (TFT_Clk),
                   .D (8'b00110000),
                   .OQ (TFT_VGA_CLK),
                   .RST (TFT_Rst_8s),
                   .T (1'b0),
                   .T_OUT ());
            


              end


          /////////////////////////////////////////////////////////////////////
          
          
          /////////////////////////////////////////////////////////////////////
          // TFT VGA RGB Data
          //////////////////////////////////////////////////////////////////////
          FDR FDR_R0 (.Q(TFT_VGA_R[0]), .C(~TFT_Clk), .R(TFT_Rst), .D(RED[0]))  ;
          FDR FDR_R1 (.Q(TFT_VGA_R[1]), .C(~TFT_Clk), .R(TFT_Rst), .D(RED[1]))  ;
          FDR FDR_R2 (.Q(TFT_VGA_R[2]), .C(~TFT_Clk), .R(TFT_Rst), .D(RED[2]))  ;
          FDR FDR_R3 (.Q(TFT_VGA_R[3]), .C(~TFT_Clk), .R(TFT_Rst), .D(RED[3]))  ;
          FDR FDR_R4 (.Q(TFT_VGA_R[4]), .C(~TFT_Clk), .R(TFT_Rst), .D(RED[4]))  ;
          FDR FDR_R5 (.Q(TFT_VGA_R[5]), .C(~TFT_Clk), .R(TFT_Rst), .D(RED[5]))  ;
          FDR FDR_G0 (.Q(TFT_VGA_G[0]), .C(~TFT_Clk), .R(TFT_Rst), .D(GREEN[0]));
          FDR FDR_G1 (.Q(TFT_VGA_G[1]), .C(~TFT_Clk), .R(TFT_Rst), .D(GREEN[1]));
          FDR FDR_G2 (.Q(TFT_VGA_G[2]), .C(~TFT_Clk), .R(TFT_Rst), .D(GREEN[2]));
          FDR FDR_G3 (.Q(TFT_VGA_G[3]), .C(~TFT_Clk), .R(TFT_Rst), .D(GREEN[3]));
          FDR FDR_G4 (.Q(TFT_VGA_G[4]), .C(~TFT_Clk), .R(TFT_Rst), .D(GREEN[4]));
          FDR FDR_G5 (.Q(TFT_VGA_G[5]), .C(~TFT_Clk), .R(TFT_Rst), .D(GREEN[5]));
          FDR FDR_B0 (.Q(TFT_VGA_B[0]), .C(~TFT_Clk), .R(TFT_Rst), .D(BLUE[0])) ;
          FDR FDR_B1 (.Q(TFT_VGA_B[1]), .C(~TFT_Clk), .R(TFT_Rst), .D(BLUE[1])) ;
          FDR FDR_B2 (.Q(TFT_VGA_B[2]), .C(~TFT_Clk), .R(TFT_Rst), .D(BLUE[2])) ;
          FDR FDR_B3 (.Q(TFT_VGA_B[3]), .C(~TFT_Clk), .R(TFT_Rst), .D(BLUE[3])) ;
          FDR FDR_B4 (.Q(TFT_VGA_B[4]), .C(~TFT_Clk), .R(TFT_Rst), .D(BLUE[4])) ;
          FDR FDR_B5 (.Q(TFT_VGA_B[5]), .C(~TFT_Clk), .R(TFT_Rst), .D(BLUE[5])) ;
          //////////////////////////////////////////////////////////////////////
          
          // All DVI interface ports are set to default value            
          assign TFT_DVI_CLK_P  = 1'b0; 
          assign TFT_DVI_CLK_N  = 1'b0;
          assign TFT_DVI_DATA   = 12'b0;
          assign I2C_done       = 1'b1;
          assign IIC_xfer_done  = 1'b0;
          assign TFT_IIC_SCL_O  = 1'b0;
          assign TFT_IIC_SDA_O  = 1'b0;
          assign TFT_IIC_SDA_T  = 1'b1;
          assign TFT_IIC_SCL_T  = 1'b1;
        
        
        end // End VGA Interface
    endgenerate    

endmodule


// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_slave_register.v   
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_slave_register.v
// Version:         v1.00a
// Description:     This module contains TFT control register and provides
//                  AXI interface to access those registers.
//                                   
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK           06/10/08    First Version
// ^^^^^^
//    --  Added PLB slave and DCR slave interface to access TFT Registers. 
// ~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

`timescale 1 ps / 1 ps

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_slave_register(
  // AXI Slave Interface
  S_AXI_Clk,          // Slave Interface clock
  S_AXI_Rst,          // Slave Interface reset
  Bus2IP_Data,      // Bus to IP data bus
  Bus2IP_RdCE,      // Bus to IP read chip enable
  Bus2IP_WrCE,      // Bus to IP write chip enable
  Bus2IP_BE,        // Bus to IP byte enable
  IP2Bus_Data,      // IP to Bus data bus
  IP2Bus_RdAck,     // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,     // IP to Bus write transfer acknowledgement
  IP2Bus_Error,     // IP to Bus error response

  // Registers
  TFT_base_addr,    // TFT Base Address reg    
  TFT_dps_reg,      // TFT display scan reg
  TFT_on_reg,       // TFT display on reg
  TFT_intr_en,      // TFT frame complete interrupt enable reg
  TFT_status,       // TFT frame complete status reg
  IIC_xfer_done,    // IIC configuration done
  TFT_iic_xfer,     // IIC configuration request
  TFT_iic_reg_addr, // IIC register address
  TFT_iic_reg_data  // IIC register data
  );


///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////

  parameter [0:63]  C_DEFAULT_TFT_BASE_ADDR  = 0; //"11110000000";
  parameter integer C_SLV_DWIDTH             = 32;
  parameter integer C_SLV_AWIDTH             = 64;
  parameter integer C_NUM_REG                = 6;
  localparam BASE_ADD_LEN = C_SLV_AWIDTH-22;//(C_SLV_AWIDTH == 32) ? 10: 42;
  localparam CONST_ZEROS = (C_SLV_AWIDTH>32)?(C_SLV_AWIDTH-33):0;//(C_SLV_AWIDTH == 32) ? 10: 42;
  localparam CONST_ZEROS_1 = (C_SLV_AWIDTH>32 && C_SLV_AWIDTH<64)?(63-C_SLV_AWIDTH):0;//(C_SLV_AWIDTH == 32) ? 10: 42;
  wire [CONST_ZEROS:0] ALL_ZERO = 'h0;
  wire [0:CONST_ZEROS_1] ALL_ZERO_1 = 'h0;
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
/////////////////////////////////////////////////////////////////////////////// 

  input                         S_AXI_Clk;
  input                         S_AXI_Rst;
  input  [0 : C_SLV_DWIDTH-1]   Bus2IP_Data;
  input  [0 : C_NUM_REG-1]      Bus2IP_RdCE;
  input  [0 : C_NUM_REG-1]      Bus2IP_WrCE;
  input  [0 : C_SLV_DWIDTH/8-1] Bus2IP_BE;
  output [0 : C_SLV_DWIDTH-1]   IP2Bus_Data;
  output                        IP2Bus_RdAck;
  output                        IP2Bus_WrAck;
  output                        IP2Bus_Error;
  output [0:BASE_ADD_LEN]       TFT_base_addr;
  output                        TFT_dps_reg;
  output                        TFT_on_reg;
  output                        TFT_intr_en;
  input                         TFT_status;
  input                         IIC_xfer_done;
  output                        TFT_iic_xfer;
  output [0:7]                  TFT_iic_reg_addr;
  output [0:7]                  TFT_iic_reg_data;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
  reg                           TFT_intr_en;
  reg                           TFT_status_reg;
  reg                           TFT_dps_reg;
  reg                           TFT_on_reg;
  reg  [0:BASE_ADD_LEN]         TFT_base_addr;
  reg  [0:10]                   TFT_base_addr_i;
  reg  [0:C_SLV_DWIDTH-1]       IP2Bus_Data; 
  reg                           tft_status_d1;
  reg                           tft_status_d2;
  reg                           TFT_iic_xfer;
  reg [0:7]                     TFT_iic_reg_addr;
  reg [0:7]                     TFT_iic_reg_data;
  reg                           iic_xfer_done_d1;
  reg                           iic_xfer_done_d2;
  reg                           End_Of_Packet;
///////////////////////////////////////////////////////////////////////////////
// TFT Register Interface 
///////////////////////////////////////////////////////////////////////////////
//---------------------
// Register         DCR  AXI  
//-- AR  - offset - 00 - 00
//-- CR  -        - 01 - 04
//-- ICR -        - 02 - 08
//-- Reserved     - 03 - 0C
//---------------------
//-- TFT Address Register(AR)
//-- BSR bits
//-- bit 0:10  - 11 MSB of Video Memory Address
//-- bit 11:31 - Reserved
//---------------------
//-- TFT Control Register(CR)
//-- BSR bits
//-- bit 0:29  - Reserved
//-- bit 30    - Display scan control bit
//-- bit 31    - TFT Display enable bit
///////////////////////////////////////////////////////////////////////////////
//---------------------
//-- TFT Interrupt Control Register(ICR)
//-- BSR bits
//-- bit 0:27  - Reserved
//-- bit 28    - Interrupt enable bit 
//-- bit 29:30 - Reserved
//-- bit 31    - Frame Complete Status bit
///////////////////////////////////////////////////////////////////////////////

        wire bus2ip_rdce_or;
        wire bus2ip_wrce_or;
        wire bus2ip_rdce_pulse;
        wire bus2ip_wrce_pulse;
        reg  bus2ip_rdce_d1;
        reg  bus2ip_rdce_d2;
        reg  bus2ip_wrce_d1;
        reg  bus2ip_wrce_d2;
        wire word_access; 
        //Ravi reg  [0:31] bus2ip_data_d1;
       
        // oring of bus2ip_rdce and wrce
        localparam [0:0] aw_64 = (C_SLV_AWIDTH == 32)? 1'b0: 1'b1;
        assign bus2ip_rdce_or = Bus2IP_RdCE[0] | Bus2IP_RdCE[1] |
                                Bus2IP_RdCE[2] | Bus2IP_RdCE[3] | ((Bus2IP_RdCE[4] | Bus2IP_RdCE[5]) & aw_64);

        assign bus2ip_wrce_or = Bus2IP_WrCE[0] | Bus2IP_WrCE[1] | 
                                Bus2IP_WrCE[2] | Bus2IP_WrCE[3] | ((Bus2IP_WrCE[4] | Bus2IP_WrCE[5]) & aw_64);

        assign word_access    = (Bus2IP_BE == 4'b1111)? 1'b1 : 1'b0; 
        
        //---------------------------------------------------------------------
        //-- register combinational rdce 
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : REG_CE
          if (S_AXI_Rst)
            begin 
              bus2ip_rdce_d1 <= 1'b0; 
              bus2ip_rdce_d2 <= 1'b0;               
              bus2ip_wrce_d1 <= 1'b0; 
              bus2ip_wrce_d2 <= 1'b0;               
            end
          else 
            begin
              bus2ip_rdce_d1 <= bus2ip_rdce_or; 
              bus2ip_rdce_d2 <= bus2ip_rdce_d1;               
              bus2ip_wrce_d1 <= bus2ip_wrce_or; 
              bus2ip_wrce_d2 <= bus2ip_wrce_d1;               
            end
        end
           
        // generate pulse for bus2ip_rdce & bus2ip_wrce
        assign bus2ip_rdce_pulse = bus2ip_rdce_d1 & ~bus2ip_rdce_d2;
        assign bus2ip_wrce_pulse = bus2ip_wrce_d1 & ~bus2ip_wrce_d2;

        
        //---------------------------------------------------------------------
        //-- Generating the acknowledgement signals
        //---------------------------------------------------------------------
        assign IP2Bus_RdAck = bus2ip_rdce_pulse;
        
        assign IP2Bus_WrAck = bus2ip_wrce_pulse;
        
        assign IP2Bus_Error = ((bus2ip_rdce_pulse | bus2ip_wrce_pulse) && 
                                 (word_access == 1'b0))? 1'b1 : 1'b0;
        //---------------------------------------------------------------------
        //-- flopping BUS2IP_data signal
        //---------------------------------------------------------------------
        //Ravi always @(posedge S_AXI_Clk)
        //Ravi begin : DATA_DELAY
        //Ravi   if (S_AXI_Rst)
        //Ravi     begin 
        //Ravi       bus2ip_data_d1 <= 32'b0; 
        //Ravi     end
        //Ravi   else 
        //Ravi     begin 
        //Ravi       bus2ip_data_d1 <= Bus2IP_Data; 
        //Ravi     end
        //Ravi end
        
        
        //---------------------------------------------------------------------
        //-- Writing to TFT Registers
        //---------------------------------------------------------------------
        // writing AR
 generate
      if (C_SLV_AWIDTH == 32) // When Address width 32
      begin 

        always @(posedge S_AXI_Clk)
        begin : WRITE_AR
          if (S_AXI_Rst)
            begin 
              TFT_base_addr[0:BASE_ADD_LEN] <= C_DEFAULT_TFT_BASE_ADDR[32:42]; 
            end
          else if (Bus2IP_WrCE[0] == 1'b1 & word_access == 1'b1)
            begin
              TFT_base_addr <= Bus2IP_Data[0:10];
              //Ravi TFT_base_addr <= bus2ip_data_d1[0:10];
            end
        end
    end
    else begin

        always @(posedge S_AXI_Clk)
        begin : WRITE_AR_64
          if (S_AXI_Rst)
            begin 
              TFT_base_addr[0:BASE_ADD_LEN] <= C_DEFAULT_TFT_BASE_ADDR[64-C_SLV_AWIDTH:42]; 
              //TFT_base_addr <= C_DEFAULT_TFT_BASE_ADDR[0:BASE_ADD_LEN]; 
              //End_Of_Packet <= 1'b1;
            end
          else if (Bus2IP_WrCE[4] == 1'b1 & word_access == 1'b1)
            begin
              TFT_base_addr[CONST_ZEROS+1:BASE_ADD_LEN] <= Bus2IP_Data[0:10];
              //TFT_base_addr[0:10] <= Bus2IP_Data[0:10];
            end
          else if (Bus2IP_WrCE[5] == 1'b1 & word_access == 1'b1)
            begin
              TFT_base_addr[0:CONST_ZEROS] <= Bus2IP_Data[64-C_SLV_AWIDTH:31];//,TFT_base_addr[0:10]};
              //TFT_base_addr[11:BASE_ADD_LEN] <= Bus2IP_Data[64-C_SLV_AWIDTH:31];//,TFT_base_addr[0:10]};
            end
        end

    end
endgenerate

        //---------------------------------------------------------------------
        // Writing CR
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_CR
          if (S_AXI_Rst)
            begin 
              TFT_dps_reg   <= 1'b0; 
              TFT_on_reg    <= 1'b1; 
            end
          else if (Bus2IP_WrCE[1] == 1'b1 & word_access == 1'b1)
            begin
              TFT_dps_reg   <= Bus2IP_Data[30]; 
              //Ravi TFT_dps_reg   <= bus2ip_data_d1[30]; 
              TFT_on_reg    <= Bus2IP_Data[31]; 
              //Ravi TFT_on_reg    <= bus2ip_data_d1[31]; 
            end
        end
        

        //---------------------------------------------------------------------
        // Writing ICR - Interrupt Enable
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_ICR_IE
          if (S_AXI_Rst)
            begin 
              TFT_intr_en     <= 1'b0; 
            end
          else if (Bus2IP_WrCE[2] == 1'b1 & word_access == 1'b1)
            begin
              TFT_intr_en     <= Bus2IP_Data[28]; 
              //Ravi TFT_intr_en     <= bus2ip_data_d1[28]; 
            end
        end

        //---------------------------------------------------------------------
        // Writing ICR - Frame Complete status 
        // For polled mode operation
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_ICR_STAT
          if (S_AXI_Rst)
            begin 
              TFT_status_reg  <= 1'b0; 
            end
          else if (Bus2IP_WrCE[0] == 1'b1 & word_access == 1'b1)
            begin
              TFT_status_reg  <= 1'b0; 
            end
          else if (Bus2IP_WrCE[2] == 1'b1 & word_access == 1'b1)
            begin
              TFT_status_reg  <= Bus2IP_Data[31]; 
              //Ravi TFT_status_reg  <= bus2ip_data_d1[31]; 
            end
          else if (tft_status_d2 == 1'b1)
            begin
              TFT_status_reg  <= 1'b1; 
            end
  
        end


        //---------------------------------------------------------------------
        // Writing IICR - IIC Register
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_IICR
          if (S_AXI_Rst)
            begin 
              TFT_iic_reg_addr <= 8'b0;
              TFT_iic_reg_data <= 8'b0;
            end
          else if (Bus2IP_WrCE[3] == 1'b1 & word_access == 1'b1)
            begin
              TFT_iic_reg_addr  <= Bus2IP_Data[16:23]; 
              //Ravi TFT_iic_reg_addr  <= bus2ip_data_d1[16:23]; 
              TFT_iic_reg_data  <= Bus2IP_Data[24:31]; 
              //Ravi TFT_iic_reg_data  <= bus2ip_data_d1[24:31]; 
            end
        end


        //---------------------------------------------------------------------
        // Writing IICR - XFER Register
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : WRITE_XFER
          if (S_AXI_Rst)
            begin 
              TFT_iic_xfer  <= 1'b0; 
            end
          else if (Bus2IP_WrCE[3] == 1'b1 & word_access == 1'b1)
            begin
              TFT_iic_xfer  <= Bus2IP_Data[0]; 
              //Ravi TFT_iic_xfer  <= bus2ip_data_d1[0]; 
            end
          else if (iic_xfer_done_d2 == 1'b1)
            begin
              TFT_iic_xfer  <= 1'b0; 
            end
        end

        //---------------------------------------------------------------------
        // Synchronize the IIC_xfer_done signal w.r.t. S_AXI_CLK
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : IIC_XFER_DONE_AXI_SYNC
          if (S_AXI_Rst)
            begin 
              iic_xfer_done_d1 <= 1'b0;
              iic_xfer_done_d2 <= 1'b0;
            end
          else
            begin
              iic_xfer_done_d1 <= IIC_xfer_done;
              iic_xfer_done_d2 <= iic_xfer_done_d1;
            end  
        end

        //---------------------------------------------------------------------
        // Synchronize the vsync_intr signal w.r.t. S_AXI_CLK
        //---------------------------------------------------------------------
        always @(posedge S_AXI_Clk)
        begin : VSYNC_INTR_AXI_SYNC
          if (S_AXI_Rst)
            begin 
              tft_status_d1 <= 1'b0;
              tft_status_d2 <= 1'b0;
            end
          else
            begin
              tft_status_d1 <= TFT_status;
              tft_status_d2 <= tft_status_d1;
            end  
        end

        
        //---------------------------------------------------------------------
        //-- Reading from TFT Registers
        //-- Bus2IP_RdCE[0] == AR
        //-- Bus2IP_RdCE[1] == CR
        //-- Bus2IP_RdCE[2] == ICR
        //-- Bus2IP_RdCE[3] == Reserved
        //---------------------------------------------------------------------
generate
      if (C_SLV_AWIDTH == 32) // When Address width 32
      begin 
always @(posedge S_AXI_Clk)
        begin : READ_REG
          
          
          if (S_AXI_Rst | ~word_access ) 
            begin 
              IP2Bus_Data[0:27]  <= 28'b0;
              IP2Bus_Data[28:31] <= 4'b0;
            end
          else if (Bus2IP_RdCE[0] == 1'b1)
            begin
              IP2Bus_Data[0:10]  <= TFT_base_addr;
              IP2Bus_Data[11:31] <= 20'b0;
            end
          else if (Bus2IP_RdCE[1] == 1'b1)
            begin
              IP2Bus_Data[0:29]  <= 30'b0;
              IP2Bus_Data[30]    <= TFT_dps_reg; 
              IP2Bus_Data[31]    <= TFT_on_reg;
            end
          else if (Bus2IP_RdCE[2] == 1'b1)
            begin
              IP2Bus_Data[0:27]  <= 28'b0;
              IP2Bus_Data[28]    <= TFT_intr_en;
              IP2Bus_Data[29:30] <= 2'b0;
              IP2Bus_Data[31]    <= TFT_status_reg; 
            end
          else if (Bus2IP_RdCE[3] == 1'b1)
            begin
              IP2Bus_Data[0]     <= TFT_iic_xfer;
              IP2Bus_Data[1: 15] <= 15'b0;
              IP2Bus_Data[16:23] <= TFT_iic_reg_addr;
              IP2Bus_Data[24:31] <= TFT_iic_reg_data; 
            end
           else 
            begin
              IP2Bus_Data  <= 32'b0;
            end
        end

      end
  endgenerate


    generate
      if (C_SLV_AWIDTH > 32) // When Address width 32
      begin 
        always @(posedge S_AXI_Clk)
        begin : READ_REG_64
          if (S_AXI_Rst | ~word_access ) 
            begin 
              IP2Bus_Data[0:27]  <= 28'b0;
              IP2Bus_Data[28:31] <= 4'b0;
            end
          else if (Bus2IP_RdCE[1] == 1'b1)
            begin
              IP2Bus_Data[0:29]  <= 30'b0;
              IP2Bus_Data[30]    <= TFT_dps_reg; 
              IP2Bus_Data[31]    <= TFT_on_reg;
            end
          else if (Bus2IP_RdCE[2] == 1'b1)
            begin
              IP2Bus_Data[0:27]  <= 28'b0;
              IP2Bus_Data[28]    <= TFT_intr_en;
              IP2Bus_Data[29:30] <= 2'b0;
              IP2Bus_Data[31]    <= TFT_status_reg; 
            end
          else if (Bus2IP_RdCE[3] == 1'b1)
            begin
              IP2Bus_Data[0]     <= TFT_iic_xfer;
              IP2Bus_Data[1: 15] <= 15'b0;
              IP2Bus_Data[16:23] <= TFT_iic_reg_addr;
              IP2Bus_Data[24:31] <= TFT_iic_reg_data; 
            end
           else if (Bus2IP_RdCE[4] == 1'b1)
            begin
              //IP2Bus_Data[0:10]  <= TFT_base_addr[0:10];
              IP2Bus_Data[0:10]  <= TFT_base_addr[BASE_ADD_LEN-10:BASE_ADD_LEN];
              IP2Bus_Data[11:31] <= 20'b0;
            end
          else if (Bus2IP_RdCE[5] == 1'b1)
            begin
             if(C_SLV_AWIDTH < 64) begin
              IP2Bus_Data[CONST_ZEROS_1+1:31]  <= TFT_base_addr[0:BASE_ADD_LEN-11];
              IP2Bus_Data[0:CONST_ZEROS_1] <= ALL_ZERO_1;
             end
             else
              IP2Bus_Data[CONST_ZEROS_1:31]  <= TFT_base_addr[0:BASE_ADD_LEN-11];

              //IP2Bus_Data[0:BASE_ADD_LEN-11]  <= TFT_base_addr[0:BASE_ADD_LEN-11];
            end
            else 
            begin
              IP2Bus_Data  <= 32'b0;
            end
        end
    end
  endgenerate

        
endmodule




// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_line_buffer.v  
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_line_buffer.v
// Version:         v1.00.a
// Description:     
//
//    -- This module contains 1 RAMB16_S18_S36 for line storage.
//    -- The RGB BRAMs hold one line of the 480 lines required for 640x480
//       resolution.
//    -- Data is written to the PORT B of the BRAM by the AXI bus.
//    -- Data is read from the  PORT A of the BRAM by the TFT 
//
//                                   
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK          06/10/08    First Version
// ^^^^^^
//        
//  TFT READ LOGIC    
//    -- BRAM_TFT_rd is generated two clock cycles early wrt DE      
//    -- BRAM_TFT_oe is generated one clock cycles early wrt DE
//    -- These two signals control the TFT side read from BRAM to HW
//  AXI WRITE LOGIC
//    -- BRAM Write Enables and Data are controlled by the tft_controller.v
//    -- module.  
// ~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------


///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_line_buffer
    #( parameter C_FAMILY = "Viretex7"
    )
    (


  // BRAM_TFT READ PORT A clock and reset
  TFT_Clk,           // TFT Clock 
  TFT_Rst,           // TFT Reset

  // AXI_BRAM WRITE PORT B clock and reset
  AXI_Clk,           // AXI Clock
  AXI_Rst,           // AXI Reset

  // BRAM_TFT READ Control
  BRAM_TFT_rd,       // TFT BRAM read   
  BRAM_TFT_oe,       // TFT BRAM output enable  

  // AXI_BRAM Write Control
  AXI_BRAM_data,     // AXI BRAM Data
  AXI_BRAM_we,       // AXI BRAM write enable

  // RGB Outputs
  RED,               // TFT Red pixel data  
  GREEN,             // TFT Green pixel data  
  BLUE               // TFT Blue pixel data  
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

  input        TFT_Clk;
  input        TFT_Rst;
  input        AXI_Clk;
  input        AXI_Rst;
  input        BRAM_TFT_rd;
  input        BRAM_TFT_oe;
  input [0:63] AXI_BRAM_data;
  input        AXI_BRAM_we;
  output [5:0] RED,GREEN,BLUE;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
  
  reg [5:0]  BRAM_TFT_R_data;
  reg [5:0]  BRAM_TFT_G_data;
  reg [5:0]  BRAM_TFT_B_data;  
  reg  [0:9]  BRAM_TFT_addr;
  reg  [0:8]  BRAAXI_addr;
  wire [35:0] fifo_out_data;
  reg         tc;
  reg  [5:0]  RED,GREEN,BLUE;

///////////////////////////////////////////////////////////////////////////////
// READ Logic BRAM Address Generator TFT Side
///////////////////////////////////////////////////////////////////////////////

  // BRAM_TFT_addr Counter (0-639d)
  always @(posedge TFT_Clk)
  begin : TFT_ADDR_CNTR
    if (TFT_Rst | ~BRAM_TFT_rd) 
      begin
        BRAM_TFT_addr <= 10'b0;
        tc <= 1'b0;
      end
    else 
      begin
        if (tc == 0) 
          begin
            if (BRAM_TFT_addr == 10'd639) 
              begin
                BRAM_TFT_addr <= 10'b0;
                tc <= 1'b1;
              end
            else 
              begin
                BRAM_TFT_addr <= BRAM_TFT_addr + 1;
                tc <= 1'b0;
              end
          end
      end
  end

///////////////////////////////////////////////////////////////////////////////
// WRITE Logic for the BRAM AXI Side
///////////////////////////////////////////////////////////////////////////////

  // BRAAXI_addr Counter (0-319d)
  always @(posedge AXI_Clk)
  begin : AXI_ADDR_CNTR
    if (AXI_Rst) 
      begin
        BRAAXI_addr <= 9'b0;
      end
    else 
      begin
        if (AXI_BRAM_we) 
          begin
            if (BRAAXI_addr == 9'd319) 
              begin
                BRAAXI_addr <= 9'b0;
              end
            else 
              begin
                BRAAXI_addr <= BRAAXI_addr + 1;
              end
          end
      end
  end

///////////////////////////////////////////////////////////////////////////////
// BRAM
///////////////////////////////////////////////////////////////////////////////

 async_fifo_fg 
  #(
        .C_ALLOW_2N_DEPTH   (1),// : Integer := 0;  -- New paramter to leverage FIFO Gen 2**N depth
        .C_FAMILY           (C_FAMILY),// : String  := "virtex5";  -- new for FIFO Gen
        .C_DATA_WIDTH       (36),// : integer := 16;
        .C_ENABLE_RLOCS     (0),// : integer := 0 ;  -- not supported in FG
        .C_FIFO_DEPTH       (512),// : integer := 15;
        .C_HAS_ALMOST_EMPTY (1),// : integer := 1 ;
        .C_HAS_ALMOST_FULL  (1),// : integer := 1 ;
        .C_HAS_RD_ACK       (1),// : integer := 0 ;
        .C_HAS_RD_COUNT     (1),// : integer := 1 ;
        .C_HAS_RD_ERR       (1),// : integer := 0 ;
        .C_HAS_WR_ACK       (1),// : integer := 0 ;
        .C_HAS_WR_COUNT     (1),// : integer := 1 ;
        .C_HAS_WR_ERR       (1),// : integer := 0 ;
        .C_RD_ACK_LOW       (0),// : integer := 0 ;
        .C_RD_COUNT_WIDTH   (9),// : integer := 3 ;
        .C_RD_ERR_LOW       (0),// : integer := 0 ;
        .C_USE_EMBEDDED_REG (0),// : integer := 0 ;  -- Valid only for BRAM based FIFO, otherwise needs to be set to 0
        .C_PRELOAD_REGS     (1),// : integer := 0 ;   
        .C_PRELOAD_LATENCY  (0),// : integer := 1 ;  -- needs to be set 2 when C_USE_EMBEDDED_REG = 1 
        .C_USE_BLOCKMEM     (1),// : integer := 1 ;  -- 0 = distributed RAM, 1 = BRAM
        .C_WR_ACK_LOW       (0),// : integer := 0 ;
        .C_EN_SAFETY_CKT    (1),// : As we have an asynchronous reset,enabling safety circuit   
        .C_WR_COUNT_WIDTH   (9),// : integer := 3 ;
        .C_WR_ERR_LOW       (0) // : integer := 0   
    )
    RAM (
        .Din            ({AXI_BRAM_data[40:45], AXI_BRAM_data[48:53], AXI_BRAM_data[56:61],     //AXI_BRAM_data), //: in std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
                          AXI_BRAM_data[8:13],  AXI_BRAM_data[16:21], AXI_BRAM_data[24:29]}),
        .Wr_en          (AXI_BRAM_we), //: in std_logic := '1';
        .Wr_clk         (AXI_Clk), //: in std_logic := '1';
        .Rd_en          (BRAM_TFT_addr[9]), //: in std_logic := '0';
        .Rd_clk         (TFT_Clk), //: in std_logic := '1';
        .Ainit          (TFT_Rst ), //: in std_logic := '1';   
        .Dout           (fifo_out_data), //: out std_logic_vector(C_DATA_WIDTH-1 downto 0);
        .Full           (), //: out std_logic; 
        .Empty          (), //: out std_logic; 
        .Almost_full    (), //: out std_logic;  
        .Almost_empty   (), //: out std_logic;  
        .Wr_count       (), //: out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
        .Rd_count       (), //: out std_logic_vector(C_RD_COUNT_WIDTH-1 downto 0);
        .Rd_ack         (), //: out std_logic;
        .Rd_err         (), //: out std_logic;
        .Wr_ack         (), //: out std_logic;
        .Wr_err         () //: out std_logic
    );


  always @(posedge TFT_Clk)
  begin
      if(TFT_Rst) begin
          BRAM_TFT_R_data <= 6'd0;
          BRAM_TFT_G_data <= 6'd0;
          BRAM_TFT_B_data <= 6'd0;
      end else begin
        if(BRAM_TFT_addr[9]) begin
            BRAM_TFT_R_data <= fifo_out_data[35:30];  //40:45];
            BRAM_TFT_G_data <= fifo_out_data[29:24];  //48:53];
            BRAM_TFT_B_data <= fifo_out_data[23:18];  //56:61];
        end else begin
            BRAM_TFT_R_data <= fifo_out_data[17:12];  //8:13]; 
            BRAM_TFT_G_data <= fifo_out_data[11:6];   //16:21];
            BRAM_TFT_B_data <= fifo_out_data[5:0];    //24:29];
        end
     end
  end
///////////////////////////////////////////////////////////////////////////////
// Register RGB BRAM output data
///////////////////////////////////////////////////////////////////////////////
  always @(posedge TFT_Clk)
  begin : BRAM_OUT_DATA 
    if (TFT_Rst | ~BRAM_TFT_oe)
      begin
        RED   <= 6'b0;
        GREEN <= 6'b0;
        BLUE  <= 6'b0; 
      end
    else
      begin
        RED   <= BRAM_TFT_R_data;
        GREEN <= BRAM_TFT_G_data;
        BLUE  <= BRAM_TFT_B_data;
      end
   end   
   

endmodule



// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_h_sync.v   
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_h_sync.v
// Version:         v2.01a
// Description:     This is the HSYNC signal generator.  It generates the 
//                  appropriate HSYNC signal for the target TFT display.  
//                  The core of this module is a state machine that controls 
//                  4 counters and the HSYNC and H_DE signals.  
//
//                                   
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK           06/10/08    First Version
// ^^^^^^
//        
//    -- Input clock is SYS_TFT_Clk
//    -- H_DE is anded with V_DE to generate DE signal for the TFT display.    
//    -- H_bp_cnt_tc, H_bp_cnt_tc2, H_pix_cnt_tc, H_pix_cnt_tc2 are used to 
//    -- generate read and output enable signals for the tft side of the BRAM.
// ~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_h_sync(
    Clk,                    // Clock      
    Rst,                    // Reset
    HSYNC,                  // Horizontal Sync
    H_DE,                   // Horizontal Data enable
    VSYNC_Rst,              // Vsync reset
    H_bp_cnt_tc,            // Horizontal back porch terminal count delayed
    H_bp_cnt_tc2,           // Horizontal back porch terminal count 
    H_pix_cnt_tc,           // Horizontal pixel data terminal count delayed
    H_pix_cnt_tc2           // Horizontal pixel data terminal count
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
    input         Clk;
    input         Rst;
    output        VSYNC_Rst;
    output        HSYNC;
    output        H_DE;
    output        H_bp_cnt_tc;
    output        H_bp_cnt_tc2;
    output        H_pix_cnt_tc;
    output        H_pix_cnt_tc2; 

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
    reg           VSYNC_Rst;
    reg           HSYNC;
    reg           H_DE;
    reg [0:6]     h_p_cnt;    // 7-bit  counter (96 clocks for pulse time)
    reg [0:5]     h_bp_cnt;   // 6-bit  counter (48 clocks for back porch time)
    reg [0:10]    h_pix_cnt;  // 11-bit counter (640 clocks for pixel time)
    reg [0:3]     h_fp_cnt;  // 4-bit  counter (16 clocks fof front porch time)
    reg           h_p_cnt_clr;
    reg           h_bp_cnt_clr;
    reg           h_pix_cnt_clr;
    reg           h_fp_cnt_clr;
    reg           h_p_cnt_tc;
    reg           H_bp_cnt_tc;
    reg           H_bp_cnt_tc2;
    reg           H_pix_cnt_tc;
    reg           H_pix_cnt_tc2;
    reg           h_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

    parameter [0:4] SET_COUNTERS = 5'b00001;
    parameter [0:4] PULSE        = 5'b00010;
    parameter [0:4] BACK_PORCH   = 5'b00100;
    parameter [0:4] PIXEL        = 5'b01000;
    parameter [0:4] FRONT_PORCH  = 5'b10000;

    reg [0:4]       HSYNC_cs;
    reg [0:4]       HSYNC_ns;
    
 
///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
    always @(posedge Clk) 
    begin : HSYNC_REG_STATE
      if (Rst) 
        begin
          HSYNC_cs  <= SET_COUNTERS;
          VSYNC_Rst <= 1;
        end
      else 
        begin
          HSYNC_cs  <= HSYNC_ns;
          VSYNC_Rst <= 0;
        end
    end

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
    always @(HSYNC_cs or h_p_cnt_tc or H_bp_cnt_tc or H_pix_cnt_tc 
             or h_fp_cnt_tc) 
    begin : HSYNC_SM_CMB
       case (HSYNC_cs)
         //////////////////////////////////////////////////////////////
         //      SET COUNTERS STATE
         //////////////////////////////////////////////////////////////
         SET_COUNTERS: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 0;
           HSYNC_ns      = PULSE;
         end
         //////////////////////////////////////////////////////////////
         //      PULSE STATE
         // -- Enable pulse counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         PULSE: begin
           h_p_cnt_clr   = 0;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 0;
           H_DE          = 0;
           
           if (h_p_cnt_tc == 0) 
             HSYNC_ns = PULSE;                     
           else 
             HSYNC_ns = BACK_PORCH;
         end
         //////////////////////////////////////////////////////////////
         //      BACK PORCH STATE
         // -- Enable back porch counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         BACK_PORCH: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 0;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 0;
           
           if (H_bp_cnt_tc == 0) 
             HSYNC_ns = BACK_PORCH;                                            
           else 
             HSYNC_ns = PIXEL;
         end
         //////////////////////////////////////////////////////////////
         //      PIXEL STATE
         // -- Enable pixel counter
         // -- De-enable others
         //////////////////////////////////////////////////////////////
         PIXEL: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 0;
           h_fp_cnt_clr  = 1;
           HSYNC         = 1;
           H_DE          = 1;
           
           if (H_pix_cnt_tc == 0) 
             HSYNC_ns = PIXEL;                                                
           else 
             HSYNC_ns = FRONT_PORCH;
         end
         //////////////////////////////////////////////////////////////
         //      FRONT PORCH STATE
         // -- Enable front porch counter
         // -- De-enable others
         // -- Wraps to PULSE state
         //////////////////////////////////////////////////////////////
         FRONT_PORCH: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 0;
           HSYNC         = 1;      
           H_DE          = 0;
           
           if (h_fp_cnt_tc == 0) 
             HSYNC_ns = FRONT_PORCH;                                           
           else 
             HSYNC_ns = PULSE;
         end
         //////////////////////////////////////////////////////////////
         //      DEFAULT STATE
         //////////////////////////////////////////////////////////////
         // added coverage off to disable the coverage for default state
         // as state machine will never enter in defualt state while doing
         // verification. 
         // coverage off
         default: begin
           h_p_cnt_clr   = 1;
           h_bp_cnt_clr  = 1;
           h_pix_cnt_clr = 1;
           h_fp_cnt_clr  = 0;
           HSYNC         = 1;      
           H_DE          = 0;
           HSYNC_ns      = SET_COUNTERS;
         end
         // coverage on 
           
       endcase
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pulse Counter - Counts 96 clocks for pulse time                                                                                                                              
///////////////////////////////////////////////////////////////////////////////
    always @(posedge Clk)
    begin : HSYNC_PULSE_CNT
      if (Rst || h_p_cnt_clr) 
        begin
          h_p_cnt <= 7'b0;
          h_p_cnt_tc <= 0;
        end
      else 
        begin
          if (h_p_cnt == 94) 
            begin
              h_p_cnt <= h_p_cnt + 1;
              h_p_cnt_tc <= 1;
            end
          else 
            begin
              h_p_cnt <= h_p_cnt + 1;
              h_p_cnt_tc <= 0;
            end
        end
    end
///////////////////////////////////////////////////////////////////////////////
//      Horizontal Back Porch Counter - Counts 48 clocks for back porch time                                                                    
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Clk )
    begin : HSYNC_BP_CNTR
      if (Rst || h_bp_cnt_clr) 
        begin
          h_bp_cnt <= 6'b0;
          H_bp_cnt_tc <= 0;
          H_bp_cnt_tc2 <= 0;
        end
      else 
        begin
          if (h_bp_cnt == 45) 
            begin
              h_bp_cnt <= h_bp_cnt + 1;
              H_bp_cnt_tc2 <= 1;
              H_bp_cnt_tc <= 0;
            end
          else if (h_bp_cnt == 46) 
            begin
              h_bp_cnt <= h_bp_cnt + 1;
              H_bp_cnt_tc <= 1;
              H_bp_cnt_tc2 <= 0;
            end
          else 
            begin
              h_bp_cnt <= h_bp_cnt + 1;
              H_bp_cnt_tc <= 0;
              H_bp_cnt_tc2 <= 0;
            end
        end
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pixel Counter - Counts 640 clocks for pixel time                                                                                                                     
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Clk)
    begin : HSYNC_PIX_CNTR
        if (Rst || h_pix_cnt_clr) 
          begin
            h_pix_cnt <= 11'b0;
            H_pix_cnt_tc <= 0;
            H_pix_cnt_tc2 <= 0;
          end
        else 
          begin
            if (h_pix_cnt == 637) 
              begin
                h_pix_cnt <= h_pix_cnt + 1;
                H_pix_cnt_tc2 <= 1;
              end
            else if (h_pix_cnt == 638) 
              begin
                h_pix_cnt <= h_pix_cnt + 1;
                H_pix_cnt_tc <= 1;
              end
            else 
              begin
                h_pix_cnt <= h_pix_cnt + 1;
                H_pix_cnt_tc <= 0;
                H_pix_cnt_tc2 <= 0;
              end
            end
    end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Front Porch Counter - Counts 16 clocks for front porch time
///////////////////////////////////////////////////////////////////////////////                 
    always @(posedge Clk)
    begin : HSYNC_FP_CNTR
        if (Rst || h_fp_cnt_clr) 
            begin
            h_fp_cnt <= 5'b0;
            h_fp_cnt_tc <= 0;
            end
        else 
            begin
                if (h_fp_cnt == 14) 
                    begin
                    h_fp_cnt <= h_fp_cnt + 1;
                    h_fp_cnt_tc <= 1;
                    end
                else 
                    begin
                    h_fp_cnt <= h_fp_cnt + 1;
                    h_fp_cnt_tc <= 0;
                    end
            end
    end
endmodule


// --------------------------------------------------------------------
// -- (c) Copyright 1984 - 2012 Xilinx, Inc. All rights reserved.	 --
// --		                                						 --
// -- This file contains confidential and proprietary information	 --
// -- of Xilinx, Inc. and is protected under U.S. and	        	 --
// -- international copyright and other intellectual property    	 --
// -- laws.							                                 --
// --								                                 --
// -- DISCLAIMER							                         --
// -- This disclaimer is not a license and does not grant any	     --
// -- rights to the materials distributed herewith. Except as	     --
// -- otherwise provided in a valid license issued to you by	     --
// -- Xilinx, and to the maximum extent permitted by applicable	     --
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND	     --
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES	 --
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING	     --
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-	     --
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and	     --
// -- (2) Xilinx shall not be liable (whether in contract or tort,	 --
// -- including negligence, or under any other theory of		     --
// -- liability) for any loss or damage of any kind or nature	     --
// -- related to, arising under or in connection with these	         --
// -- materials, including for any direct, or any indirect,	         --
// -- special, incidental, or consequential loss or damage		     --
// -- (including loss of data, profits, goodwill, or any type of	 --
// -- loss or damage suffered as a result of any action brought	     --
// -- by a third party) even if such damage or loss was		         --
// -- reasonably foreseeable or Xilinx had been advised of the	     --
// -- possibility of the same.					                     --
// --								                                 --
// -- CRITICAL APPLICATIONS					                         --
// -- Xilinx products are not designed or intended to be fail-	     --
// -- safe, or for use in any application requiring fail-safe	     --
// -- performance, such as life-support or safety devices or	     --
// -- systems, Class III medical devices, nuclear facilities,	     --
// -- applications related to the deployment of airbags, or any	     --
// -- other applications that could lead to death, personal	         --
// -- injury, or severe property or environmental damage		     --
// -- (individually and collectively, "Critical			             --
// -- Applications"). Customer assumes the sole risk and		     --
// -- liability of any use of Xilinx products in Critical		     --
// -- Applications, subject only to applicable laws and	  	         --
// -- regulations governing limitations on product liability.	     --
// --								                                 --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS	     --
// -- PART OF THIS FILE AT ALL TIMES. 				                 --
// --------------------------------------------------------------------
//-----------------------------------------------------------------------------
// axi_tft_v2_0_16_tft_controller.v   
//-----------------------------------------------------------------------------
// Filename:        axi_tft_v2_0_16_tft_controller.vhd
// Version:         v1.00.a
// Description:     This is top level file for TFT controller. 
//                  This module generate the read request to the Video memory.
//                  It also generates the write request on the line buffer to
//                  store video data line.
//
// Verilog-Standard:   Verilog'2001
//-----------------------------------------------------------------------------
// Structure:   
//                  axi_tft.vhd
//                     -- axi_master_burst.vhd               
//                     -- axi_lite_ipif.vhd
//                     -- tft_controller.v
//                            -- line_buffer.v
//                            -- v_sync.v
//                            -- h_sync.v
//                            -- slave_register.v
//                            -- tft_interface.v
//                                -- iic_init.v
//-----------------------------------------------------------------------------
// Author:          PVK
// History:
//   PVK           06/10/08    First Version
// ^^^^^^
//  PVK             09/15/09    v2.01.a
// ^^^^^^^
//  Reverted back the changes made for S6 DVI mode. Added flexibilty for 
//  Chrontel Chip configuration through register interface.
// ~~~~~~~~~
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps
(* DowngradeIPIdentifiedWarnings="yes" *)
module axi_tft_v2_0_16_tft_controller(
                                            
  // TFT Interface  
  SYS_TFT_Clk,                // TFT Input Clock
  TFT_HSYNC,                  // TFT Horizontal Sync    
  TFT_VSYNC,                  // TFT Vertical Sync
  TFT_DE,                     // TFT Data Enable
  TFT_DPS,                    // TFT Display scan 
  TFT_VGA_CLK,                // TFT VGA Clock
  TFT_VGA_R,                  // TFT VGA Red data 
  TFT_VGA_G,                  // TFT VGA Green data 
  TFT_VGA_B,                  // TFT VGA Blue data
  TFT_DVI_CLK_P,              // TFT DVI differential clock
  TFT_DVI_CLK_N,              // TFT DVI differential clock
  TFT_DVI_DATA,               // TFT DVI DATA

  //IIC Interface for Chrontel CH7301C
  TFT_IIC_SCL_I,              // I2C clock input 
  TFT_IIC_SCL_O,              // I2C clock output
  TFT_IIC_SCL_T,              // I2C clock control
  TFT_IIC_SDA_I,              // I2C data input
  TFT_IIC_SDA_O,              // I2C data output 
  TFT_IIC_SDA_T,              // I2C data control
  
  // Slave Interface
  S_AXI_Clk,                   // Slave Interface clock
  S_AXI_Rst,                   // Slave Interface reset
  Bus2IP_Data,                // Bus to IP data bus
  Bus2IP_RdCE,                // Bus to IP read chip enable
  Bus2IP_WrCE,                // Bus to IP write chip enable
  Bus2IP_BE,                  // Bus to IP byte enable     
  IP2Bus_Data,                // IP to Bus data bus
  IP2Bus_RdAck,               // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,               // IP to Bus write transfer acknowledgement
  IP2Bus_Error,               // IP to Bus error response

  // Interrupt
  IP2INTC_Irpt,               // Frame complete interrupt

  // Master Interface
  M_AXI_Clk,                   // Master Interface clock 
  M_AXI_Rst,                   // Master Interface reset
  IP2Bus_MstRd_Req,           // IP to Bus master read request
  IP2Bus_Mst_Addr,            // IP to Bus master address bus
  IP2Bus_Mst_BE,              // IP to Bus master byte enables
  IP2Bus_Mst_Length,          // IP to Bus master transfer length
  IP2Bus_Mst_Type,            // IP to Bus master transfer type
  IP2Bus_Mst_Lock,            // IP to Bus master lock
  IP2Bus_Mst_Reset,           // IP to Bus master reset
  Bus2IP_Mst_CmdAck,          // Bus to IP master command acknowledgement
  Bus2IP_Mst_Cmplt,           // Bus to IP master transfer completion
  Bus2IP_MstRd_d,             // Bus to IP master read data bus
  Bus2IP_MstRd_eof_n,         // Bus to IP master read end of frame
  Bus2IP_MstRd_src_rdy_n,     // Bus to IP master read source ready
  IP2Bus_MstRd_dst_rdy_n,     // IP to Bus master read destination ready
  IP2Bus_MstRd_dst_dsc_n      // IP to Bus master read destination discontinue
 
); 


// -- parameters definition 
parameter  integer C_TFT_INTERFACE          = 1;          
parameter  integer C_I2C_SLAVE_ADDR         = 7'b1110110;          
//parameter  integer C_DEFAULT_TFT_BASE_ADDR  = 11'b11110000000;
parameter  [0:63] C_DEFAULT_TFT_BASE_ADDR  = 64'h00000000F0000000;
parameter  integer C_IOREG_STYLE            = 1;
parameter  integer C_EN_I2C_INTF            = 1;

parameter          C_FAMILY                 = "virtex7";
parameter  integer C_SLV_DWIDTH             = 32;
parameter  integer C_MST_AWIDTH             = 32;
parameter  integer C_MST_DWIDTH             = 64;
parameter  integer C_NUM_REG                = 6;
parameter  integer C_TRANS_INIT             = 19;
parameter  integer C_LINE_INIT              = 479;

// TFT SIGNALS
input                              SYS_TFT_Clk;
output                             TFT_HSYNC;
output                             TFT_VSYNC;
output                             TFT_DE; 
output                             TFT_DPS; 
output                             TFT_VGA_CLK; 
output    [5:0]                    TFT_VGA_R; 
output    [5:0]                    TFT_VGA_G; 
output    [5:0]                    TFT_VGA_B; 
output                             TFT_DVI_CLK_P; 
output                             TFT_DVI_CLK_N; 
output    [11:0]                   TFT_DVI_DATA; 

// IIC init signals
input                              TFT_IIC_SCL_I;
output                             TFT_IIC_SCL_O;
output                             TFT_IIC_SCL_T;
input                              TFT_IIC_SDA_I;
output                             TFT_IIC_SDA_O;
output                             TFT_IIC_SDA_T;

// AXI Slave signals 
input                              S_AXI_Clk;
input                              S_AXI_Rst;
input     [0 : C_SLV_DWIDTH-1]     Bus2IP_Data;
input     [0 : C_NUM_REG-1]        Bus2IP_RdCE;
input     [0 : C_NUM_REG-1]        Bus2IP_WrCE;
input     [0 : C_SLV_DWIDTH/8-1]   Bus2IP_BE;
output    [0 : C_SLV_DWIDTH-1]     IP2Bus_Data;
output                             IP2Bus_RdAck;
output                             IP2Bus_WrAck;
output                             IP2Bus_Error;

output                             IP2INTC_Irpt;

// AXI Master signals 
input                              M_AXI_Clk;
input                              M_AXI_Rst;
output                             IP2Bus_MstRd_Req;
output    [0 : C_MST_AWIDTH-1]     IP2Bus_Mst_Addr;
output    [0 : C_MST_DWIDTH/8-1]   IP2Bus_Mst_BE;
output    [0 : 11]                 IP2Bus_Mst_Length;
output                             IP2Bus_Mst_Type;
output                             IP2Bus_Mst_Lock;
output                             IP2Bus_Mst_Reset;
input                              Bus2IP_Mst_CmdAck;
input                              Bus2IP_Mst_Cmplt;
input     [0 : C_MST_DWIDTH-1]     Bus2IP_MstRd_d;
input                              Bus2IP_MstRd_eof_n;
input                              Bus2IP_MstRd_src_rdy_n;
output                             IP2Bus_MstRd_dst_rdy_n;
output                             IP2Bus_MstRd_dst_dsc_n;

//////////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////////
localparam BASE_ADD_LEN = C_MST_AWIDTH-22;//(C_MST_AWIDTH == 32) ? 10: (C_MST_AWIDTH-21);
//localparam BASE_ADD_LEN = (C_MST_AWIDTH == 32) ? 10: 42;
    // AXI_IF to RGB_BRAM  
  reg    [0:63]                    AXI_BRAM_data_i;
  reg                              AXI_BRAM_we_i;

  // HSYNC and VSYNC to TFT_IF
  wire                             HSYNC_i;
  wire                             VSYNC_i;

  // DE GENERATION
  wire                             H_DE_i;
  wire                             V_DE_i;
  wire                             DE_i;

  // RGB_BRAM to TFT_IF
  wire   [5:0]                     RED_i;
  wire   [5:0]                     GREEN_i;
  wire   [5:0]                     BLUE_i;
  wire                             I2C_done;
  wire                             I2C_done_tft;

  // VSYNC RESET
  wire                             vsync_rst;

  // TFT READ FROM BRAM
  wire                             BRAM_TFT_rd;
  wire                             BRAM_TFT_oe;

  // Hsync|Vsync terminal counts                                   
  wire                             h_bp_cnt_tc;
  wire                             h_bp_cnt_tc2;  
  wire                             h_pix_cnt_tc;
  wire                             h_pix_cnt_tc2;
  reg    [0:4]                     trans_cnt;
  reg    [0:4]                     trans_cnt_i;
  wire                             trans_cnt_tc;
  reg    [0:8]                     line_cnt;
  reg    [0:8]                     line_cnt_i;
  wire                             line_cnt_ce;
  wire                             mn_request_set;
  wire                             trans_cnt_tc_pulse;
  wire                             mn_request;

  // get line pulse
  wire                              get_line;
  
  // TFT controller Registers
  wire   [0:BASE_ADD_LEN]         tft_base_addr_i;
  wire   [0:BASE_ADD_LEN]         tft_base_addr_d2;
  reg    [0:BASE_ADD_LEN]         tft_base_addr;
  wire                             tft_on_reg;
  wire                             tft_on_reg_i;

  // TFT control signals
  wire                             tft_on_reg_bram_d2;
  wire                             v_bp_cnt_tc;
  wire                             get_line_start;
  reg                              get_line_start_d1;
  wire                             v_l_cnt_tc;
  wire                             v_p_cnt_tc;

                                   
  // TFT Reset signals                   
  wire                             tft_rst;   

  // axi reset signals
  //wire                             axi_rst_d6;    
  (*ASYNC_REG = "TRUE"*) reg       axi_rst_d1;    
  (*ASYNC_REG = "TRUE"*) reg       axi_rst_d6;    
  reg                              IP2Bus_MstRd_Req;
  reg                              IP2Bus_Mst_Type;
  reg                              IP2Bus_MstRd_dst_rdy;
  reg                              eof_n;
  reg                              trans_cnt_tc_pulse_i;
  wire                             eof_pulse;
  wire                             master_rst;
  wire                             ip2intc_irpt_i;
  wire                             tft_intr_en_i;
  wire                             tft_intr_en_maxi;
  wire                             tft_status_i;
  wire                             vsync_intr;
  reg                              vsync_intr_d1;
  reg                              vsync_intr_d2;
  wire                             v_bp_pulse;  
  wire                             iic_xfer_done_i;  
  wire                             tft_iic_xfer_i;  
  wire [0:7]                       tft_iic_reg_addr_i;  
  wire [0:7]                       tft_iic_reg_data_i;  
  
  
  // AXI Master Interface signals
  assign IP2Bus_MstRd_dst_rdy_n = ~IP2Bus_MstRd_dst_rdy;
  assign IP2Bus_MstRd_dst_dsc_n     = 1'b1;                             
  assign IP2Bus_Mst_Length          = 12'b000010000000;
  assign IP2Bus_Mst_BE              = 8'b0;   
  assign IP2Bus_Mst_Lock            = 1'b0;   
  assign IP2Bus_Mst_Reset           = ~tft_on_reg; 
  assign IP2Bus_Mst_Addr[0:BASE_ADD_LEN]  = tft_base_addr; //0:42
  //assign IP2Bus_Mst_Addr[0:10]      = tft_base_addr; 
  assign IP2Bus_Mst_Addr[BASE_ADD_LEN+1:BASE_ADD_LEN+9]     = line_cnt_i; //43:51
  //assign IP2Bus_Mst_Addr[11:19]     = line_cnt_i;
  assign IP2Bus_Mst_Addr[BASE_ADD_LEN+10:BASE_ADD_LEN+14]     = trans_cnt_i; //52:56
  //assign IP2Bus_Mst_Addr[20:24]     = trans_cnt_i;
  //assign IP2Bus_Mst_Addr[25:31]     = 7'b0000000; 
  assign IP2Bus_Mst_Addr[BASE_ADD_LEN+15:BASE_ADD_LEN+21]     = 7'b0000000; //57:63

 

  /////////////////////////////////////
  // Generate Frame complete interrupt
  // for master burst interface
  /////////////////////////////////////

  // Synchronize the tft_intr_en_i signal w.r.t. M_AXI clock 
  cdc_sync
    #(
        .C_CDC_TYPE      (1),
        .C_RESET_STATE   (0), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (4))
   INTR_EN_SYNC
    (
        .prmry_aclk         (S_AXI_Clk),
        .prmry_resetn       (1'b0),
        .prmry_in           (tft_intr_en_i),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (M_AXI_Clk),
        .scndry_resetn      (1'b0), 
        .scndry_out         (tft_intr_en_maxi),
        .scndry_vect_out    ()); 


  assign ip2intc_irpt_i = tft_intr_en_maxi & vsync_intr;

  // Generate TFT DE
  FDR FDR_IP2INTC_Irpt (.Q(IP2INTC_Irpt),    
                        .C(M_AXI_Clk), 
                        .R(master_rst), 
                        .D(ip2intc_irpt_i));

  
  /////////////////////////////////////////////////////////////////////////////                                                   
  // REQUEST LOGIC for AXI 
  /////////////////////////////////////////////////////////////////////////////
  assign mn_request_set = ((get_line & (trans_cnt == 0)) | 
                           (Bus2IP_Mst_Cmplt & trans_cnt != 0));
  
  /////////////////////////////////
  // Generate Master read request 
  // for master burst interface
  /////////////////////////////////
  always @(posedge M_AXI_Clk)
  begin : MST_REQ
    if (Bus2IP_Mst_CmdAck | master_rst | trans_cnt_tc_pulse) 
      begin
        IP2Bus_MstRd_Req <= 1'b0;
      end
    else if (mn_request_set) 
      begin
        IP2Bus_MstRd_Req <= 1'b1;
      end 
   end   

  /////////////////////////////////
  // Generate Master Type signal 
  // for master burst interface
  /////////////////////////////////
  always @(posedge M_AXI_Clk)
  begin : MST_TYPE
    if (Bus2IP_Mst_CmdAck | master_rst) 
      begin
        IP2Bus_Mst_Type <= 1'b0;
      end
    else if (mn_request_set)
      begin
        IP2Bus_Mst_Type <= 1'b1;
      end
   end
    
  //////////////////////////////////////////
  // Generate Master read destination ready 
  // for master burst interface
  //////////////////////////////////////////
  always @(posedge M_AXI_Clk)
  begin : MST_DST_RDY
    if (master_rst | eof_pulse) 
      begin
        IP2Bus_MstRd_dst_rdy <= 1'b0;
      end
    else if (mn_request_set) 
      begin
        IP2Bus_MstRd_dst_rdy <= 1'b1;
      end
   end


 

  /////////////////////////////////////////////////////////////////////////////
  // Generate control signals for line count and trans count
  /////////////////////////////////////////////////////////////////////////////    
  // Generate end of frame from Master burst interface 
  always @(posedge M_AXI_Clk)
  begin : EOF_GEN
    if (master_rst) 
      begin
        eof_n <= 1'b1;
      end
    else     
      begin
        eof_n <= Bus2IP_MstRd_eof_n;
      end
  end 
 
  // Generate one shot pulse for end of frame  
  assign eof_pulse = ~eof_n & Bus2IP_MstRd_eof_n;
  
  
  // Registering trans_cnt_tc to generate one shot pulse 
  // for trans_counter terminal count  
  always @(posedge M_AXI_Clk)
  begin : TRANS_CNT_TC_I
    if (master_rst) 
      begin
        trans_cnt_tc_pulse_i <= 1'b0;
      end
    else     
      begin 
        trans_cnt_tc_pulse_i <= trans_cnt_tc;
      end
  end 

  // Generate one shot pulse for trans_counter terminal count  
  assign trans_cnt_tc_pulse = trans_cnt_tc_pulse_i & ~trans_cnt_tc;  
                          

  /////////////////////////////////////////////////////////////////////////////
  // Generate AXI memory addresses
  /////////////////////////////////////////////////////////////////////////////    

 // load tft_base_addr from tft address register after completing 
 // the current frame only
generate
      if (C_MST_AWIDTH == 32) // When Address width 32
      begin 
 always @(posedge M_AXI_Clk)
 begin : MST_BASE_ADDR_GEN
   if (master_rst) 
     begin
       tft_base_addr <= C_DEFAULT_TFT_BASE_ADDR[32:42];
     end
   else if (v_bp_pulse) 
     begin
       tft_base_addr <= tft_base_addr_d2;
     end
 end 
end
else begin
always @(posedge M_AXI_Clk)
 begin : MST_BASE_ADDR_GEN_64
   if (master_rst) 
     begin
       //tft_base_addr <= C_DEFAULT_TFT_BASE_ADDR[0:BASE_ADD_LEN];
       tft_base_addr <= C_DEFAULT_TFT_BASE_ADDR[64-C_MST_AWIDTH:42];
     end
   else if (v_bp_pulse) 
     begin
       tft_base_addr <= tft_base_addr_d2;
     end
 end 

 end
 endgenerate
  // Load line counter and trans counter if the master request is set
  always @(posedge M_AXI_Clk)
  begin : MST_LINE_ADDR_GEN
    if (master_rst) 
      begin 
        line_cnt_i      <= 9'b0;
        trans_cnt_i     <= 5'b0;
      end  
    else if (mn_request_set) 
      begin
        line_cnt_i      <= line_cnt;
        trans_cnt_i     <= trans_cnt;
      end 
  end 
                             
  
  /////////////////////////////////////////////////////////////////////////////
  // Transaction Counter - Counts 0-19 (d) C_TRANS_INIT
  /////////////////////////////////////////////////////////////////////////////      

  // Generate trans_count_tc 
  assign trans_cnt_tc = (trans_cnt == C_TRANS_INIT);

  // Trans_count counter.
  // Update the counter after every 128 byte frame 
  // received from the master burst interface.
  always @(posedge M_AXI_Clk)
  begin : TRANS_CNT_I
    if(master_rst | vsync_intr)
      begin
        trans_cnt <= 5'b0;
      end   
    else if (eof_pulse) 
      begin
        if (trans_cnt_tc)
          begin
            trans_cnt <= 5'b0;
          end  
        else 
          begin 
            trans_cnt <= trans_cnt + 1;
          end  
      end
  end

  /////////////////////////////////////////////////////////////////////////////
  // Line Counter - Counts 0-479 (d)  C_LINE_INIT
  /////////////////////////////////////////////////////////////////////////////      

  // Generate trans_count_tc 
  assign line_cnt_ce = trans_cnt_tc_pulse;
  
  // Line_count counter.
  // Update the counter after every line is received 
  // from the master burst interface.
  always @(posedge M_AXI_Clk)
  begin : LINE_CNT_I
    if (master_rst | vsync_intr)
      begin 
        line_cnt <= 9'b0; 
      end  
    else if (line_cnt_ce) 
      begin
        if (line_cnt == C_LINE_INIT)
          begin 
            line_cnt <= 9'b0;
          end  
        else
          begin 
            line_cnt <= line_cnt + 1;
          end  
      end
  end

  // BRAM_TFT_rd and BRAM_TFT_oe start the read process. These are constant
  // signals through out a line read.  
  assign BRAM_TFT_rd = ((DE_i ^ h_bp_cnt_tc ^ h_bp_cnt_tc2 ) & V_DE_i);
  assign BRAM_TFT_oe = ((DE_i ^ h_bp_cnt_tc) & V_DE_i);  
  
  /////////////////////////////////////////////////////////////////////////////
  // Generate line buffer write enable signal and register the AXI data
  /////////////////////////////////////////////////////////////////////////////    
  always @(posedge M_AXI_Clk)
  begin : BRAM_DATA_WE
    if(master_rst)
      begin
        AXI_BRAM_data_i  <= 64'b0;
        AXI_BRAM_we_i    <= 1'b0;
      end
    else
      begin
        AXI_BRAM_data_i  <= Bus2IP_MstRd_d;
        AXI_BRAM_we_i    <= ~Bus2IP_MstRd_src_rdy_n;
      end                             
  end
  
  /////////////////////////////////////////////////////////////////////////////
  // Generate Get line start signal to fetch the video data from AXI  attached
  // video memory
  /////////////////////////////////////////////////////////////////////////////
  // get line start logic
  assign get_line_start = ((h_pix_cnt_tc && v_bp_cnt_tc) || // 1st get line
                           (h_pix_cnt_tc && DE_i) &&     // 2nd,3rd,...get line
                           (~v_l_cnt_tc));               // No get_line on last 
                                                         //line      

  // Generate DE for HW
  assign DE_i = (H_DE_i & V_DE_i);
  
      
  // Synchronize the get line signal w.r.t. M_AXI clock
  always @(posedge SYS_TFT_Clk)
  begin : GET_LINE_START_I
    if (tft_rst)
      begin
        get_line_start_d1 <= 1'b0;
      end
    else
      begin
        get_line_start_d1 <= get_line_start;
      end
  end
  
  // Synchronize the get line signal w.r.t. M_AXI clock //Sync needed
  cdc_sync
    #(
        .C_CDC_TYPE      (0),
        .C_RESET_STATE   (1), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (4))
   GET_LINE_SYNC
    (
        .prmry_aclk         (SYS_TFT_Clk),
        .prmry_resetn       (~tft_rst),
        .prmry_in           (get_line_start_d1),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (M_AXI_Clk),
        .scndry_resetn      (~M_AXI_Rst), 
        .scndry_out         (get_line),
        .scndry_vect_out    ()); 


  /////////////////////////////////////////////////////////////////////////////
  // Sample VSYNC Frame Complete signal. 
  ///////////////////////////////////////////////////////////////////////////// 
  cdc_sync
    #(
        .C_CDC_TYPE      (0),
        .C_RESET_STATE   (1), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (4))
   V_P_SYNC
    (
        .prmry_aclk         (SYS_TFT_Clk),
        .prmry_resetn       (~tft_rst),
        .prmry_in           (v_p_cnt_tc),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (M_AXI_Clk),
        .scndry_resetn      (~M_AXI_Rst), 
        .scndry_out         (vsync_intr),
        .scndry_vect_out    ()); 

  /////////////////////////////////////////////////////////////////////////////
  // Synchronize all the signals crossing the clock domains
  // video memory
  /////////////////////////////////////////////////////////////////////////////

  // Synchronize the TFT clock domain signals w.r.t. M_AXI clock
  cdc_sync
    #(
        .C_CDC_TYPE      (0),
        .C_RESET_STATE   (1), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (4))
   V_BP_SYNC
    (
        .prmry_aclk         (SYS_TFT_Clk),
        .prmry_resetn       (~tft_rst),
        .prmry_in           (v_bp_cnt_tc),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (M_AXI_Clk),
        .scndry_resetn      (~M_AXI_Rst), 
        .scndry_out         (v_bp_pulse),
        .scndry_vect_out    ()); 


  // Synchronize the slave register signals w.r.t. M_AXI clock
  cdc_sync
    #(
        .C_CDC_TYPE      (1),
        .C_RESET_STATE   (0), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (4))
   TFT_ON_MAXI_SYNC
    (
        .prmry_aclk         (S_AXI_Clk),
        .prmry_resetn       (1'b0),
        .prmry_in           (tft_on_reg_i),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (M_AXI_Clk),
        .scndry_resetn      (1'b0), 
        .scndry_out         (tft_on_reg),
        .scndry_vect_out    ()); 

   cdc_sync
    #(
        .C_CDC_TYPE      (1),
        .C_RESET_STATE   (0), 
        .C_SINGLE_BIT    (0), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (BASE_ADD_LEN+1),
        .C_MTBF_STAGES   (4))
   BASE_ADDR_SYNC
    (
        .prmry_aclk         (S_AXI_Clk),
        .prmry_resetn       (1'b0),
        .prmry_in           (1'b0),
        .prmry_vect_in      (tft_base_addr_i),
        .prmry_ack          (),
        .scndry_aclk        (M_AXI_Clk),
        .scndry_resetn      (1'b0), 
        .scndry_out         (),
        .scndry_vect_out    (tft_base_addr_d2)); 


  // Synchronize the tft_on_reg signal w.r.t. SYS_TFT_Clk
  cdc_sync
    #(
        .C_CDC_TYPE      (1),
        .C_RESET_STATE   (0), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (2))
   TFT_ON_TFT_SYNC
    (
        .prmry_aclk         (S_AXI_Clk),
        .prmry_resetn       (1'b0),
        .prmry_in           (tft_on_reg_i),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (SYS_TFT_Clk),
        .scndry_resetn      (1'b0), 
        .scndry_out         (tft_on_reg_bram_d2),
        .scndry_vect_out    ()); 


  // Increase the width of the signal to match with S_AXI clock
  cdc_sync
    #(
        .C_CDC_TYPE      (0),
        .C_RESET_STATE   (1), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (4))
   V_INTR_SYNC
    (
        .prmry_aclk         (M_AXI_Clk),
        .prmry_resetn       (~M_AXI_Rst),
        .prmry_in           (vsync_intr),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (S_AXI_Clk),
        .scndry_resetn      (~S_AXI_Rst), 
        .scndry_out         (tft_status_i),
        .scndry_vect_out    ()); 


  /////////////////////////////////////////////////////////////////////////////

  
  // Generate master interface reset from the M_AXI reset and tft_on_reg
  assign master_rst = M_AXI_Rst | ~tft_on_reg;
  
  // Generate TFT reset from the master reset,I2C done

  always@(posedge SYS_TFT_Clk or posedge M_AXI_Rst)
  begin
      if(M_AXI_Rst) begin
          axi_rst_d1 <= 1'b0;
          axi_rst_d6 <= 1'b0;
      end else begin
          axi_rst_d1 <= 1'b1;
          axi_rst_d6 <= axi_rst_d1;
      end
  end
  //cdc_sync
  //  #(
  //      .C_CDC_TYPE      (1),
  //      .C_RESET_STATE   (1), 
  //      .C_SINGLE_BIT    (1), 
  //      .C_FLOP_INPUT    (0),
  //      .C_VECTOR_WIDTH  (1),
  //      .C_MTBF_STAGES   (2))
  //  TFT_RST_SYNC
  //  (
  //      .prmry_aclk         (M_AXI_Clk),
  //      .prmry_resetn       (~M_AXI_Rst),
  //      .prmry_in           (1'b1),
  //      .prmry_vect_in      (1'b0),
  //      .prmry_ack          (),
  //      .scndry_aclk        (SYS_TFT_Clk),
  //      .scndry_resetn      (~M_AXI_Rst), 
  //      .scndry_out         (axi_rst_d6),
  //      .scndry_vect_out    ());


 
  // Synchronize the M_AXI reset with SYS_TFT_CLK
  cdc_sync
    #(
        .C_CDC_TYPE      (1),
        .C_RESET_STATE   (0), 
        .C_SINGLE_BIT    (1), 
        .C_FLOP_INPUT    (0),
        .C_VECTOR_WIDTH  (1),
        .C_MTBF_STAGES   (2))
    I2C_DONE_SYNC
    (
        .prmry_aclk         (S_AXI_Clk),
        .prmry_resetn       (1'b0),
        .prmry_in           (I2C_done),
        .prmry_vect_in      (1'b0),
        .prmry_ack          (),
        .scndry_aclk        (SYS_TFT_Clk),
        .scndry_resetn      (1'b0), 
        .scndry_out         (I2C_done_tft),
        .scndry_vect_out    ());

 // assign tft_rst = ~axi_rst_d6 | ~I2C_done_tft | ~tft_on_reg_bram_d2;

      generate
      if (C_IOREG_STYLE == 0) // Selects 7 seriese
        begin : gen_7s
            assign tft_rst = ~axi_rst_d6 | ~I2C_done_tft | ~tft_on_reg_bram_d2;
        end
      else  // Selects 8 seriese
        begin : gen_8s
            reg tft_rst_d1;
            reg tft_rst_d2;
            reg tft_rst_d3;
            reg tft_rst_d4;
            
            always @(posedge SYS_TFT_Clk) begin
                tft_rst_d1 <= ~axi_rst_d6 | ~I2C_done_tft | ~tft_on_reg_bram_d2;
                tft_rst_d2 <= tft_rst_d1;
                tft_rst_d3 <= tft_rst_d2;
                tft_rst_d4 <= tft_rst_d3;
            end
            assign tft_rst = tft_rst_d4;
        end
      endgenerate


  /////////////////////////////////////////////////////////////////////////////
  // Slave Register COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////
  axi_tft_v2_0_16_slave_register 
    #(
      .C_DEFAULT_TFT_BASE_ADDR   (C_DEFAULT_TFT_BASE_ADDR), 
      .C_SLV_DWIDTH              (C_SLV_DWIDTH), 
      .C_SLV_AWIDTH              (C_MST_AWIDTH), 
      .C_NUM_REG                 (C_NUM_REG)
    )
    SLAVE_REG_U6 
    (
      .S_AXI_Clk          (S_AXI_Clk),
      .S_AXI_Rst          (S_AXI_Rst),
      .Bus2IP_Data      (Bus2IP_Data),         
      .Bus2IP_RdCE      (Bus2IP_RdCE),     
      .Bus2IP_WrCE      (Bus2IP_WrCE),     
      .Bus2IP_BE        (Bus2IP_BE),
      .IP2Bus_Data      (IP2Bus_Data),         
      .IP2Bus_RdAck     (IP2Bus_RdAck),       
      .IP2Bus_WrAck     (IP2Bus_WrAck),    
      .IP2Bus_Error     (IP2Bus_Error), 
      .TFT_base_addr    (tft_base_addr_i),
      .TFT_dps_reg      (TFT_DPS),
      .TFT_on_reg       (tft_on_reg_i),
      .TFT_intr_en      (tft_intr_en_i),
      .TFT_status       (tft_status_i),
      .IIC_xfer_done    (iic_xfer_done_i),
      .TFT_iic_xfer     (tft_iic_xfer_i),
      .TFT_iic_reg_addr (tft_iic_reg_addr_i),
      .TFT_iic_reg_data (tft_iic_reg_data_i)
  );              
                  
  /////////////////////////////////////////////////////////////////////////////
  // RGB_BRAM COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////              
  axi_tft_v2_0_16_line_buffer #(.C_FAMILY (C_FAMILY))LINE_BUFFER_U4
    (
    .TFT_Clk         (SYS_TFT_Clk),
    .TFT_Rst         (tft_rst),
    .AXI_Clk         (M_AXI_Clk),
    .AXI_Rst         (master_rst),
    .BRAM_TFT_rd     (BRAM_TFT_rd), 
    .BRAM_TFT_oe     (BRAM_TFT_oe), 
    .AXI_BRAM_data   (AXI_BRAM_data_i),
    .AXI_BRAM_we     (AXI_BRAM_we_i),
    .RED             (RED_i),
    .GREEN           (GREEN_i), 
    .BLUE            (BLUE_i)
  );              
                  
  /////////////////////////////////////////////////////////////////////////////
  //HSYNC COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////  
  axi_tft_v2_0_16_h_sync HSYNC_U2 (
    .Clk             (SYS_TFT_Clk), 
    .Rst             (tft_rst), 
    .HSYNC           (HSYNC_i), 
    .H_DE            (H_DE_i), 
    .VSYNC_Rst       (vsync_rst), 
    .H_bp_cnt_tc     (h_bp_cnt_tc),    
    .H_bp_cnt_tc2    (h_bp_cnt_tc2), 
    .H_pix_cnt_tc    (h_pix_cnt_tc),  
    .H_pix_cnt_tc2   (h_pix_cnt_tc2) 
  );              
                 
  /////////////////////////////////////////////////////////////////////////////
  // VSYNC COMPONENT INSTANTIATION
  ///////////////////////////////////////////////////////////////////////////// 
  axi_tft_v2_0_16_v_sync VSYNC_U3 (
    .Clk          (SYS_TFT_Clk),
    .Clk_stb      (~HSYNC_i), 
    .Rst          (vsync_rst), 
    .VSYNC        (VSYNC_i), 
    .V_DE         (V_DE_i),
    .V_bp_cnt_tc  (v_bp_cnt_tc),
    .V_p_cnt_tc   (v_p_cnt_tc),
    .V_l_cnt_tc   (v_l_cnt_tc)
  );            
               

  /////////////////////////////////////////////////////////////////////////////
  // TFT_IF COMPONENT INSTANTIATION
  /////////////////////////////////////////////////////////////////////////////
  axi_tft_v2_0_16_tft_interface 
    #(
      .C_FAMILY          (C_FAMILY),
      .C_TFT_INTERFACE   (C_TFT_INTERFACE), 
      .C_I2C_SLAVE_ADDR  (C_I2C_SLAVE_ADDR),
      .C_IOREG_STYLE     (C_IOREG_STYLE), 
      .C_EN_I2C_INTF     (C_EN_I2C_INTF) 

    )
    TFT_IF_U5
    (
      .TFT_Clk           (SYS_TFT_Clk),
      .TFT_Rst           (tft_rst),
      .TFT_Rst_8s        (~axi_rst_d6 | ~I2C_done_tft | ~tft_on_reg_bram_d2),
      .Bus2IP_Clk        (S_AXI_Clk),
      .Bus2IP_Rst        (S_AXI_Rst),
      .HSYNC             (HSYNC_i),
      .VSYNC             (VSYNC_i),
      .DE                (DE_i),   
      .RED               (RED_i),
      .GREEN             (GREEN_i),
      .BLUE              (BLUE_i),
      .TFT_HSYNC         (TFT_HSYNC),
      .TFT_VSYNC         (TFT_VSYNC),
      .TFT_DE            (TFT_DE),
      .TFT_VGA_CLK       (TFT_VGA_CLK),
      .TFT_VGA_R         (TFT_VGA_R),
      .TFT_VGA_G         (TFT_VGA_G),
      .TFT_VGA_B         (TFT_VGA_B), 
      .TFT_DVI_CLK_P     (TFT_DVI_CLK_P),
      .TFT_DVI_CLK_N     (TFT_DVI_CLK_N),
      .TFT_DVI_DATA      (TFT_DVI_DATA),
      .I2C_done          (I2C_done),
      .TFT_IIC_SCL_I     (TFT_IIC_SCL_I),
      .TFT_IIC_SCL_O     (TFT_IIC_SCL_O),
      .TFT_IIC_SCL_T     (TFT_IIC_SCL_T),
      .TFT_IIC_SDA_I     (TFT_IIC_SDA_I),
      .TFT_IIC_SDA_O     (TFT_IIC_SDA_O),
      .TFT_IIC_SDA_T     (TFT_IIC_SDA_T),
      .IIC_xfer_done     (iic_xfer_done_i),
      .TFT_iic_xfer      (tft_iic_xfer_i),
      .TFT_iic_reg_addr  (tft_iic_reg_addr_i),
      .TFT_iic_reg_data  (tft_iic_reg_data_i)
  );
  
  
endmodule


