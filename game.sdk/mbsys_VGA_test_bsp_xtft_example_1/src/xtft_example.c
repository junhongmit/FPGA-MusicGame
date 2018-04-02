/******************************************************************************
*
* Copyright (C) 2008 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/****************************************************************************/
/**
*
* @file xtft_example.c
*
* This file contains a design example using the driver functions of the XTft
* driver. This example shows the usage of the driver/device to
* - Write a character and write a string of characters
* - Draw a line
* - Turn ON/OFF the TFT Device
*
*
* @note
*
* TFT_FRAME_ADDR specifies the starting address of the 2MB space for storing the
* frame data and has to be defined by the user based on the system memory map.
*
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver    Who   Date      Changes
* -----  ----  --------  -----------------------------------------------
* 1.00a  sg    03/24/08  First release
* 1.00a  sg    09/24/08  Updated the example to update the Video Memory Base
*			 Address with the Memory specified by the application
* 2.00a  ktn   07/09/09  Updated the example to poll the Vsync(Video address
*			 latch) status bit before writing to the Address
*			 Register (AR)
* 4.00a  bss   01/22/13  Updated the example to use DDR_HIGH_ADDR to support
*			 for some AXI memory controllers, User needs to define
*			 it with a valid address.
* 6.00   ms    01/23/17 Added xil_printf statement in main function to
*                       ensure that "Successfully ran" and "Failed" strings
*                       are available in all examples. This is a fix for
*                       CR-965028.
*
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "display.h"
#include "math.h"
#include "xtft.h"
#include "xtft_hw.h"
//#include "image.h"
//#include "image1.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "xtmrctr.h"
#include "xintc.h"
#include "tmrctr_header.h"
extern int page;
extern int checkBack;
extern XIntc InterruptController;

/************************** Constant Definitions ****************************/
/**
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define TFT_DEVICE_ID	XPAR_TFT_0_DEVICE_ID


#ifdef XPAR_V6DDR_0_S_AXI_HIGHADDR
#define DDR_HIGH_ADDR		XPAR_V6DDR_0_S_AXI_HIGHADDR
#elif XPAR_S6DDR_0_S0_AXI_HIGHADDR
#define DDR_HIGH_ADDR		XPAR_S6DDR_0_S0_AXI_HIGHADDR
#elif XPAR_AXI_7SDDR_0_S_AXI_HIGHADDR
#define DDR_HIGH_ADDR		XPAR_AXI_7SDDR_0_S_AXI_HIGHADDR
#elif XPAR_HIER_MEM_MIG_7SERIES_0_HIGHADDR
#define DDR_HIGH_ADDR		XPAR_HIER_MEM_MIG_7SERIES_0_HIGHADDR
#endif

#ifndef DDR_HIGH_ADDR
#warning "CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H"
#endif

/**
 * User has to specify a 2MB memory space for filling the frame data.
 * This constant has to be updated based on the memory map of the
 * system.
 */
#define TFT_FRAME_ADDR		DDR_HIGH_ADDR - 0x001FFFFF
#define TFT_FRAME_ADDR2		DDR_HIGH_ADDR - 0x001FFFFF - 0x001FFFFF-1

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/**
 * Color Values.
 */
#define FGCOLOR_VALUE		0x0000FF00	/**< Foreground Color - Green */
#define BGCOLOR_VALUE		0x0		/**< Background Color - Black */
#define WHITECOLOR_VALUE 	0x00FFFFFF	/**< Color - White */

/**
 * Start and End point Coordinates for the line.
 */
#define X1POS	100	/**< Column Start Position */
#define X2POS	100	 /**< Column End Position */
#define Y1POS	50 	/**< Row Start Position */
#define Y2POS	450	 /**< Row End Position */

/************************** Function Prototypes *****************************/

static int TftWriteString(XTft *InstancePtr, const u8 *CharValue);
static int TftDrawLine(XTft *InstancePtr, u32 ColStartPos, u32 RowStartPos,
			u32 ColEndPos, u32 RowEndPos, u32 PixelVal);
