TARGET = led
CFLAGS += -O2 -DUSE_PLIC -DUSE_M_TIME   

BSP_BASE = ../../bsp

C_SRCS += led.c
C_SRCS += $(BSP_BASE)/$(BOARD)/drivers/plic/plic_driver.c

include $(BSP_BASE)/$(BOARD)/env/common.mk
