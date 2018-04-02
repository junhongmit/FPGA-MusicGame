################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

C_SRCS += \
../src/callback.c \
../src/paint.c \
../src/xaxidma_example_sg_intr.c \
../src/xtft_example.c \
../src/xtmrctr_intr_example.c 

OBJS += \
./src/callback.o \
./src/paint.o \
./src/xaxidma_example_sg_intr.o \
./src/xtft_example.o \
./src/xtmrctr_intr_example.o 

C_DEPS += \
./src/callback.d \
./src/paint.d \
./src/xaxidma_example_sg_intr.d \
./src/xtft_example.d \
./src/xtmrctr_intr_example.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O3 -g3 -c -fmessage-length=0 -MT"$@" -mxl-frequency -mxl-frequency -I../../standalone_bsp_0/microblaze_0/include -mlittle-endian -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v10.0 -mno-xl-soft-mul -mxl-multiply-high -mhard-float -mxl-float-convert -mxl-float-sqrt -Wl,--no-relax -ffunction-sections -fdata-sections -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


