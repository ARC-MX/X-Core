/*
Copyright 2019 PerfXLab (Beijing) Technology Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/    

`define RISCV_FPGA_SIM //2018.5.14
`define SYNTHESIS      //2018.5.14
`define DIS_CACHE
//`define DIS_ISA_M    //disable m-type riscv isa

// no traces for synthesis, they are not synthesizable
`ifndef SIMULATION
`ifndef SYNTHESIS
`ifndef RISCV_FPGA_EMUL
//`define TRACE_EXECUTION
`endif
`endif
`endif

`ifdef RISCV_FPGA_SIM
//`define TRACE_EXECUTION
`endif

