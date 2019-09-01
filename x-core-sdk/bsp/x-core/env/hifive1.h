// See LICENSE for license details.

#ifndef _SIFIVE_HIFIVE1_H
#define _SIFIVE_HIFIVE1_H

#include <stdint.h>

/****************************************************************************
 * GPIO Connections
 *****************************************************************************/

// These are the GPIO bit offsets for the RGB LED on HiFive1 Board.
// These are also mapped to RGB LEDs on the Freedom E300 Arty
// FPGA
// Dev Kit.

//#define RED_LED_OFFSET   22
//#define GREEN_LED_OFFSET 19
//#define BLUE_LED_OFFSET  21

#define RED_LED_OFFSET    21
#define GREEN_LED_OFFSET  24//21
#define BLUE_LED_OFFSET   14//22
#define led4 14
#define led6 1
#define led7 2
#define led8 3
#define output 1
#define input 2  
             
#define ck_io_0   16 
#define ck_io_1   17 
#define ck_io_2   18 
#define ck_io_3   19 
#define ck_io_4   20 
#define ck_io_5   21 
#define ck_io_6   22 
#define ck_io_7   23 
#define ck_io_8   0  
#define ck_io_9   1  
#define ck_io_10  2  
#define ck_io_11  3  
#define ck_io_12  4  
#define ck_io_13  5  
#define ck_io_14  8  
#define ck_io_15  9  
#define ck_io_16  10 
#define ck_io_17  11 
#define ck_io_18  12 
#define ck_io_19  13 


#define ledD4_b   3
#define ledD4_g   2
#define ledD4_r   1  

#define ledD5_b  22
#define ledD5_g  21
#define ledD5_r  19

#define ledD6_b  13
#define ledD6_g  12
#define ledD6_r  11

#define ledD3	14

//************************DIGITAL*************************//
//usart1_io  
#define ja_0 24
#define D1_TX1 ja_1
#define ja_1 25
#define D0_RX1 ja_0
//iic_io
#define D2_SDA ck_io_2
#define D3_SCL ck_io_3

#define D4 ck_io_4
#define D5 ck_io_5
#define D6 ck_io_6
#define D7 ck_io_7
#define D8 ck_io_8
#define D9 ck_io_9
#define D10 ck_io_10
#define D11 ck_io_11
#define D12 ck_io_12
#define D13 ck_io_13
#define AREF ck_io_14
//************************ANALOG*************************//
#define A0  ck_io_15
#define A1  ck_io_16
#define A2  ck_io_17
#define A3  ck_io_18
#define A4  ck_io_19
#define A5  ck_io_1


//************************pmod*************************//
#define JP1_1 ck_io_15 
#define JP1_2 ck_io_16 
#define JP1_3 ck_io_17 
#define JP1_4 ck_io_18 
#define JP1_7 ck_io_19 

//************************smart-car-gpio*************************//
#define	run	1
#define stop 0
#define	left_monitor	D0_RX1
#define	right_monitor	D1_TX1

#define	motor_IN1		D3_SCL
#define	motor_IN2		D4
#define	motor_IN3		D5
#define	motor_IN4		D6

#define motor_ENA		D2_SDA
#define	motor_ENB		D7






// These are the GPIO bit offsets for the differen digital pins
 // on the headers for both the HiFive1 Board and the Freedom E300 Arty FPGA Dev Kit.
#define PIN_0_OFFSET  16
#define PIN_1_OFFSET  17
#define PIN_2_OFFSET  18
#define PIN_3_OFFSET  19
#define PIN_4_OFFSET  20
#define PIN_5_OFFSET  21
#define PIN_6_OFFSET  22
#define PIN_7_OFFSET  23
#define PIN_8_OFFSET  0
#define PIN_9_OFFSET  1
#define PIN_10_OFFSET 2
#define PIN_11_OFFSET 3
#define PIN_12_OFFSET 4
#define PIN_13_OFFSET 5
#define PIN_14_OFFSET 8 //This pin is not connected on either board.
#define PIN_15_OFFSET 9
#define PIN_16_OFFSET 10
#define PIN_17_OFFSET 11
#define PIN_18_OFFSET 12
#define PIN_19_OFFSET 13

// These are *PIN* numbers, not
// GPIO Offset Numbers.
#define PIN_SPI1_SCK    (13u)
#define PIN_SPI1_MISO   (12u)
#define PIN_SPI1_MOSI   (11u)
#define PIN_SPI1_SS0    (10u)
#define PIN_SPI1_SS1    (14u) 
#define PIN_SPI1_SS2    (15u)
#define PIN_SPI1_SS3    (16u)

#define SS_PIN_TO_CS_ID(x) \
  ((x==PIN_SPI1_SS0 ? 0 :		 \
    (x==PIN_SPI1_SS1 ? 1 :		 \
     (x==PIN_SPI1_SS2 ? 2 :		 \
      (x==PIN_SPI1_SS3 ? 3 :		 \
       -1))))) 


// These buttons are present only on the Freedom E300 Arty Dev Kit.
#ifdef HAS_BOARD_BUTTONS
#define BUTTON_0_OFFSET 15
#define BUTTON_1_OFFSET 30
#define BUTTON_2_OFFSET 31

#define INT_DEVICE_BUTTON_0 (INT_GPIO_BASE + BUTTON_0_OFFSET)
#define INT_DEVICE_BUTTON_1 (INT_GPIO_BASE + BUTTON_1_OFFSET)
#define INT_DEVICE_BUTTON_2 (INT_GPIO_BASE + BUTTON_2_OFFSET)

#endif

#define HAS_HFXOSC 1
#define HAS_LFROSC_BYPASS 1

#define RTC_FREQ 32768

void write_hex(int fd, unsigned long int hex);

#endif /* _SIFIVE_HIFIVE1_H */


