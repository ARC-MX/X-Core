#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include <string.h>
#include "plic/plic_driver.h"
#include "encoding.h"
#include <unistd.h>
#include "stdatomic.h"
#define uchar unsigned char
#define uint unsigned int
uint32_t count=0;
uint32_t delay_mark=0;
void delay(uint32_t times);
void reset_demo (uint32_t times);
void GPIO_SET(uint32_t pin_num,uint32_t pin_val,uint32_t pin_model);

// Structures for registering different interrupt handlers
// for different parts of the application.
typedef void (*function_ptr_t) (void);


void no_interrupt_handler (void) {};

function_ptr_t g_ext_interrupt_handlers[PLIC_NUM_INTERRUPTS];


// Instance data for the PLIC.

plic_instance_t g_plic;

static plic_source int_nums;
void interrupt_handler(void)
{
    printf("interrupt_handler %d\r\n",int_nums);
}

/*Entry Point for PLIC Interrupt Handler*/
void handle_m_ext_interrupt(){
  plic_source int_num  = PLIC_claim_interrupt(&g_plic);
  if ((int_num >=1 ) && (int_num < PLIC_NUM_INTERRUPTS)) {
    int_nums = int_num;
    g_ext_interrupt_handlers[int_num]();
  }
  else {
    exit(1 + (uintptr_t) int_num);
  }
  PLIC_complete_interrupt(&g_plic, int_num);
}

 
/*Entry Point for Machine Timer Interrupt Handler*/

//void handle_timer_interrupt(){}
void handle_m_time_interrupt(){

   clear_csr(mie, MIP_MTIP);
   volatile uint64_t * mtime       = (uint64_t*) (CLINT_CTRL_ADDR + CLINT_MTIME);
   volatile uint64_t * mtimecmp    = (uint64_t*) (CLINT_CTRL_ADDR + CLINT_MTIMECMP);
    uint64_t now = *mtime;
    uint64_t then = now +0.5* RTC_FREQ;
   *mtimecmp = then;
  count++;
	
 if(count==1)
{
	uint32_t leds = GPIO_REG(GPIO_OUTPUT_VAL);
    GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD4_r));
	GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD5_r));
	GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD6_r));
}
 if(count==2)
{
	uint32_t leds = GPIO_REG(GPIO_OUTPUT_VAL);
       GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD4_g));
	GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD5_g));
	GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD6_g));
}
 if(count==3)
{
	uint32_t leds = GPIO_REG(GPIO_OUTPUT_VAL);
       GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD4_b));
	GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD5_b));
	GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD6_b));
}
 if(count==3)
{
	count=0;
}

  // read the current value of the LEDS and invert them.


    
      uint32_t leds = GPIO_REG(GPIO_OUTPUT_VAL);
      GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << BLUE_LED_OFFSET));
	
   
    //GPIO_REG(GPIO_OUTPUT_VAL) ^= ((0x1 << ledD4_r));
  // Re-enable the timer interrupt. 
  set_csr(mie, MIP_MTIP);
 
}


void print_instructions() {

  //write (STDOUT_FILENO, instructions_msg, strlen(instructions_msg));
  //write (STDOUT_FILENO, instructions_msg_sirv, strlen(instructions_msg_sirv));
  // printf ("%s",instructions_msg_sirv);

}




void reset_demo (uint32_t times){

  // Disable the machine & timer interrupts until setup is done.

    clear_csr(mie, MIP_MEIP);
    clear_csr(mie, MIP_MTIP);

    for (int ii = 0; ii < PLIC_NUM_INTERRUPTS; ii ++){
        g_ext_interrupt_handlers[ii] = interrupt_handler;
    }


    // Set the machine timer to go off in 3 seconds.
   
    volatile uint64_t * mtime       = (uint64_t*) (CLINT_CTRL_ADDR + CLINT_MTIME);
    volatile uint64_t * mtimecmp    = (uint64_t*) (CLINT_CTRL_ADDR + CLINT_MTIMECMP);
    uint64_t now = *mtime;
    uint64_t then = now + times*RTC_FREQ;
    *mtimecmp = then;

    // Enable the Machine-External bit in MIE
    set_csr(mie, MIP_MEIP);
    // Enable the Machine-Timer bit in MIE
    set_csr(mie, MIP_MTIP);
    // Enable interrupts in general.
    set_csr(mstatus, MSTATUS_MIE);
}


void GPIO_SET(uint32_t pin_num,uint32_t pin_val,uint32_t pin_model)
{
    if(pin_model==output)
     {	
	GPIO_REG(GPIO_OUTPUT_EN) |= (0x01<<pin_num);
        if(pin_val==1)
	{
	     GPIO_REG(GPIO_OUTPUT_VAL) |=(0x01<<pin_num);
	}
        if(pin_val==0)
	{
	     GPIO_REG(GPIO_OUTPUT_VAL) &=~(0x01<<pin_num);
	}
     }
    if(pin_model==input)
    {
	GPIO_REG(GPIO_INPUT_EN) |= (0x01<<pin_num);
    }

}

int main(int argc, char **argv)
{
 

	printf("led is setting\r\n");

  /**************************************************************************
   * Set up the PLIC
   *
   *************************************************************************/
   PLIC_init(&g_plic,
 	    PLIC_CTRL_ADDR,
 	    PLIC_NUM_INTERRUPTS,
 	    PLIC_NUM_PRIORITIES);

   reset_demo(1);
	GPIO_SET(ledD4_r,1,output);
	GPIO_SET(ledD4_g,1,output);
	GPIO_SET(ledD4_b,1,output);

	GPIO_SET(ledD5_r,1,output);
	GPIO_SET(ledD5_g,1,output);
	GPIO_SET(ledD5_b,1,output);

	GPIO_SET(ledD6_r,1,output);
	GPIO_SET(ledD6_g,1,output);
	GPIO_SET(ledD6_b,1,output);
	
	GPIO_SET(led4,1,output);
	GPIO_SET(led6,1,output);
	GPIO_SET(led7,1,output);	
	GPIO_SET(led8,1,output);
	
	GPIO_SET(BLUE_LED_OFFSET,1,output);

	printf("led is running\r\n");
  while (1){
	
  }
 

  return 0;

}







































