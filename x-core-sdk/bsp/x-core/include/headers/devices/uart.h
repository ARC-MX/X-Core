// See LICENSE for license details.

#ifndef _XCORE_UART_H
#define _XCORE_UART_H

/* Register offsets */
#define UART_REG_RXFIFO 0x00
#define UART_REG_TXFIFO 0x04
#define UART_REG_STAT 0x08
#define UART_REG_CTRL 0x0C
/* TXCTRL register */
#define UART_TXEN               0x1
#define UART_TXWM(x)            (((x) & 0xffff) << 16)

/* RXCTRL register */
#define UART_RXEN               0x1
#define UART_RXWM(x)            (((x) & 0xffff) << 16)

/* IP register */
#define UART_IP_TXWM            0x1
#define UART_IP_RXWM            0x2

#endif /* _XCORE_UART_H */
