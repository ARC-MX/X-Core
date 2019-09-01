`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/08/28 16:08:45
// Design Name: 
// Module Name: design_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module design_top
   (ACLK,
    ARESETN,
    CLINT_araddr,
    CLINT_arburst,
    CLINT_arcache,
    CLINT_arid,
    CLINT_arlen,
    CLINT_arlock,
    CLINT_arprot,
    CLINT_arqos,
    CLINT_arready,
    CLINT_arregion,
    CLINT_arsize,
    CLINT_arvalid,
    CLINT_awaddr,
    CLINT_awburst,
    CLINT_awcache,
    CLINT_awid,
    CLINT_awlen,
    CLINT_awlock,
    CLINT_awprot,
    CLINT_awqos,
    CLINT_awready,
    CLINT_awregion,
    CLINT_awsize,
    CLINT_awvalid,
    CLINT_bid,
    CLINT_bready,
    CLINT_bresp,
    CLINT_bvalid,
    CLINT_rdata,
    CLINT_rid,
    CLINT_rlast,
    CLINT_rready,
    CLINT_rresp,
    CLINT_rvalid,
    CLINT_wdata,
    CLINT_wlast,
    CLINT_wready,
    CLINT_wstrb,
    CLINT_wvalid,
    DATA_araddr,
    DATA_arburst,
    DATA_arcache,
    DATA_arid,
    DATA_arlen,
    DATA_arlock,
    DATA_arprot,
    DATA_arqos,
    DATA_arready,
    DATA_arsize,
    DATA_arvalid,
    DATA_awaddr,
    DATA_awburst,
    DATA_awcache,
    DATA_awid,
    DATA_awlen,
    DATA_awlock,
    DATA_awprot,
    DATA_awqos,
    DATA_awready,
    DATA_awsize,
    DATA_awvalid,
    DATA_bid,
    DATA_bready,
    DATA_bresp,
    DATA_bvalid,
    DATA_rdata,
    DATA_rid,
    DATA_rlast,
    DATA_rready,
    DATA_rresp,
    DATA_rvalid,
    DATA_wdata,
    DATA_wlast,
    DATA_wready,
    DATA_wstrb,
    DATA_wvalid,
    DEBUG_araddr,
    DEBUG_arburst,
    DEBUG_arcache,
    DEBUG_arid,
    DEBUG_arlen,
    DEBUG_arlock,
    DEBUG_arprot,
    DEBUG_arqos,
    DEBUG_arready,
    DEBUG_arregion,
    DEBUG_arsize,
    DEBUG_arvalid,
    DEBUG_awaddr,
    DEBUG_awburst,
    DEBUG_awcache,
    DEBUG_awid,
    DEBUG_awlen,
    DEBUG_awlock,
    DEBUG_awprot,
    DEBUG_awqos,
    DEBUG_awready,
    DEBUG_awregion,
    DEBUG_awsize,
    DEBUG_awvalid,
    DEBUG_bid,
    DEBUG_bready,
    DEBUG_bresp,
    DEBUG_bvalid,
    DEBUG_rdata,
    DEBUG_rid,
    DEBUG_rlast,
    DEBUG_rready,
    DEBUG_rresp,
    DEBUG_rvalid,
    DEBUG_wdata,
    DEBUG_wlast,
    DEBUG_wready,
    DEBUG_wstrb,
    DEBUG_wvalid,
    IIC_scl_io,
    IIC_sda_io,
    INSTR_araddr,
    INSTR_arburst,
    INSTR_arcache,
    INSTR_arid,
    INSTR_arlen,
    INSTR_arlock,
    INSTR_arprot,
    INSTR_arqos,
    INSTR_arready,
    INSTR_arsize,
    INSTR_arvalid,
    INSTR_awaddr,
    INSTR_awburst,
    INSTR_awcache,
    INSTR_awid,
    INSTR_awlen,
    INSTR_awlock,
    INSTR_awprot,
    INSTR_awqos,
    INSTR_awready,
    INSTR_awsize,
    INSTR_awvalid,
    INSTR_bid,
    INSTR_bready,
    INSTR_bresp,
    INSTR_bvalid,
    INSTR_rdata,
    INSTR_rid,
    INSTR_rlast,
    INSTR_rready,
    INSTR_rresp,
    INSTR_rvalid,
    INSTR_wdata,
    INSTR_wlast,
    INSTR_wready,
    INSTR_wstrb,
    INSTR_wvalid,
    MEM_araddr,
    MEM_arburst,
    MEM_arcache,
    MEM_arid,
    MEM_arlen,
    MEM_arlock,
    MEM_arprot,
    MEM_arqos,
    MEM_arready,
    MEM_arregion,
    MEM_arsize,
    MEM_arvalid,
    MEM_awaddr,
    MEM_awburst,
    MEM_awcache,
    MEM_awid,
    MEM_awlen,
    MEM_awlock,
    MEM_awprot,
    MEM_awqos,
    MEM_awready,
    MEM_awregion,
    MEM_awsize,
    MEM_awvalid,
    MEM_bid,
    MEM_bready,
    MEM_bresp,
    MEM_bvalid,
    MEM_rdata,
    MEM_rid,
    MEM_rlast,
    MEM_rready,
    MEM_rresp,
    MEM_rvalid,
    MEM_wdata,
    MEM_wlast,
    MEM_wready,
    MEM_wstrb,
    MEM_wvalid,
    PLIC_araddr,
    PLIC_arburst,
    PLIC_arcache,
    PLIC_arid,
    PLIC_arlen,
    PLIC_arlock,
    PLIC_arprot,
    PLIC_arqos,
    PLIC_arready,
    PLIC_arregion,
    PLIC_arsize,
    PLIC_arvalid,
    PLIC_awaddr,
    PLIC_awburst,
    PLIC_awcache,
    PLIC_awid,
    PLIC_awlen,
    PLIC_awlock,
    PLIC_awprot,
    PLIC_awqos,
    PLIC_awready,
    PLIC_awregion,
    PLIC_awsize,
    PLIC_awvalid,
    PLIC_bid,
    PLIC_bready,
    PLIC_bresp,
    PLIC_bvalid,
    PLIC_rdata,
    PLIC_rid,
    PLIC_rlast,
    PLIC_rready,
    PLIC_rresp,
    PLIC_rvalid,
    PLIC_wdata,
    PLIC_wlast,
    PLIC_wready,
    PLIC_wstrb,
    PLIC_wvalid,
    PPI_araddr,
    PPI_arburst,
    PPI_arcache,
    PPI_arid,
    PPI_arlen,
    PPI_arlock,
    PPI_arprot,
    PPI_arqos,
    PPI_arready,
    PPI_arregion,
    PPI_arsize,
    PPI_arvalid,
    PPI_awaddr,
    PPI_awburst,
    PPI_awcache,
    PPI_awid,
    PPI_awlen,
    PPI_awlock,
    PPI_awprot,
    PPI_awqos,
    PPI_awready,
    PPI_awregion,
    PPI_awsize,
    PPI_awvalid,
    PPI_bid,
    PPI_bready,
    PPI_bresp,
    PPI_bvalid,
    PPI_rdata,
    PPI_rid,
    PPI_rlast,
    PPI_rready,
    PPI_rresp,
    PPI_rvalid,
    PPI_wdata,
    PPI_wlast,
    PPI_wready,
    PPI_wstrb,
    PPI_wvalid,
    UART_rxd,
    UART_txd,
    Vaux10_0_v_n,
    Vaux10_0_v_p,
    Vaux1_0_v_n,
    Vaux1_0_v_p,
    Vaux2_0_v_n,
    Vaux2_0_v_p,
    Vaux9_0_v_n,
    Vaux9_0_v_p,
    Vp_Vn_v_n,
    Vp_Vn_v_p,
    iic_intr,
    io0_i_0,
    io0_o_0,
    io0_t_0,
    io1_i_0,
    io1_o_0,
    io1_t_0,
    io_port_cs_0,
    io_port_dq_0_i,
    io_port_dq_0_o,
    io_port_dq_0_oe,
    io_port_dq_1_i,
    io_port_dq_1_o,
    io_port_dq_1_oe,
    io_port_dq_2_i,
    io_port_dq_2_o,
    io_port_dq_2_oe,
    io_port_dq_3_i,
    io_port_dq_3_o,
    io_port_dq_3_oe,
    io_port_sck,
    pwm0,
    sck_i_0,
    sck_o_0,
    sck_t_0,
    spi0_intr,
    spi1_intr,
    ss_i_0,
    ss_o_0,
    ss_t_0,
    timer0_intr,
    uart_intr);
  input ACLK;
  input ARESETN;
  output [31:0]CLINT_araddr;
  output [1:0]CLINT_arburst;
  output [3:0]CLINT_arcache;
  output [1:0]CLINT_arid;
  output [7:0]CLINT_arlen;
  output [0:0]CLINT_arlock;
  output [2:0]CLINT_arprot;
  output [3:0]CLINT_arqos;
  input [0:0]CLINT_arready;
  output [3:0]CLINT_arregion;
  output [2:0]CLINT_arsize;
  output [0:0]CLINT_arvalid;
  output [31:0]CLINT_awaddr;
  output [1:0]CLINT_awburst;
  output [3:0]CLINT_awcache;
  output [1:0]CLINT_awid;
  output [7:0]CLINT_awlen;
  output [0:0]CLINT_awlock;
  output [2:0]CLINT_awprot;
  output [3:0]CLINT_awqos;
  input [0:0]CLINT_awready;
  output [3:0]CLINT_awregion;
  output [2:0]CLINT_awsize;
  output [0:0]CLINT_awvalid;
  input [1:0]CLINT_bid;
  output [0:0]CLINT_bready;
  input [1:0]CLINT_bresp;
  input [0:0]CLINT_bvalid;
  input [31:0]CLINT_rdata;
  input [1:0]CLINT_rid;
  input [0:0]CLINT_rlast;
  output [0:0]CLINT_rready;
  input [1:0]CLINT_rresp;
  input [0:0]CLINT_rvalid;
  output [31:0]CLINT_wdata;
  output [0:0]CLINT_wlast;
  input [0:0]CLINT_wready;
  output [3:0]CLINT_wstrb;
  output [0:0]CLINT_wvalid;
  input [31:0]DATA_araddr;
  input [1:0]DATA_arburst;
  input [3:0]DATA_arcache;
  input [1:0]DATA_arid;
  input [7:0]DATA_arlen;
  input [0:0]DATA_arlock;
  input [2:0]DATA_arprot;
  input [3:0]DATA_arqos;
  output [0:0]DATA_arready;
  input [2:0]DATA_arsize;
  input [0:0]DATA_arvalid;
  input [31:0]DATA_awaddr;
  input [1:0]DATA_awburst;
  input [3:0]DATA_awcache;
  input [1:0]DATA_awid;
  input [7:0]DATA_awlen;
  input [0:0]DATA_awlock;
  input [2:0]DATA_awprot;
  input [3:0]DATA_awqos;
  output [0:0]DATA_awready;
  input [2:0]DATA_awsize;
  input [0:0]DATA_awvalid;
  output [1:0]DATA_bid;
  input [0:0]DATA_bready;
  output [1:0]DATA_bresp;
  output [0:0]DATA_bvalid;
  output [31:0]DATA_rdata;
  output [1:0]DATA_rid;
  output [0:0]DATA_rlast;
  input [0:0]DATA_rready;
  output [1:0]DATA_rresp;
  output [0:0]DATA_rvalid;
  input [31:0]DATA_wdata;
  input [0:0]DATA_wlast;
  output [0:0]DATA_wready;
  input [3:0]DATA_wstrb;
  input [0:0]DATA_wvalid;
  output [31:0]DEBUG_araddr;
  output [1:0]DEBUG_arburst;
  output [3:0]DEBUG_arcache;
  output [1:0]DEBUG_arid;
  output [7:0]DEBUG_arlen;
  output [0:0]DEBUG_arlock;
  output [2:0]DEBUG_arprot;
  output [3:0]DEBUG_arqos;
  input [0:0]DEBUG_arready;
  output [3:0]DEBUG_arregion;
  output [2:0]DEBUG_arsize;
  output [0:0]DEBUG_arvalid;
  output [31:0]DEBUG_awaddr;
  output [1:0]DEBUG_awburst;
  output [3:0]DEBUG_awcache;
  output [1:0]DEBUG_awid;
  output [7:0]DEBUG_awlen;
  output [0:0]DEBUG_awlock;
  output [2:0]DEBUG_awprot;
  output [3:0]DEBUG_awqos;
  input [0:0]DEBUG_awready;
  output [3:0]DEBUG_awregion;
  output [2:0]DEBUG_awsize;
  output [0:0]DEBUG_awvalid;
  input [1:0]DEBUG_bid;
  output [0:0]DEBUG_bready;
  input [1:0]DEBUG_bresp;
  input [0:0]DEBUG_bvalid;
  input [31:0]DEBUG_rdata;
  input [1:0]DEBUG_rid;
  input [0:0]DEBUG_rlast;
  output [0:0]DEBUG_rready;
  input [1:0]DEBUG_rresp;
  input [0:0]DEBUG_rvalid;
  output [31:0]DEBUG_wdata;
  output [0:0]DEBUG_wlast;
  input [0:0]DEBUG_wready;
  output [3:0]DEBUG_wstrb;
  output [0:0]DEBUG_wvalid;
  inout IIC_scl_io;
  inout IIC_sda_io;
  input [31:0]INSTR_araddr;
  input [1:0]INSTR_arburst;
  input [3:0]INSTR_arcache;
  input [1:0]INSTR_arid;
  input [7:0]INSTR_arlen;
  input [0:0]INSTR_arlock;
  input [2:0]INSTR_arprot;
  input [3:0]INSTR_arqos;
  output [0:0]INSTR_arready;
  input [2:0]INSTR_arsize;
  input [0:0]INSTR_arvalid;
  input [31:0]INSTR_awaddr;
  input [1:0]INSTR_awburst;
  input [3:0]INSTR_awcache;
  input [1:0]INSTR_awid;
  input [7:0]INSTR_awlen;
  input [0:0]INSTR_awlock;
  input [2:0]INSTR_awprot;
  input [3:0]INSTR_awqos;
  output [0:0]INSTR_awready;
  input [2:0]INSTR_awsize;
  input [0:0]INSTR_awvalid;
  output [1:0]INSTR_bid;
  input [0:0]INSTR_bready;
  output [1:0]INSTR_bresp;
  output [0:0]INSTR_bvalid;
  output [31:0]INSTR_rdata;
  output [1:0]INSTR_rid;
  output [0:0]INSTR_rlast;
  input [0:0]INSTR_rready;
  output [1:0]INSTR_rresp;
  output [0:0]INSTR_rvalid;
  input [31:0]INSTR_wdata;
  input [0:0]INSTR_wlast;
  output [0:0]INSTR_wready;
  input [3:0]INSTR_wstrb;
  input [0:0]INSTR_wvalid;
  output [31:0]MEM_araddr;
  output [1:0]MEM_arburst;
  output [3:0]MEM_arcache;
  output [1:0]MEM_arid;
  output [7:0]MEM_arlen;
  output [0:0]MEM_arlock;
  output [2:0]MEM_arprot;
  output [3:0]MEM_arqos;
  input [0:0]MEM_arready;
  output [3:0]MEM_arregion;
  output [2:0]MEM_arsize;
  output [0:0]MEM_arvalid;
  output [31:0]MEM_awaddr;
  output [1:0]MEM_awburst;
  output [3:0]MEM_awcache;
  output [1:0]MEM_awid;
  output [7:0]MEM_awlen;
  output [0:0]MEM_awlock;
  output [2:0]MEM_awprot;
  output [3:0]MEM_awqos;
  input [0:0]MEM_awready;
  output [3:0]MEM_awregion;
  output [2:0]MEM_awsize;
  output [0:0]MEM_awvalid;
  input [1:0]MEM_bid;
  output [0:0]MEM_bready;
  input [1:0]MEM_bresp;
  input [0:0]MEM_bvalid;
  input [31:0]MEM_rdata;
  input [1:0]MEM_rid;
  input [0:0]MEM_rlast;
  output [0:0]MEM_rready;
  input [1:0]MEM_rresp;
  input [0:0]MEM_rvalid;
  output [31:0]MEM_wdata;
  output [0:0]MEM_wlast;
  input [0:0]MEM_wready;
  output [3:0]MEM_wstrb;
  output [0:0]MEM_wvalid;
  output [31:0]PLIC_araddr;
  output [1:0]PLIC_arburst;
  output [3:0]PLIC_arcache;
  output [1:0]PLIC_arid;
  output [7:0]PLIC_arlen;
  output [0:0]PLIC_arlock;
  output [2:0]PLIC_arprot;
  output [3:0]PLIC_arqos;
  input [0:0]PLIC_arready;
  output [3:0]PLIC_arregion;
  output [2:0]PLIC_arsize;
  output [0:0]PLIC_arvalid;
  output [31:0]PLIC_awaddr;
  output [1:0]PLIC_awburst;
  output [3:0]PLIC_awcache;
  output [1:0]PLIC_awid;
  output [7:0]PLIC_awlen;
  output [0:0]PLIC_awlock;
  output [2:0]PLIC_awprot;
  output [3:0]PLIC_awqos;
  input [0:0]PLIC_awready;
  output [3:0]PLIC_awregion;
  output [2:0]PLIC_awsize;
  output [0:0]PLIC_awvalid;
  input [1:0]PLIC_bid;
  output [0:0]PLIC_bready;
  input [1:0]PLIC_bresp;
  input [0:0]PLIC_bvalid;
  input [31:0]PLIC_rdata;
  input [1:0]PLIC_rid;
  input [0:0]PLIC_rlast;
  output [0:0]PLIC_rready;
  input [1:0]PLIC_rresp;
  input [0:0]PLIC_rvalid;
  output [31:0]PLIC_wdata;
  output [0:0]PLIC_wlast;
  input [0:0]PLIC_wready;
  output [3:0]PLIC_wstrb;
  output [0:0]PLIC_wvalid;
  output [31:0]PPI_araddr;
  output [1:0]PPI_arburst;
  output [3:0]PPI_arcache;
  output [1:0]PPI_arid;
  output [7:0]PPI_arlen;
  output [0:0]PPI_arlock;
  output [2:0]PPI_arprot;
  output [3:0]PPI_arqos;
  input [0:0]PPI_arready;
  output [3:0]PPI_arregion;
  output [2:0]PPI_arsize;
  output [0:0]PPI_arvalid;
  output [31:0]PPI_awaddr;
  output [1:0]PPI_awburst;
  output [3:0]PPI_awcache;
  output [1:0]PPI_awid;
  output [7:0]PPI_awlen;
  output [0:0]PPI_awlock;
  output [2:0]PPI_awprot;
  output [3:0]PPI_awqos;
  input [0:0]PPI_awready;
  output [3:0]PPI_awregion;
  output [2:0]PPI_awsize;
  output [0:0]PPI_awvalid;
  input [1:0]PPI_bid;
  output [0:0]PPI_bready;
  input [1:0]PPI_bresp;
  input [0:0]PPI_bvalid;
  input [31:0]PPI_rdata;
  input [1:0]PPI_rid;
  input [0:0]PPI_rlast;
  output [0:0]PPI_rready;
  input [1:0]PPI_rresp;
  input [0:0]PPI_rvalid;
  output [31:0]PPI_wdata;
  output [0:0]PPI_wlast;
  input [0:0]PPI_wready;
  output [3:0]PPI_wstrb;
  output [0:0]PPI_wvalid;
  input UART_rxd;
  output UART_txd;
  input Vaux10_0_v_n;
  input Vaux10_0_v_p;
  input Vaux1_0_v_n;
  input Vaux1_0_v_p;
  input Vaux2_0_v_n;
  input Vaux2_0_v_p;
  input Vaux9_0_v_n;
  input Vaux9_0_v_p;
  input Vp_Vn_v_n;
  input Vp_Vn_v_p;
  output iic_intr;
  input io0_i_0;
  output io0_o_0;
  output io0_t_0;
  input io1_i_0;
  output io1_o_0;
  output io1_t_0;
  output io_port_cs_0;
  input io_port_dq_0_i;
  output io_port_dq_0_o;
  output io_port_dq_0_oe;
  input io_port_dq_1_i;
  output io_port_dq_1_o;
  output io_port_dq_1_oe;
  input io_port_dq_2_i;
  output io_port_dq_2_o;
  output io_port_dq_2_oe;
  input io_port_dq_3_i;
  output io_port_dq_3_o;
  output io_port_dq_3_oe;
  output io_port_sck;
  output pwm0;
  input sck_i_0;
  output sck_o_0;
  output sck_t_0;
  output spi0_intr;
  output spi1_intr;
  input [0:0]ss_i_0;
  output [0:0]ss_o_0;
  output ss_t_0;
  output timer0_intr;
  output uart_intr;

  wire ACLK;
  wire ARESETN;
  wire [31:0]CLINT_araddr;
  wire [1:0]CLINT_arburst;
  wire [3:0]CLINT_arcache;
  wire [1:0]CLINT_arid;
  wire [7:0]CLINT_arlen;
  wire [0:0]CLINT_arlock;
  wire [2:0]CLINT_arprot;
  wire [3:0]CLINT_arqos;
  wire [0:0]CLINT_arready;
  wire [3:0]CLINT_arregion;
  wire [2:0]CLINT_arsize;
  wire [0:0]CLINT_arvalid;
  wire [31:0]CLINT_awaddr;
  wire [1:0]CLINT_awburst;
  wire [3:0]CLINT_awcache;
  wire [1:0]CLINT_awid;
  wire [7:0]CLINT_awlen;
  wire [0:0]CLINT_awlock;
  wire [2:0]CLINT_awprot;
  wire [3:0]CLINT_awqos;
  wire [0:0]CLINT_awready;
  wire [3:0]CLINT_awregion;
  wire [2:0]CLINT_awsize;
  wire [0:0]CLINT_awvalid;
  wire [1:0]CLINT_bid;
  wire [0:0]CLINT_bready;
  wire [1:0]CLINT_bresp;
  wire [0:0]CLINT_bvalid;
  wire [31:0]CLINT_rdata;
  wire [1:0]CLINT_rid;
  wire [0:0]CLINT_rlast;
  wire [0:0]CLINT_rready;
  wire [1:0]CLINT_rresp;
  wire [0:0]CLINT_rvalid;
  wire [31:0]CLINT_wdata;
  wire [0:0]CLINT_wlast;
  wire [0:0]CLINT_wready;
  wire [3:0]CLINT_wstrb;
  wire [0:0]CLINT_wvalid;
  wire [31:0]DATA_araddr;
  wire [1:0]DATA_arburst;
  wire [3:0]DATA_arcache;
  wire [1:0]DATA_arid;
  wire [7:0]DATA_arlen;
  wire [0:0]DATA_arlock;
  wire [2:0]DATA_arprot;
  wire [3:0]DATA_arqos;
  wire [0:0]DATA_arready;
  wire [2:0]DATA_arsize;
  wire [0:0]DATA_arvalid;
  wire [31:0]DATA_awaddr;
  wire [1:0]DATA_awburst;
  wire [3:0]DATA_awcache;
  wire [1:0]DATA_awid;
  wire [7:0]DATA_awlen;
  wire [0:0]DATA_awlock;
  wire [2:0]DATA_awprot;
  wire [3:0]DATA_awqos;
  wire [0:0]DATA_awready;
  wire [2:0]DATA_awsize;
  wire [0:0]DATA_awvalid;
  wire [1:0]DATA_bid;
  wire [0:0]DATA_bready;
  wire [1:0]DATA_bresp;
  wire [0:0]DATA_bvalid;
  wire [31:0]DATA_rdata;
  wire [1:0]DATA_rid;
  wire [0:0]DATA_rlast;
  wire [0:0]DATA_rready;
  wire [1:0]DATA_rresp;
  wire [0:0]DATA_rvalid;
  wire [31:0]DATA_wdata;
  wire [0:0]DATA_wlast;
  wire [0:0]DATA_wready;
  wire [3:0]DATA_wstrb;
  wire [0:0]DATA_wvalid;
  wire [31:0]DEBUG_araddr;
  wire [1:0]DEBUG_arburst;
  wire [3:0]DEBUG_arcache;
  wire [1:0]DEBUG_arid;
  wire [7:0]DEBUG_arlen;
  wire [0:0]DEBUG_arlock;
  wire [2:0]DEBUG_arprot;
  wire [3:0]DEBUG_arqos;
  wire [0:0]DEBUG_arready;
  wire [3:0]DEBUG_arregion;
  wire [2:0]DEBUG_arsize;
  wire [0:0]DEBUG_arvalid;
  wire [31:0]DEBUG_awaddr;
  wire [1:0]DEBUG_awburst;
  wire [3:0]DEBUG_awcache;
  wire [1:0]DEBUG_awid;
  wire [7:0]DEBUG_awlen;
  wire [0:0]DEBUG_awlock;
  wire [2:0]DEBUG_awprot;
  wire [3:0]DEBUG_awqos;
  wire [0:0]DEBUG_awready;
  wire [3:0]DEBUG_awregion;
  wire [2:0]DEBUG_awsize;
  wire [0:0]DEBUG_awvalid;
  wire [1:0]DEBUG_bid;
  wire [0:0]DEBUG_bready;
  wire [1:0]DEBUG_bresp;
  wire [0:0]DEBUG_bvalid;
  wire [31:0]DEBUG_rdata;
  wire [1:0]DEBUG_rid;
  wire [0:0]DEBUG_rlast;
  wire [0:0]DEBUG_rready;
  wire [1:0]DEBUG_rresp;
  wire [0:0]DEBUG_rvalid;
  wire [31:0]DEBUG_wdata;
  wire [0:0]DEBUG_wlast;
  wire [0:0]DEBUG_wready;
  wire [3:0]DEBUG_wstrb;
  wire [0:0]DEBUG_wvalid;
  wire IIC_scl_i;
  wire IIC_scl_io;
  wire IIC_scl_o;
  wire IIC_scl_t;
  wire IIC_sda_i;
  wire IIC_sda_io;
  wire IIC_sda_o;
  wire IIC_sda_t;
  wire [31:0]INSTR_araddr;
  wire [1:0]INSTR_arburst;
  wire [3:0]INSTR_arcache;
  wire [1:0]INSTR_arid;
  wire [7:0]INSTR_arlen;
  wire [0:0]INSTR_arlock;
  wire [2:0]INSTR_arprot;
  wire [3:0]INSTR_arqos;
  wire [0:0]INSTR_arready;
  wire [2:0]INSTR_arsize;
  wire [0:0]INSTR_arvalid;
  wire [31:0]INSTR_awaddr;
  wire [1:0]INSTR_awburst;
  wire [3:0]INSTR_awcache;
  wire [1:0]INSTR_awid;
  wire [7:0]INSTR_awlen;
  wire [0:0]INSTR_awlock;
  wire [2:0]INSTR_awprot;
  wire [3:0]INSTR_awqos;
  wire [0:0]INSTR_awready;
  wire [2:0]INSTR_awsize;
  wire [0:0]INSTR_awvalid;
  wire [1:0]INSTR_bid;
  wire [0:0]INSTR_bready;
  wire [1:0]INSTR_bresp;
  wire [0:0]INSTR_bvalid;
  wire [31:0]INSTR_rdata;
  wire [1:0]INSTR_rid;
  wire [0:0]INSTR_rlast;
  wire [0:0]INSTR_rready;
  wire [1:0]INSTR_rresp;
  wire [0:0]INSTR_rvalid;
  wire [31:0]INSTR_wdata;
  wire [0:0]INSTR_wlast;
  wire [0:0]INSTR_wready;
  wire [3:0]INSTR_wstrb;
  wire [0:0]INSTR_wvalid;
  wire [31:0]MEM_araddr;
  wire [1:0]MEM_arburst;
  wire [3:0]MEM_arcache;
  wire [1:0]MEM_arid;
  wire [7:0]MEM_arlen;
  wire [0:0]MEM_arlock;
  wire [2:0]MEM_arprot;
  wire [3:0]MEM_arqos;
  wire [0:0]MEM_arready;
  wire [3:0]MEM_arregion;
  wire [2:0]MEM_arsize;
  wire [0:0]MEM_arvalid;
  wire [31:0]MEM_awaddr;
  wire [1:0]MEM_awburst;
  wire [3:0]MEM_awcache;
  wire [1:0]MEM_awid;
  wire [7:0]MEM_awlen;
  wire [0:0]MEM_awlock;
  wire [2:0]MEM_awprot;
  wire [3:0]MEM_awqos;
  wire [0:0]MEM_awready;
  wire [3:0]MEM_awregion;
  wire [2:0]MEM_awsize;
  wire [0:0]MEM_awvalid;
  wire [1:0]MEM_bid;
  wire [0:0]MEM_bready;
  wire [1:0]MEM_bresp;
  wire [0:0]MEM_bvalid;
  wire [31:0]MEM_rdata;
  wire [1:0]MEM_rid;
  wire [0:0]MEM_rlast;
  wire [0:0]MEM_rready;
  wire [1:0]MEM_rresp;
  wire [0:0]MEM_rvalid;
  wire [31:0]MEM_wdata;
  wire [0:0]MEM_wlast;
  wire [0:0]MEM_wready;
  wire [3:0]MEM_wstrb;
  wire [0:0]MEM_wvalid;
  wire [31:0]PLIC_araddr;
  wire [1:0]PLIC_arburst;
  wire [3:0]PLIC_arcache;
  wire [1:0]PLIC_arid;
  wire [7:0]PLIC_arlen;
  wire [0:0]PLIC_arlock;
  wire [2:0]PLIC_arprot;
  wire [3:0]PLIC_arqos;
  wire [0:0]PLIC_arready;
  wire [3:0]PLIC_arregion;
  wire [2:0]PLIC_arsize;
  wire [0:0]PLIC_arvalid;
  wire [31:0]PLIC_awaddr;
  wire [1:0]PLIC_awburst;
  wire [3:0]PLIC_awcache;
  wire [1:0]PLIC_awid;
  wire [7:0]PLIC_awlen;
  wire [0:0]PLIC_awlock;
  wire [2:0]PLIC_awprot;
  wire [3:0]PLIC_awqos;
  wire [0:0]PLIC_awready;
  wire [3:0]PLIC_awregion;
  wire [2:0]PLIC_awsize;
  wire [0:0]PLIC_awvalid;
  wire [1:0]PLIC_bid;
  wire [0:0]PLIC_bready;
  wire [1:0]PLIC_bresp;
  wire [0:0]PLIC_bvalid;
  wire [31:0]PLIC_rdata;
  wire [1:0]PLIC_rid;
  wire [0:0]PLIC_rlast;
  wire [0:0]PLIC_rready;
  wire [1:0]PLIC_rresp;
  wire [0:0]PLIC_rvalid;
  wire [31:0]PLIC_wdata;
  wire [0:0]PLIC_wlast;
  wire [0:0]PLIC_wready;
  wire [3:0]PLIC_wstrb;
  wire [0:0]PLIC_wvalid;
  wire [31:0]PPI_araddr;
  wire [1:0]PPI_arburst;
  wire [3:0]PPI_arcache;
  wire [1:0]PPI_arid;
  wire [7:0]PPI_arlen;
  wire [0:0]PPI_arlock;
  wire [2:0]PPI_arprot;
  wire [3:0]PPI_arqos;
  wire [0:0]PPI_arready;
  wire [3:0]PPI_arregion;
  wire [2:0]PPI_arsize;
  wire [0:0]PPI_arvalid;
  wire [31:0]PPI_awaddr;
  wire [1:0]PPI_awburst;
  wire [3:0]PPI_awcache;
  wire [1:0]PPI_awid;
  wire [7:0]PPI_awlen;
  wire [0:0]PPI_awlock;
  wire [2:0]PPI_awprot;
  wire [3:0]PPI_awqos;
  wire [0:0]PPI_awready;
  wire [3:0]PPI_awregion;
  wire [2:0]PPI_awsize;
  wire [0:0]PPI_awvalid;
  wire [1:0]PPI_bid;
  wire [0:0]PPI_bready;
  wire [1:0]PPI_bresp;
  wire [0:0]PPI_bvalid;
  wire [31:0]PPI_rdata;
  wire [1:0]PPI_rid;
  wire [0:0]PPI_rlast;
  wire [0:0]PPI_rready;
  wire [1:0]PPI_rresp;
  wire [0:0]PPI_rvalid;
  wire [31:0]PPI_wdata;
  wire [0:0]PPI_wlast;
  wire [0:0]PPI_wready;
  wire [3:0]PPI_wstrb;
  wire [0:0]PPI_wvalid;
  wire UART_rxd;
  wire UART_txd;
  wire Vaux10_0_v_n;
  wire Vaux10_0_v_p;
  wire Vaux1_0_v_n;
  wire Vaux1_0_v_p;
  wire Vaux2_0_v_n;
  wire Vaux2_0_v_p;
  wire Vaux9_0_v_n;
  wire Vaux9_0_v_p;
  wire Vp_Vn_v_n;
  wire Vp_Vn_v_p;
  wire iic_intr;
  wire io0_i_0;
  wire io0_o_0;
  wire io0_t_0;
  wire io1_i_0;
  wire io1_o_0;
  wire io1_t_0;
  wire io_port_cs_0;
  wire io_port_dq_0_i;
  wire io_port_dq_0_o;
  wire io_port_dq_0_oe;
  wire io_port_dq_1_i;
  wire io_port_dq_1_o;
  wire io_port_dq_1_oe;
  wire io_port_dq_2_i;
  wire io_port_dq_2_o;
  wire io_port_dq_2_oe;
  wire io_port_dq_3_i;
  wire io_port_dq_3_o;
  wire io_port_dq_3_oe;
  wire io_port_sck;
  wire pwm0;
  wire sck_i_0;
  wire sck_o_0;
  wire sck_t_0;
  wire spi0_intr;
  wire spi1_intr;
  wire [0:0]ss_i_0;
  wire [0:0]ss_o_0;
  wire ss_t_0;
  wire timer0_intr;
  wire uart_intr;

  IOBUF IIC_scl_iobuf
       (.I(IIC_scl_o),
        .IO(IIC_scl_io),
        .O(IIC_scl_i),
        .T(IIC_scl_t));
  IOBUF IIC_sda_iobuf
       (.I(IIC_sda_o),
        .IO(IIC_sda_io),
        .O(IIC_sda_i),
        .T(IIC_sda_t));
  design_1 design_1_i
       (.ACLK(ACLK),
        .ARESETN(ARESETN),
        .CLINT_araddr(CLINT_araddr),
        .CLINT_arburst(CLINT_arburst),
        .CLINT_arcache(CLINT_arcache),
        .CLINT_arid(CLINT_arid),
        .CLINT_arlen(CLINT_arlen),
        .CLINT_arlock(CLINT_arlock),
        .CLINT_arprot(CLINT_arprot),
        .CLINT_arqos(CLINT_arqos),
        .CLINT_arready(CLINT_arready),
        .CLINT_arregion(CLINT_arregion),
        .CLINT_arsize(CLINT_arsize),
        .CLINT_arvalid(CLINT_arvalid),
        .CLINT_awaddr(CLINT_awaddr),
        .CLINT_awburst(CLINT_awburst),
        .CLINT_awcache(CLINT_awcache),
        .CLINT_awid(CLINT_awid),
        .CLINT_awlen(CLINT_awlen),
        .CLINT_awlock(CLINT_awlock),
        .CLINT_awprot(CLINT_awprot),
        .CLINT_awqos(CLINT_awqos),
        .CLINT_awready(CLINT_awready),
        .CLINT_awregion(CLINT_awregion),
        .CLINT_awsize(CLINT_awsize),
        .CLINT_awvalid(CLINT_awvalid),
        .CLINT_bid(CLINT_bid),
        .CLINT_bready(CLINT_bready),
        .CLINT_bresp(CLINT_bresp),
        .CLINT_bvalid(CLINT_bvalid),
        .CLINT_rdata(CLINT_rdata),
        .CLINT_rid(CLINT_rid),
        .CLINT_rlast(CLINT_rlast),
        .CLINT_rready(CLINT_rready),
        .CLINT_rresp(CLINT_rresp),
        .CLINT_rvalid(CLINT_rvalid),
        .CLINT_wdata(CLINT_wdata),
        .CLINT_wlast(CLINT_wlast),
        .CLINT_wready(CLINT_wready),
        .CLINT_wstrb(CLINT_wstrb),
        .CLINT_wvalid(CLINT_wvalid),
        .DATA_araddr(DATA_araddr),
        .DATA_arburst(DATA_arburst),
        .DATA_arcache(DATA_arcache),
        .DATA_arid(DATA_arid),
        .DATA_arlen(DATA_arlen),
        .DATA_arlock(DATA_arlock),
        .DATA_arprot(DATA_arprot),
        .DATA_arqos(DATA_arqos),
        .DATA_arready(DATA_arready),
        .DATA_arsize(DATA_arsize),
        .DATA_arvalid(DATA_arvalid),
        .DATA_awaddr(DATA_awaddr),
        .DATA_awburst(DATA_awburst),
        .DATA_awcache(DATA_awcache),
        .DATA_awid(DATA_awid),
        .DATA_awlen(DATA_awlen),
        .DATA_awlock(DATA_awlock),
        .DATA_awprot(DATA_awprot),
        .DATA_awqos(DATA_awqos),
        .DATA_awready(DATA_awready),
        .DATA_awsize(DATA_awsize),
        .DATA_awvalid(DATA_awvalid),
        .DATA_bid(DATA_bid),
        .DATA_bready(DATA_bready),
        .DATA_bresp(DATA_bresp),
        .DATA_bvalid(DATA_bvalid),
        .DATA_rdata(DATA_rdata),
        .DATA_rid(DATA_rid),
        .DATA_rlast(DATA_rlast),
        .DATA_rready(DATA_rready),
        .DATA_rresp(DATA_rresp),
        .DATA_rvalid(DATA_rvalid),
        .DATA_wdata(DATA_wdata),
        .DATA_wlast(DATA_wlast),
        .DATA_wready(DATA_wready),
        .DATA_wstrb(DATA_wstrb),
        .DATA_wvalid(DATA_wvalid),
        .DEBUG_araddr(DEBUG_araddr),
        .DEBUG_arburst(DEBUG_arburst),
        .DEBUG_arcache(DEBUG_arcache),
        .DEBUG_arid(DEBUG_arid),
        .DEBUG_arlen(DEBUG_arlen),
        .DEBUG_arlock(DEBUG_arlock),
        .DEBUG_arprot(DEBUG_arprot),
        .DEBUG_arqos(DEBUG_arqos),
        .DEBUG_arready(DEBUG_arready),
        .DEBUG_arregion(DEBUG_arregion),
        .DEBUG_arsize(DEBUG_arsize),
        .DEBUG_arvalid(DEBUG_arvalid),
        .DEBUG_awaddr(DEBUG_awaddr),
        .DEBUG_awburst(DEBUG_awburst),
        .DEBUG_awcache(DEBUG_awcache),
        .DEBUG_awid(DEBUG_awid),
        .DEBUG_awlen(DEBUG_awlen),
        .DEBUG_awlock(DEBUG_awlock),
        .DEBUG_awprot(DEBUG_awprot),
        .DEBUG_awqos(DEBUG_awqos),
        .DEBUG_awready(DEBUG_awready),
        .DEBUG_awregion(DEBUG_awregion),
        .DEBUG_awsize(DEBUG_awsize),
        .DEBUG_awvalid(DEBUG_awvalid),
        .DEBUG_bid(DEBUG_bid),
        .DEBUG_bready(DEBUG_bready),
        .DEBUG_bresp(DEBUG_bresp),
        .DEBUG_bvalid(DEBUG_bvalid),
        .DEBUG_rdata(DEBUG_rdata),
        .DEBUG_rid(DEBUG_rid),
        .DEBUG_rlast(DEBUG_rlast),
        .DEBUG_rready(DEBUG_rready),
        .DEBUG_rresp(DEBUG_rresp),
        .DEBUG_rvalid(DEBUG_rvalid),
        .DEBUG_wdata(DEBUG_wdata),
        .DEBUG_wlast(DEBUG_wlast),
        .DEBUG_wready(DEBUG_wready),
        .DEBUG_wstrb(DEBUG_wstrb),
        .DEBUG_wvalid(DEBUG_wvalid),
        .IIC_scl_i(IIC_scl_i),
        .IIC_scl_o(IIC_scl_o),
        .IIC_scl_t(IIC_scl_t),
        .IIC_sda_i(IIC_sda_i),
        .IIC_sda_o(IIC_sda_o),
        .IIC_sda_t(IIC_sda_t),
        .INSTR_araddr(INSTR_araddr),
        .INSTR_arburst(INSTR_arburst),
        .INSTR_arcache(INSTR_arcache),
        .INSTR_arid(INSTR_arid),
        .INSTR_arlen(INSTR_arlen),
        .INSTR_arlock(INSTR_arlock),
        .INSTR_arprot(INSTR_arprot),
        .INSTR_arqos(INSTR_arqos),
        .INSTR_arready(INSTR_arready),
        .INSTR_arsize(INSTR_arsize),
        .INSTR_arvalid(INSTR_arvalid),
        .INSTR_awaddr(INSTR_awaddr),
        .INSTR_awburst(INSTR_awburst),
        .INSTR_awcache(INSTR_awcache),
        .INSTR_awid(INSTR_awid),
        .INSTR_awlen(INSTR_awlen),
        .INSTR_awlock(INSTR_awlock),
        .INSTR_awprot(INSTR_awprot),
        .INSTR_awqos(INSTR_awqos),
        .INSTR_awready(INSTR_awready),
        .INSTR_awsize(INSTR_awsize),
        .INSTR_awvalid(INSTR_awvalid),
        .INSTR_bid(INSTR_bid),
        .INSTR_bready(INSTR_bready),
        .INSTR_bresp(INSTR_bresp),
        .INSTR_bvalid(INSTR_bvalid),
        .INSTR_rdata(INSTR_rdata),
        .INSTR_rid(INSTR_rid),
        .INSTR_rlast(INSTR_rlast),
        .INSTR_rready(INSTR_rready),
        .INSTR_rresp(INSTR_rresp),
        .INSTR_rvalid(INSTR_rvalid),
        .INSTR_wdata(INSTR_wdata),
        .INSTR_wlast(INSTR_wlast),
        .INSTR_wready(INSTR_wready),
        .INSTR_wstrb(INSTR_wstrb),
        .INSTR_wvalid(INSTR_wvalid),
        .MEM_araddr(MEM_araddr),
        .MEM_arburst(MEM_arburst),
        .MEM_arcache(MEM_arcache),
        .MEM_arid(MEM_arid),
        .MEM_arlen(MEM_arlen),
        .MEM_arlock(MEM_arlock),
        .MEM_arprot(MEM_arprot),
        .MEM_arqos(MEM_arqos),
        .MEM_arready(MEM_arready),
        .MEM_arregion(MEM_arregion),
        .MEM_arsize(MEM_arsize),
        .MEM_arvalid(MEM_arvalid),
        .MEM_awaddr(MEM_awaddr),
        .MEM_awburst(MEM_awburst),
        .MEM_awcache(MEM_awcache),
        .MEM_awid(MEM_awid),
        .MEM_awlen(MEM_awlen),
        .MEM_awlock(MEM_awlock),
        .MEM_awprot(MEM_awprot),
        .MEM_awqos(MEM_awqos),
        .MEM_awready(MEM_awready),
        .MEM_awregion(MEM_awregion),
        .MEM_awsize(MEM_awsize),
        .MEM_awvalid(MEM_awvalid),
        .MEM_bid(MEM_bid),
        .MEM_bready(MEM_bready),
        .MEM_bresp(MEM_bresp),
        .MEM_bvalid(MEM_bvalid),
        .MEM_rdata(MEM_rdata),
        .MEM_rid(MEM_rid),
        .MEM_rlast(MEM_rlast),
        .MEM_rready(MEM_rready),
        .MEM_rresp(MEM_rresp),
        .MEM_rvalid(MEM_rvalid),
        .MEM_wdata(MEM_wdata),
        .MEM_wlast(MEM_wlast),
        .MEM_wready(MEM_wready),
        .MEM_wstrb(MEM_wstrb),
        .MEM_wvalid(MEM_wvalid),
        .PLIC_araddr(PLIC_araddr),
        .PLIC_arburst(PLIC_arburst),
        .PLIC_arcache(PLIC_arcache),
        .PLIC_arid(PLIC_arid),
        .PLIC_arlen(PLIC_arlen),
        .PLIC_arlock(PLIC_arlock),
        .PLIC_arprot(PLIC_arprot),
        .PLIC_arqos(PLIC_arqos),
        .PLIC_arready(PLIC_arready),
        .PLIC_arregion(PLIC_arregion),
        .PLIC_arsize(PLIC_arsize),
        .PLIC_arvalid(PLIC_arvalid),
        .PLIC_awaddr(PLIC_awaddr),
        .PLIC_awburst(PLIC_awburst),
        .PLIC_awcache(PLIC_awcache),
        .PLIC_awid(PLIC_awid),
        .PLIC_awlen(PLIC_awlen),
        .PLIC_awlock(PLIC_awlock),
        .PLIC_awprot(PLIC_awprot),
        .PLIC_awqos(PLIC_awqos),
        .PLIC_awready(PLIC_awready),
        .PLIC_awregion(PLIC_awregion),
        .PLIC_awsize(PLIC_awsize),
        .PLIC_awvalid(PLIC_awvalid),
        .PLIC_bid(PLIC_bid),
        .PLIC_bready(PLIC_bready),
        .PLIC_bresp(PLIC_bresp),
        .PLIC_bvalid(PLIC_bvalid),
        .PLIC_rdata(PLIC_rdata),
        .PLIC_rid(PLIC_rid),
        .PLIC_rlast(PLIC_rlast),
        .PLIC_rready(PLIC_rready),
        .PLIC_rresp(PLIC_rresp),
        .PLIC_rvalid(PLIC_rvalid),
        .PLIC_wdata(PLIC_wdata),
        .PLIC_wlast(PLIC_wlast),
        .PLIC_wready(PLIC_wready),
        .PLIC_wstrb(PLIC_wstrb),
        .PLIC_wvalid(PLIC_wvalid),
        .PPI_araddr(PPI_araddr),
        .PPI_arburst(PPI_arburst),
        .PPI_arcache(PPI_arcache),
        .PPI_arid(PPI_arid),
        .PPI_arlen(PPI_arlen),
        .PPI_arlock(PPI_arlock),
        .PPI_arprot(PPI_arprot),
        .PPI_arqos(PPI_arqos),
        .PPI_arready(PPI_arready),
        .PPI_arregion(PPI_arregion),
        .PPI_arsize(PPI_arsize),
        .PPI_arvalid(PPI_arvalid),
        .PPI_awaddr(PPI_awaddr),
        .PPI_awburst(PPI_awburst),
        .PPI_awcache(PPI_awcache),
        .PPI_awid(PPI_awid),
        .PPI_awlen(PPI_awlen),
        .PPI_awlock(PPI_awlock),
        .PPI_awprot(PPI_awprot),
        .PPI_awqos(PPI_awqos),
        .PPI_awready(PPI_awready),
        .PPI_awregion(PPI_awregion),
        .PPI_awsize(PPI_awsize),
        .PPI_awvalid(PPI_awvalid),
        .PPI_bid(PPI_bid),
        .PPI_bready(PPI_bready),
        .PPI_bresp(PPI_bresp),
        .PPI_bvalid(PPI_bvalid),
        .PPI_rdata(PPI_rdata),
        .PPI_rid(PPI_rid),
        .PPI_rlast(PPI_rlast),
        .PPI_rready(PPI_rready),
        .PPI_rresp(PPI_rresp),
        .PPI_rvalid(PPI_rvalid),
        .PPI_wdata(PPI_wdata),
        .PPI_wlast(PPI_wlast),
        .PPI_wready(PPI_wready),
        .PPI_wstrb(PPI_wstrb),
        .PPI_wvalid(PPI_wvalid),
        .UART_rxd(UART_rxd),
        .UART_txd(UART_txd),
        .Vaux10_0_v_n(Vaux10_0_v_n),
        .Vaux10_0_v_p(Vaux10_0_v_p),
        .Vaux1_0_v_n(Vaux1_0_v_n),
        .Vaux1_0_v_p(Vaux1_0_v_p),
        .Vaux2_0_v_n(Vaux2_0_v_n),
        .Vaux2_0_v_p(Vaux2_0_v_p),
        .Vaux9_0_v_n(Vaux9_0_v_n),
        .Vaux9_0_v_p(Vaux9_0_v_p),
        .Vp_Vn_v_n(Vp_Vn_v_n),
        .Vp_Vn_v_p(Vp_Vn_v_p),
        .iic_intr(iic_intr),
        .io0_i_0(io0_i_0),
        .io0_o_0(io0_o_0),
        .io0_t_0(io0_t_0),
        .io1_i_0(io1_i_0),
        .io1_o_0(io1_o_0),
        .io1_t_0(io1_t_0),
        .io_port_cs_0(io_port_cs_0),
        .io_port_dq_0_i(io_port_dq_0_i),
        .io_port_dq_0_o(io_port_dq_0_o),
        .io_port_dq_0_oe(io_port_dq_0_oe),
        .io_port_dq_1_i(io_port_dq_1_i),
        .io_port_dq_1_o(io_port_dq_1_o),
        .io_port_dq_1_oe(io_port_dq_1_oe),
        .io_port_dq_2_i(io_port_dq_2_i),
        .io_port_dq_2_o(io_port_dq_2_o),
        .io_port_dq_2_oe(io_port_dq_2_oe),
        .io_port_dq_3_i(io_port_dq_3_i),
        .io_port_dq_3_o(io_port_dq_3_o),
        .io_port_dq_3_oe(io_port_dq_3_oe),
        .io_port_sck(io_port_sck),
        .pwm0(pwm0),
        .sck_i_0(sck_i_0),
        .sck_o_0(sck_o_0),
        .sck_t_0(sck_t_0),
        .spi0_intr(spi0_intr),
        .spi1_intr(spi1_intr),
        .ss_i_0(ss_i_0),
        .ss_o_0(ss_o_0),
        .ss_t_0(ss_t_0),
        .timer0_intr(timer0_intr),
        .uart_intr(uart_intr));
endmodule

