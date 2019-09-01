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

import riscv_defines::*;
import riscv_package::*;

module riscv_mem_stage
    #(
      parameter  INSTR_TLB_ENTRIES = 4,
      parameter  DATA_TLB_ENTRIES  = 4,
      parameter  ASID_WIDTH        = 9,
      parameter  INSTR_RDATA_WIDTH = 32
    )
    (
    input  logic                            clk,
    input  logic                            rst_n,

    // IF interface
    input  logic                            fetch_req_i,
    output logic                            fetch_gnt_o,
    output logic                            fetch_valid_o,
    input  logic [31:0]                     fetch_vaddr_i,
    output logic [INSTR_RDATA_WIDTH-1:0]    fetch_rdata_o,          // pass-through because of interfaces
    output exception_t                      fetch_ex_o,             // write-back fetch exceptions (e.g.: bus faults, page faults, etc.)

    // signals from mem stage
    input  logic                            data_we_mem_i,          // write enable                      -> from mem stage
    input  logic [1:0]                      data_type_mem_i,        // Data type word, halfword, byte    -> from mem stage
    input  logic [31:0]                     data_wdata_mem_i,       // data to write to memory           -> from mem stage
    input  logic [1:0]                      data_reg_offset_mem_i,  // offset inside register for stores -> from mem stage
    input  logic                            data_sign_ext_mem_i,    // sign extension                    -> from mem stage
                   
    input  logic                            data_req_mem_i,         // data request                      -> from mem stage
    input  logic [31:0]                     data_addr_mem_i,        // data request addr                 -> from mem stage
                   
    input  logic [5:0]                      regfile_waddr_mem_i,    //we to reg addr for lsu
    input  logic                            regfile_we_mem_i,       //we to reg en for lsu
                       
    input  logic [31:0]                     regfile_alu_wdata_mem_i,//wb to reg's data for alu/multi
    input  logic                            regfile_alu_we_mem_i,   //wb to reg's en for alu/multi
    input  logic [5:0]                      regfile_alu_waddr_mem_i,//wb to reg's addr for alu/multi
                   
    //to wb stage                   
    output logic [31:0]                     regfile_alu_wdata_wb_o,
    output logic                            regfile_alu_we_wb_o,   
    output logic [5:0]                      regfile_alu_waddr_wb_o,
                   
    output logic [5:0]                      regfile_waddr_wb_o,    
    output logic                            regfile_we_wb_o,     
    output logic [31:0]                     regfile_wdata_wb_o,
    //**                   
    input  logic                            data_misaligned_ex_i,  // misaligned access in last ld/st   -> from ID/EX pipeline
    output logic                            data_misaligned_o,      // misaligned access was detected    -> to controller
                   
    // exception signals
    output logic                            load_err_o,
    output logic                            store_err_o,
                   
    // stall signal                   
    output logic                            mem_ready_o,
    output logic                            mem_valid_o,
    output logic                            wb_ready_o,
    output logic                            wb_valid_o,
    output logic                            lsu_ready_mem_o,
    output logic                            busy_o,
                   
    // CSR control                  
    input  logic                            enable_translation_i,
    input  logic                            en_ld_st_translation_i, // enable virtual memory translation for load/stores

    // if we need to walk the page table we can't grant in the same cycle
    // Cycle 0
    output logic                            lsu_dtlb_hit_o,         // sent in the same cycle as the request if translation hits in the DTLB
    output exception_t                      lsu_exception_o,        // address translation threw an exception
    // General control signals
    input PrivLvl_t                         priv_lvl_i,
    input PrivLvl_t                         ld_st_priv_lvl_i,
    input logic                             sum_i,
    input logic                             mxr_i,
    // input logic flag_mprv_i,
    input logic  [21:0]                     satp_ppn_i,
    input logic  [ASID_WIDTH-1:0]           asid_i,
    input logic                             flush_tlb_i,
    // Performance counters
    output logic                            itlb_miss_o,
    output logic                            dtlb_miss_o,
    // Memory interfaces
    // Instruction memory/cache
    output logic [33:0]                     instr_if_address_o,
    output logic                            instr_if_data_req_o,
    input  logic                            instr_if_data_gnt_i,
    input  logic                            instr_if_data_rvalid_i,
    input  logic [INSTR_RDATA_WIDTH-1:0]    instr_if_data_rdata_i,
    // Data memory/cache
    output logic [33:0]                     data_addr_o,
    output logic [31:0]                     data_wdata_o,
    output logic                            data_req_o,
    output logic                            data_we_o,
    output logic [3:0]                      data_be_o,
    output logic [1:0]                      data_size_o,
    output logic                            tag_valid_o,
    input  logic                            data_gnt_i,
    input  logic                            data_rvalid_i,
    input  logic [31:0]                     data_rdata_i    
);

// LSU interface
// this is a more minimalistic interface because the actual addressing logic is handled
// in the LSU as we distinguish load and stores, what we do here is simple address translation
logic        misaligned_mem;

