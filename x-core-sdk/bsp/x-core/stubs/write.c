/* See LICENSE of license details. */

#include <stdint.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>

#include "platform.h"
#include "stub.h"

ssize_t _write(int fd, const void* ptr, size_t len)
{
  const uint8_t * current = (const char *)ptr;
  //const void* current = (const void *)ptr;

  if (isatty(fd)) {
    for (size_t jj = 0; jj < len; jj++) {
	if (current[jj] == '\n') {
	        while ((UART0_REG(UART_REG_STAT) & 0x0004) != 0x0004) ;
	        UART0_REG(UART_REG_TXFIFO) = '\r';
	}
      while ((UART0_REG(UART_REG_STAT) & 0x0004) != 0x0004) ;
      UART0_REG(UART_REG_TXFIFO) = current[jj];
     
    }
    return len;
  }

  return _stub(EBADF);
}
