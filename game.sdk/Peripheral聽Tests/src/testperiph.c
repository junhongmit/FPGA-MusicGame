/*
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * 
 *
 * This file is a generated sample test application.
 *
 * This application is intended to test and/or illustrate some 
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * SDK application project when you run the "Generate Libraries" menu item.
 *
 */

#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xintc.h"
#include "intc_header.h"
#include "xgpio.h"
#include "gpio_header.h"
#include "xspi.h"
#include "spi_header.h"
#include "spi_intr_header.h"
#include "xtmrctr.h"
#include "tmrctr_header.h"
#include "tmrctr_intr_header.h"
int main() 
{
   static XIntc intc;
   static XSpi hier_periph_axi_quad_spi_flash_Spi;
   static XTmrCtr hier_periph_axi_timer_0_Timer;
   Xil_ICacheEnable();
   Xil_DCacheEnable();
   print("---Entering main---\n\r");
   

   {
      int status;
      
      print("\r\n Running IntcSelfTestExample() for hier_periph_microblaze_0_axi_intc...\r\n");
      
      status = IntcSelfTestExample(XPAR_HIER_PERIPH_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
      
      if (status == 0) {
         print("IntcSelfTestExample PASSED\r\n");
      }
      else {
         print("IntcSelfTestExample FAILED\r\n");
      }
   } 
	
   {
       int Status;

       Status = IntcInterruptSetup(&intc, XPAR_HIER_PERIPH_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
       if (Status == 0) {
          print("Intc Interrupt Setup PASSED\r\n");
       } 
       else {
         print("Intc Interrupt Setup FAILED\r\n");
      } 
   }
   

   {
      u32 status;
      
      print("\r\nRunning GpioOutputExample() for hier_periph_axi_gpio_LED...\r\n");

      status = GpioOutputExample(XPAR_HIER_PERIPH_AXI_GPIO_LED_DEVICE_ID,16);
      
      if (status == 0) {
         print("GpioOutputExample PASSED.\r\n");
      }
      else {
         print("GpioOutputExample FAILED.\r\n");
      }
   }
   

   {
      XStatus status;
      
      print("\r\n Runnning SpiSelfTestExample() for hier_periph_axi_quad_spi_flash...\r\n");
      
      status = SpiSelfTestExample(XPAR_HIER_PERIPH_AXI_QUAD_SPI_FLASH_DEVICE_ID);
      
      if (status == 0) {
         print("SpiSelfTestExample PASSED\r\n");
      }
      else {
         print("SpiSelfTestExample FAILED\r\n");
      }
   }
    {
       XStatus Status;

       print("\r\n Running Interrupt Test for hier_periph_axi_quad_spi_flash...\r\n");

       Status = SpiIntrExample(&intc, &hier_periph_axi_quad_spi_flash_Spi, \
                                XPAR_HIER_PERIPH_AXI_QUAD_SPI_FLASH_DEVICE_ID, \
                                XPAR_HIER_PERIPH_MICROBLAZE_0_AXI_INTC_HIER_PERIPH_AXI_QUAD_SPI_FLASH_IP2INTC_IRPT_INTR);
      if (Status == 0) {
         print("Spi Interrupt Test PASSED\r\n");
      } 
      else {
         print("Spi Interrupt Test FAILED\r\n");
      }

    }
   

   {
      int status;
      
      print("\r\n Running TmrCtrSelfTestExample() for hier_periph_axi_timer_0...\r\n");
      
      status = TmrCtrSelfTestExample(XPAR_HIER_PERIPH_AXI_TIMER_0_DEVICE_ID, 0x0);
      
      if (status == 0) {
         print("TmrCtrSelfTestExample PASSED\r\n");
      }
      else {
         print("TmrCtrSelfTestExample FAILED\r\n");
      }
   }
   {
      int Status;

      print("\r\n Running Interrupt Test  for hier_periph_axi_timer_0...\r\n");
      
      Status = TmrCtrIntrExample(&intc, &hier_periph_axi_timer_0_Timer, \
                                 XPAR_HIER_PERIPH_AXI_TIMER_0_DEVICE_ID, \
                                 XPAR_HIER_PERIPH_MICROBLAZE_0_AXI_INTC_HIER_PERIPH_AXI_TIMER_0_INTERRUPT_INTR, 0);
	
      if (Status == 0) {
         print("Timer Interrupt Test PASSED\r\n");
      } 
      else {
         print("Timer Interrupt Test FAILED\r\n");
      }

   }
   
   /*
    * Peripheral SelfTest will not be run for hier_periph_mdm_1
    * because it has been selected as the STDOUT device
    */

   print("---Exiting main---\n\r");
   Xil_DCacheDisable();
   Xil_ICacheDisable();
   return 0;
}