int TftExample(u32 TftDeviceId);

/************************** Variable Definitions ****************************/

XTft TftInstance;
u32 key;

/************************** Function Definitions ****************************/
/*****************************************************************************/
/**
*
* Main function that invokes the Tft example.
*
* @param	None.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if unsuccessful.
*
* @note		None.
*
******************************************************************************/
int main()
{
	int Status;

	Timer_Init();
	SetupKeyBoardIntC();
	Status = TftExample(TFT_DEVICE_ID);
	if ( Status != XST_SUCCESS) {
		xil_printf("Tft Example Failed\r\n");
		return XST_FAILURE;
	}
	xil_printf("Successfully ran Tft Example\r\n");
	return XST_SUCCESS;
}

/***************************************************************************/
/**
*
* This function fills the screen with the range defined by the start and end
* values of column and row with the color passed as argument.
*
* @param	InstancePtr is a pointer to the XTft instance.
* @param	ColStartVal is the value of the starting column. The valid
*		values are 0 to (XTFT_DISPLAY_WIDTH - 1).
* @param	RowStartVal is the value of the starting row. The valid
*		values are 0 to (XTFT_DISPLAY_HEIGHT - 1).
* @param	ColEndVal is the value of the ending column. The valid
*		values are 0 to (XTFT_DISPLAY_WIDTH - 1).
* @param	RowEndVal is the value of the ending row. The valid
*		values are 0 to (XTFT_DISPLAY_HEIGHT - 1).
* @param	PixelVal represents the color with which it will be
*		filled on screen.
*
* @return	None.
*
* @note		It must be taken care to pass values such that column start
*		position should not exceed column end position, same is the
*		case with row position.
*
****************************************************************************/
/*void BitBlt(UINTPTR Address, u32 x0,u32 y0,u32 width,u32 height, u8 * image, u32 x1, u32 y1, u32 width1,u32 height1)
{
	u32 ColIndex;
	u32 RowIndex;
	u32 nowad;

	for (ColIndex = x0; ColIndex <= x0+width-1; ColIndex++) {
		for (RowIndex = y0; RowIndex <= y0+height-1;
			RowIndex++) {
			nowad=4*(x1+(y1+RowIndex)*width1+ColIndex);
			Xil_Out32(Address +(4 * ((RowIndex) * XTFT_DISPLAY_BUFFER_WIDTH + ColIndex)),
					image[nowad]+(image[nowad+1]<<8)+(image[nowad+2]<<16)+(image[nowad+3]<<24));

		}
	}

}*/

