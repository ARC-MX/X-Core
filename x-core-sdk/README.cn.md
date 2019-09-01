项目提供一个典型的示例程序 hello_world可运行于Perf-V开发板(基于X-Core),使用 x-core-sdk 平台按照如下步骤可以运行。

1. 安装RISC-V Software Tools，未来我们将提供预编译好的工具链
2. 准备好X-Core的FPGA开发板，将bitstream文件或者mcs文件烧录至FPGA中待命，且用JTAG将FPGA开发板与PC链接
3. 编译和执行示例程序

```makefile
cd <your_sdk_dir>

make dasm PROGRAM=hello_world NANO_PFLOAT=0
#其中NANO_PFLOAT=0 指 明newlib-nano 的 printf 函数无需支持浮点数. 此处没有指定 Makefile 中的 DOWNLOAD 选项,则默认采用“将程序从 Flash 上载至 ITCM 进行执行的方式”进行编译。

make upload PROGRAM=hello_world
```

