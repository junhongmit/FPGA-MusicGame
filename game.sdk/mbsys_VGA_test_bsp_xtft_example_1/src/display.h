
#ifndef DISPLAY_H /* prevent circular inclusions */
#define DISPLAY_H /* by using protection macros */

/************************** Function Prototypes ****************************/

#include "xparameters.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xil_io.h"
/*
 * Functions for basic driver operations in xtft.c.
 */


/************************** Variable Definitions ***************************/

/************************** Function Definitions ***************************/

u32 Round(double val);
int BitBlt(u32 x1, u32 y1, u32 width1, u32 height1, u8* image, u32 x0,u32 y0,u32 img_width);
int TransparentBlt(u32 x1, u32 y1, u32 width1, u32 height1, u8* image, u32 x0,u32 y0, u32 width, u32 height ,u32 trans);

#endif /* XTFT_H */

/** @} */