/*****************************************************************************/
/**
*
* This is the example function which performs the following operations on
* the TFT device -
* - Set the color values of foreground and background
* - Write two characters (S) one after another
* - Write a string of characters
* - Draw a line and scroll the screen once
* - Disable the display (The screen goes blank)
* - Scroll the screen once and draw a line
* - Enable the TFT display
*
* @param	TftDeviceId is the unique Id of the device.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if unsuccessful.
*
* @note		None.
*
******************************************************************************/
int TftExample(u32 TftDeviceId)
{
	int Status;
	u8 VarChar;
	XTft_Config *TftConfigPtr;

	/*
	 * Get address of the XTft_Config structure for the given device id.
	 */
	TftConfigPtr = XTft_LookupConfig(TftDeviceId);
	if (TftConfigPtr == (XTft_Config *)NULL) {
		return XST_FAILURE;
	}

	/*
	 * Initialize all the TftInstance members and fills the screen with
	 * default background color.
	 */
	Status = XTft_CfgInitialize(&TftInstance, TftConfigPtr,
				 	TftConfigPtr->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait till Vsync(Video address latch) status bit is set before writing
	 * the frame address into the Address Register. This ensures that the
	 * current frame has been displayed and we can display a new frame of
	 * data. Checking the Vsync state ensures that there is no data flicker
	 * when displaying frames in real time though there is some delay due to
	 * polling.
	 */
	while (XTft_GetVsyncStatus(&TftInstance) !=
					XTFT_IESR_VADDRLATCH_STATUS_MASK);

	/*
	 * Change the Video Memory Base Address from default value to
	 * a valid Memory Address and clear the screen.
	 */
	XTft_SetFrameBaseAddr(&TftInstance, TFT_FRAME_ADDR);
	XTft_ClearScreen(&TftInstance);

	VarChar = 'S';
	XTft_SetColor(&TftInstance, FGCOLOR_VALUE, BGCOLOR_VALUE);


	XTft_Write(&TftInstance, VarChar);
	XTft_Write(&TftInstance, VarChar);

	DMA_Init();
	TftWriteString(&TftInstance, (u8*)"\n\n\n\n\n\n\n\n\n\n\n\n\n finished");
	//BitBlt(0,0,640,480,page_song, 0,0);
	//BitBlt(0,0,147,148,easy_on, 246,270);
	//BitBlt(0,0,640,480,page_song, 0,0,640,480);
	XTft_SetFrameBaseAddr(&TftInstance, TFT_FRAME_ADDR);
	paint();
	//xil_printf("Keyboard:%d\n",Xil_In32(XPAR_HIER_PERIPH_KEYBOARD_0_S00_AXI_BASEADDR));
	for (int i=0; i<5; i++) {
		paint();
	}
	key=1;
	callback();
	while (1) {
		paint();
		CalcPos();
		key=Xil_In32(XPAR_HIER_PERIPH_KEYBOARD_0_S00_AXI_BASEADDR);
		Xil_Out32(XPAR_HIER_PERIPH_KEYBOARD_0_S00_AXI_BASEADDR,0);
		//xil_printf("Keyboard:%d\n",key);
		callback();
	}
	while (1) {
	//XTft_FillScreenAtAddres(&TftInstance, 100,100,540,380,
	//			 0xFFFF00,TFT_FRAME_ADDR2);

	/*XTft_SetFrameBaseAddr(&TftInstance, TFT_FRAME_ADDR2);
	//XTft_FillScreenAtAddres(&TftInstance, 100,100,540,380,
	//				 0xFF0000,TFT_FRAME_ADDR);
	XTft_SetFrameBaseAddr(&TftInstance, TFT_FRAME_ADDR);
	//XTft_FillScreenAtAddres(&TftInstance, 100,100,540,380,
	//				 0x00FF00,TFT_FRAME_ADDR2);
	XTft_SetFrameBaseAddr(&TftInstance, TFT_FRAME_ADDR2);
	//XTft_FillScreenAtAddres(&TftInstance, 100,100,540,380,
	//					 0x0000FF,TFT_FRAME_ADDR);
	XTft_SetFrameBaseAddr(&TftInstance, TFT_FRAME_ADDR);*/
	}
	Status = TftWriteString(&TftInstance, (u8*)"TFT CONTROLLER\nThis is a Test!");
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	for (int i=0; i<1000000; i++);

	Status = TftDrawLine(&TftInstance, X1POS, Y1POS, X2POS, Y2POS,
				WHITECOLOR_VALUE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	for (int i=0; i<100000000; i++);
	/*
	 * Disable the display, the screen will be turned off.
	 */
	XTft_DisableDisplay(&TftInstance);

	XTft_Scroll(&TftInstance);
	Status = TftDrawLine(&TftInstance, X1POS + 10, Y1POS, X2POS + 10,
				 Y2POS, WHITECOLOR_VALUE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Enable the display. Screen will display two lines in white color.
	 * The first line from the left of screen is slightly above the
	 * second one indicating the scroll was successful.
	 */
	XTft_EnableDisplay(&TftInstance);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
* Write a string of characters to the TFT.
*
* @param	InstancePtr is a pointer to the XTft instance.
* @param	CharValue is a pointer to the character array to be written
*		to the TFT screen.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if unsuccessful.
*
* @note		None.
*
******************************************************************************/
int TftWriteString(XTft *InstancePtr, const u8 *CharValue)
{
	/*
	 * Writes a character from the string to the screen
	 * until it reaches null or end of the string.
	 */
	while (*CharValue != 0) {
		XTft_Write(InstancePtr, *CharValue);
		CharValue++;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
* Draws a line between two points with a specified color.
*
* @param	InstancePtr is a pointer to the XTft instance.
* @param	ColStartPos is the Start point of Column.
*		The valid value is 0 to (XTFT_DISPLAY_WIDTH - 1).
* @param	RowStartPos is the Start point of Row.
*		The valid value is 0 to (XTFT_DISPLAY_HEIGHT - 1).
* @param	ColEndPos is the End point of Column.
*		The valid value is 0 to (XTFT_DISPLAY_WIDTH - 1).
* @param	RowEndPos is the End point of Row.
*		The valid value is 0 to (XTFT_DISPLAY_HEIGHT - 1).
* @param	PixelVal is the Color Value to be put at pixel.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if unsuccessful.
*
* @note		None.
*
******************************************************************************/
static int TftDrawLine(XTft *InstancePtr, u32 ColStartPos, u32 RowStartPos,
			u32 ColEndPos, u32 RowEndPos, u32 PixelVal)
{
	u32 Slope;
	u32 YIntercept;
	u32 Xmin;
	u32 Ymin;
	u32 Xmax;
	u32 Ymax;
	u32 Index1;
	u32 Index2;
	u32 Mx;

	/*
	 * Check whether the given position of X,Y dimensions
	 * are below the limits of the screen.
	 */
	if (ColStartPos >= 0 && ColStartPos <= (XTFT_DISPLAY_WIDTH - 1) &&
		ColEndPos >= 0 && ColEndPos <= (XTFT_DISPLAY_WIDTH - 1) &&
		RowStartPos >= 0 && RowStartPos <= (XTFT_DISPLAY_HEIGHT - 1) &&
		RowEndPos >= 0 && RowEndPos <= (XTFT_DISPLAY_HEIGHT - 1)) {

		/*
		 * Check the exception case where slope can be infinite
		 * that is vertical line.
		 */
		if (ColEndPos-ColStartPos != 0) {
			/*
			 * Calculate slope.
			 */
			Slope = ((RowEndPos - RowStartPos) /
				(ColEndPos - ColStartPos) * 100000);

			/*
			 * Calculate y intercept.
			 */
			YIntercept = RowStartPos -
					((Slope / 100000) * ColStartPos);
		} else {
			/*
			 * Divide by zero.
			 */
			Slope = 0;
			YIntercept = (-1);
		}

		/*
		 * Update the min and max position by conditional checking.
		 */
		if (ColEndPos < ColStartPos) {
			Xmin = ColEndPos;
			Xmax = ColStartPos;
		} else {
			Xmin = ColStartPos;
			Xmax = ColEndPos;
		}
		if (RowEndPos < RowStartPos) {
			Ymin = RowEndPos;
			Ymax = RowStartPos;
		} else {
			Ymin = RowStartPos;
			Ymax = RowEndPos;
		}

		/*
		 * Increment X and Y position values and calculate
		 * slope at the corresponding x position. Check the condition
		 * for general line equation and set the pixel. Otherwise check
		 * for the case of vertical line.
		 */
		for (Index1 = Xmin; Index1 <= Xmax; Index1++) {
			Mx = (Slope * Index1) / 100000;
			for (Index2 = Ymin; Index2 <= Ymax; Index2++) {
				if ((Index2 - Mx) == YIntercept) {

					/*
					 * Calculate visible line.
					 */
					XTft_SetPixel(InstancePtr, Index1,
						 Index2, PixelVal);
				}
				else {
					/*
					 * Divide by zero.
					 */
					if((Slope == 0) &&
							(YIntercept == -1)) {

						/*
						 * Vertical line.
						 */
						XTft_SetPixel(InstancePtr,
							Index1, Index2,
							PixelVal);
					}
				}
			}
		}
		return XST_SUCCESS;
	} else {
		return XST_FAILURE;
	}

}