logic        lsu_data_req;
logic        lsu_data_we;      // the translation is requested by a store
logic [31:0] lsu_data_addr; 
logic        lsu_data_gnt;
logic [3:0]  lsu_data_be;
logic        lsu_data_rvalid;
logic [31:0] lsu_data_rdata;
logic [31:0] lsu_data_wdata;

logic        lsu_ready;
logic [31:0] lsu_rdata;

logic        regfile_alu_we_wb_pre;
logic        meet_diff_en;
logic        meet_same_en;

logic        mmu_data_req;
logic [31:0] mmu_data_addr;

assign mmu_data_addr = lsu_data_addr;
assign mmu_data_req  = lsu_data_req;


  ////////////////////////////////////////////////////////////////////////////////////////
  //    _     ___    _    ____    ____ _____ ___  ____  _____   _   _ _   _ ___ _____   //
  //   | |   / _ \  / \  |  _ \  / ___|_   _/ _ \|  _ \| ____| | | | | \ | |_ _|_   _|  //
  //   | |  | | | |/ _ \ | | | | \___ \ | || | | | |_) |  _|   | | | |  \| || |  | |    //
  //   | |__| |_| / ___ \| |_| |  ___) || || |_| |  _ <| |___  | |_| | |\  || |  | |    //
  //   |_____\___/_/   \_\____/  |____/ |_| \___/|_| \_\_____|  \___/|_| \_|___| |_|    //
  //                                                                                    //
  ////////////////////////////////////////////////////////////////////////////////////////

