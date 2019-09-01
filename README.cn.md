# X-Core

X-Core是一款开源in-order 5级流水线 RISC-V 32-bit MCU级别处理器核，支持RV32IM指令集，主要用于个人学习、实验与教学。其中，Core部分代码参考[PULP RI5CY](https://github.com/pulp-platform/riscv)，SoC部分外设和SDK来自[蜂鸟E200](https://github.com/SI-RISCV/e200_opensource)。

X-Core主要特点：

- 5级流水线，RV32IM指令集，在FPGA平台的系统时钟达到50MHz
- 标准JTAG接口，支持GDB调试工具
- ITIM：64KB （可配置），DTIM：64KB（可配置）
- 提供多种外设，包括IIC，UART，SPI，GPIO，PWM，XADC，TIMER等
- QSPI接口访问其他片外存储

X-Core SoC外设：

- CLINT

  处理器核局部中断控制器，主要实现 RISC-V 架构手册中规定的标准计时器（Timer）和软件中断功能。

- PLIC

  实现 RISC-V 架构手册中规定的 PLIC 功能，该PLIC 能够支持多个中断源，并且每个中断可以配置中断优先级。所有的中断经过 PLIC 仲裁后,生成一根最终的中断信号通给处理器核作为其外部中断信号。

- JTAG

  JTAG连接模块用于连接系统外部调试器与内部的调试模块。

- Debug Module

  用于支持外部 JTAG 通过该模块调试处理器核，是的处理器核能够通过 GDB 对其进行交互式调试，譬如设置断点，单步执行等调试功能。

- Quad-SPI Flash

  专用于连接外部 Flash的Quad-SPI（QSPI）接口。指令和数据均可以存储于外部的 Flash 之中，并且该 QSPI 接口还可以被软件配置成为 eXecute-In-Place 模式，在此模式下， Flash可以被当作一段只读区间直接被当做内存读取。在默认上电之后， QSPI 即处于该模式之下，由于Flash 掉电不丢失的特性， 因此可以将系统的启动程序存放于外部的 Flash 中，然后处理器核通过 eXecute-In-Place 模式的 QSPI 接口直接访问外部Flash 加载启动程序启动。

- GPIO

  用于提供一组 32 I/O 的通用输入输出接口。每个I/O 可用被软件配置为输入或者输出，如果是输出可以设置具体的输出值。每个I/O 还可以被配置为IOF（Hardware I/O Functions），也就是将I/O 供 SoC 内部的其他模块复用，其中每个 I/O 均可以供两个内部模块复用，软件可以通过配置每个I/O 使其选择 IOF0 或者 IOF1 来选择信号来源。另外，每个GPIO 的 I/O 均作为一个中断源连接到 PLIC的中断源上。

- SPI

  标准模式 8位数据位模式支持单从机 DataFifo深度为16。

- UART

  波特率为128000 可直接使用printf调用。

- PWM

  脉宽调节器。

- WatchDog

  该计数器位于 Always-on Domain 中，因此使用低速时钟进行计数，并且可以通过配置其计数的目标值产生中断。

- IIC

  IIC模块中iic sck为100khz 地址模式为7位 SDA高有效。

- XADC

  保留了vaux1，vaux2，vaux9，vaux10四个通道。

## 开发板

* [Perf-V FPGA开发板](http://perfv.org/)

![Perf-V FPGA开发板图片](http://perfv.org/images/home/board_intro.png)

## 交流讨论

- QQ群：806854399
- 论坛：http://forum.perfv.org/

