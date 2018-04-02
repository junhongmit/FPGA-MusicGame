# FPGA-MusicGame

操作：键盘上下键选择游戏难度，按Enter键开始游戏。游戏过程中四个滑道分别对应DFJK四个键，滑块到达屏幕下方时按下指定按钮消除滑块。
游戏结束后按R重新游戏，按S键返回主菜单。

编译环境：Vivado 2017.1
软件部分文件夹：mbsys_VGA_test_bsp_xtft_example_1

其中——
display.h为自己定义的贴图API头文件。
image.h为由Image2LCD生成的背景和难度选择部分贴图的常数数组。
image1.h为滑块的贴图常数数组。
myhead.h为自定义的常数头文件。
paint.c为绘图部分paint（）函数的代码文件。
tmrctr_head.h为移植代码前自动生成的遗留测试头文件。
xaxidma_example_sg_intr.c为导入的DMA测试SDK代码文件，并依此改写了自己定义的贴图API函数。
xtft_example.c为main函数所在代码文件，亦是由导入的VGA测试代码文件修改而来的。
xtmrctr_intr_example.c为Timer外设驱动函数所在代码文件，用于定时刷新画面。

![软件部分代码结构树](https://github.com/john-junhong/FPGA-MusicGame/blob/master/image1.jpg)
图1. 软件部分代码结构树

![贴图源文件和Image2LCD软件生成的图片数组文件](https://github.com/john-junhong/FPGA-MusicGame/blob/master/image2.jpg)
图2. 贴图源文件和Image2LCD软件生成的图片数组文件