riscv_load_store_unit  riscv_load_store_unit_i
  (
    .clk                   ( clk                  ),
    .rst_n                 ( rst_n                ),

    //output to data memory
    .data_req_o            ( lsu_data_req         ),
    .data_gnt_i            ( lsu_data_gnt         ),
    .data_rvalid_i         ( lsu_data_rvalid      ),
    .data_err_i            ( 1'b0                    ),//modf 2018-6-9

    .data_addr_o           ( lsu_data_addr        ),
    .data_we_o             ( lsu_data_we          ),
    .data_be_o             ( lsu_data_be          ),
    .data_wdata_o          ( lsu_data_wdata       ),
    .data_rdata_i          ( lsu_data_rdata       ),

    // signal from mem stage
    .data_we_mem_i         ( data_we_mem_i        ),
    .data_type_mem_i       ( data_type_mem_i      ),
    .data_wdata_mem_i      ( data_wdata_mem_i     ),
    .data_reg_offset_mem_i ( data_reg_offset_mem_i),
    .data_sign_ext_mem_i   ( data_sign_ext_mem_i  ),  // sign extension
    .data_rdata_wb_o       ( lsu_rdata            ),
    .data_req_mem_i        ( data_req_mem_i       ),
    .data_addr_mem_i       ( data_addr_mem_i      ),
  
    .data_misaligned_ex_i  ( data_misaligned_ex_i   ), // from ID/EX pipeline
    .data_misaligned_o     ( data_misaligned_o      ),
  
    // exception signals  
    .load_err_o            ( load_err_o         ),
    .store_err_o           ( store_err_o        ),
  
    // control signals  
    .lsu_ready_mem_o       ( lsu_ready_mem_o        ),
    .lsu_ready_wb_o        ( lsu_ready_wb         ),
  
    .ex_valid_i            ( 1'b1                 ),
    .busy_o                ( busy_o               )
  );



riscv_mmu 
#(
  .INSTR_RDATA_WIDTH (INSTR_RDATA_WIDTH),
  .ASID_WIDTH		 (ASID_WIDTH),
  .INSTR_TLB_ENTRIES (INSTR_TLB_ENTRIES),
  .DATA_TLB_ENTRIES	 (DATA_TLB_ENTRIES)
  ) riscv_mmu (
      .clk_i                   ( clk                       ),
      .rst_ni                  ( rst_n                     ),
      .enable_translation_i    ( enable_translation_i      ),         //from CSR
      .en_ld_st_translation_i  ( en_ld_st_translation_i    ),         //from CSR, enable virtual memory translation for load/stores
      // IF interface 
      .fetch_req_i             ( fetch_req_i               ),  
      .fetch_gnt_o             ( fetch_gnt_o               ),
      .fetch_valid_o           ( fetch_valid_o             ),
      .fetch_vaddr_i           ( fetch_vaddr_i             ),
      .fetch_rdata_o           ( fetch_rdata_o             ),         // pass-through because of interfaces     
      .fetch_ex_o              ( fetch_ex_o                ),         // write-back fetch exceptions (e.g.: bus faults, page faults, etc.)
      // LSU interface
      // this is a more minimalistic interface because the actual addressing logic is handled
      // in the LSU as we distinguish load and stores, what we do here is simple address translation
      .misaligned_ex_i         ( data_misaligned_ex_i      ),
      //mmu-lsu interface for load&store       
      .lsu_req_i               ( mmu_data_req              ),          // request address translation
      .lsu_vaddr_i             ( mmu_data_addr             ),          // virtual address in
      .lsu_is_store_i          ( lsu_data_we               ),          // the translation is requested by a store
      .lsu_mem_data_gnt_o      ( lsu_data_gnt              ),
      .lsu_mem_data_rvalid_o   ( lsu_data_rvalid           ),
      .lsu_mem_data_rdata_o    ( lsu_data_rdata            ),
      .lsu_mem_data_wdata_i    ( lsu_data_wdata            ),
      .lsu_mem_data_be_i       ( lsu_data_be               ),
      // if we need to walk the page table we can't grant in the same cycle
      // Cycle 0 hit signal gen, Cycle 1 paddr gen
      .lsu_dtlb_hit_o          ( lsu_dtlb_hit_o            ),         // sent in the same cycle as the request if translation hits in the DTLB
      .lsu_exception_o         ( lsu_exception_o           ),         // address translation threw an exception
      // General control signals 
      .priv_lvl_i              ( priv_lvl_i                ),         //from CSR
      .ld_st_priv_lvl_i        ( ld_st_priv_lvl_i          ),         //from CSR
      .sum_i                   ( sum_i                       ),         //from CSR
      .mxr_i                   ( mxr_i                       ),         //from CSR
      // input logic flag_mprv_i
      .satp_ppn_i              ( satp_ppn_i                ),         //from CSR
      .asid_i                  ( asid_i                    ),         //from CSR
      .flush_tlb_i             ( flush_tlb_i               ),
      // Performance counters
      .itlb_miss_o             ( itlb_miss_o               ),
      .dtlb_miss_o             ( dtlb_miss_o               ),
      // Memory interfaces
      // Instruction memory/cache
      .instr_if_address_o      ( instr_if_address_o        ),
      .instr_if_data_req_o     ( instr_if_data_req_o       ),             
      .instr_if_data_gnt_i     ( instr_if_data_gnt_i       ),
      .instr_if_data_rvalid_i  ( instr_if_data_rvalid_i    ),
      .instr_if_data_rdata_i   ( instr_if_data_rdata_i     ),
      // Data memory/cache               
      .data_addr_o             ( data_addr_o               ),
      .data_wdata_o            ( data_wdata_o              ),
      .data_req_o              ( data_req_o                ),
      .data_we_o               ( data_we_o                 ),
      .data_be_o               ( data_be_o                 ),
      .data_size_o             ( data_size_o               ),
      .tag_valid_o             ( tag_valid_o               ),
      .data_gnt_i              ( data_gnt_i                ),
      .data_rvalid_i           ( data_rvalid_i             ),
      .data_rdata_i            ( data_rdata_i              )
);


  always_ff @(posedge clk or negedge rst_n) begin 
      if(~rst_n) begin
        regfile_alu_wdata_wb_o <= '0;
        regfile_alu_we_wb_pre    <= 1'b0;   
        regfile_alu_waddr_wb_o  <= '0;
        regfile_waddr_wb_o     <= 1'b0;
        regfile_we_wb_o        <= 1'b0;
      end else begin
        if(mem_valid_o) begin
            regfile_alu_wdata_wb_o <= regfile_alu_wdata_mem_i;
            regfile_alu_we_wb_pre  <= regfile_alu_we_mem_i; 
            regfile_alu_waddr_wb_o <= regfile_alu_waddr_mem_i;  
        end else begin
            regfile_alu_wdata_wb_o <= regfile_alu_wdata_wb_o;
            regfile_alu_we_wb_pre <= regfile_alu_we_wb_pre ; 
            regfile_alu_waddr_wb_o <= regfile_alu_waddr_wb_o;
        end
        if(wb_valid_o) begin
            regfile_waddr_wb_o <= regfile_waddr_mem_i;    //we to reg addr for lsu
            regfile_we_wb_o    <= regfile_we_mem_i ;      //we to reg en for lsu
        end else begin
            regfile_waddr_wb_o <= regfile_waddr_wb_o;
            regfile_we_wb_o    <= regfile_we_wb_o;
        end
      end // end else

  end
  
  always_comb begin
        regfile_wdata_wb_o = lsu_rdata;    

        regfile_alu_we_wb_o  = regfile_alu_we_wb_pre  & mem_ready_o; //alu we and lsu we  
  end // always_comb

  assign meet_diff_en     = regfile_we_wb_o&regfile_alu_we_wb_pre&(regfile_waddr_wb_o!=regfile_alu_waddr_wb_o);
  assign meet_same_en     = regfile_we_wb_o&regfile_alu_we_wb_pre&(regfile_waddr_wb_o==regfile_alu_waddr_wb_o);
  //alu control
  //alu control
  assign mem_ready_o = ~(lsu_ready_wb&meet_diff_en); //if load wb meet alu wb, stall alu wb 
  assign mem_valid_o = mem_ready_o;
  //lsu control
  assign wb_ready_o  = lsu_ready_wb&lsu_ready_mem_o&~meet_same_en;
  assign wb_valid_o  = wb_ready_o;

  endmodule