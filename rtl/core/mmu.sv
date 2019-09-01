// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19/04/2017
// Description: Memory Management Unit for Ariane, contains TLB and
//              address translation unit. SV39 as defined in RISC-V
//              privilege specification 1.11-WIP

import riscv_package::*;
import riscv_defines::*;

module riscv_mmu #(
      parameter  INSTR_TLB_ENTRIES = 4,
      parameter  DATA_TLB_ENTRIES  = 4,
      parameter  ASID_WIDTH        = 9,
      parameter  INSTR_RDATA_WIDTH = 32
    )
    (
        input  logic                            clk_i,
        input  logic                            rst_ni,
        input  logic                            enable_translation_i,
        input  logic                            en_ld_st_translation_i,   // enable virtual memory translation for load/stores

        // IF interface
        input  logic                            fetch_req_i,
        output logic                            fetch_gnt_o,
        output logic                            fetch_valid_o,
        input  logic [31:0]                     fetch_vaddr_i,
        output logic [INSTR_RDATA_WIDTH-1:0]    fetch_rdata_o,  // pass-through because of interfaces
        output exception_t                      fetch_ex_o,     // write-back fetch exceptions (e.g.: bus faults, page faults, etc.)
        // LSU interface
        // this is a more minimalistic interface because the actual addressing logic is handled
        // in the LSU as we distinguish load and stores, what we do here is simple address translation
        input  logic                            misaligned_ex_i,
        input  logic                            lsu_req_i,        // request address translation
        input  logic [31:0]                     lsu_vaddr_i,      // virtual address in
        input  logic                            lsu_is_store_i,   // the translation is requested by a store
        output logic                            lsu_mem_data_gnt_o,
        input  logic [3:0]                      lsu_mem_data_be_i,
        output logic                            lsu_mem_data_rvalid_o,
        output logic [31:0]                     lsu_mem_data_rdata_o,
        input  logic [31:0]                     lsu_mem_data_wdata_i,

        // if we need to walk the page table we can't grant in the same cycle
        // Cycle 0
        output logic                            lsu_dtlb_hit_o,   // sent in the same cycle as the request if translation hits in the DTLB
        // Cycle 1
       // output logic                            lsu_valid_z_o,      // translation is valid
       // output logic [33:0]                     lsu_paddr_z_o,      // translated address
        output exception_t                      lsu_exception_o,  // address translation threw an exception
        // General control signals
        input PrivLvl_t                         priv_lvl_i,
        input PrivLvl_t                         ld_st_priv_lvl_i,
        input logic                             sum_i,
        input logic                             mxr_i,
        // input logic flag_mprv_i,
        input logic [21:0]                      satp_ppn_i,
        input logic [ASID_WIDTH-1:0]            asid_i,
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
        output logic [33:0]                    data_addr_o,
        output logic [31:0]                    data_wdata_o,
        output logic                           data_req_o,
        output logic                           data_we_o,
        output logic [3:0]                     data_be_o,
        output logic [1:0]                     data_size_o,
        output logic                           tag_valid_o,
        input  logic                           data_gnt_i,
        input  logic                           data_rvalid_i,
        input  logic [31:0]                    data_rdata_i
);
    // instruction error
    // instruction error valid signal and exception, delayed one cycle
    logic        ierr_valid_q, ierr_valid_n;

    logic        iaccess_err;   // insufficient privilege to access this instruction page
    logic        daccess_err;   // insufficient privilege to access this data page
    logic        ptw_active;    // PTW is currently walking a page table
    logic        walking_instr; // PTW is walking because of an ITLB miss
    logic        ptw_error;     // PTW threw an exception
    logic [31:0] faulting_address;
    logic [11:0] address_index_o;
    logic [21:0] address_tag_o;

    logic [31:0] update_vaddr;
    tlb_update_t update_ptw_itlb, update_ptw_dtlb;

    logic        itlb_update;
    logic        itlb_lu_access;
    pte_t        itlb_content;
    logic        itlb_is_4M;
    logic        itlb_lu_hit;

    logic        dtlb_update;
    logic        dtlb_lu_access;
    pte_t        dtlb_content;
    logic        dtlb_is_4M;
    logic        dtlb_lu_hit;

    logic        ptw_data_we;
    logic        ptw_data_req;
    logic [3:0]  ptw_be;
    logic [31:0] ptw_wdata;
    logic [1:0]  ptw_data_size;
    logic        ptw_tag_valid;

    logic        lsu_valid;
    logic [33:0] lsu_paddr;
    logic        lsu_data_we;
    logic [3:0]  lsu_mem_data_be;
    logic [31:0] lsu_mem_data_wdata;
    logic [33:0] ptw_addr;
    
    
    // Assignments
    assign itlb_lu_access = fetch_req_i;
    assign dtlb_lu_access = lsu_req_i;
    assign fetch_rdata_o  = instr_if_data_rdata_i;
    ///////////add 2018/5/7//////////
    assign lsu_mem_data_gnt_o    = ptw_active  ? 1'b0 : data_gnt_i ;
    assign lsu_mem_data_rvalid_o = ptw_active  ? 1'b0 : data_rvalid_i;
    assign lsu_mem_data_rdata_o  = data_rdata_i;

    assign data_be_o             = ~enable_translation_i ? lsu_mem_data_be_i    : (ptw_active  ? ptw_be      : lsu_mem_data_be); 
    assign data_wdata_o          = ~enable_translation_i ? lsu_mem_data_wdata_i : (ptw_active  ? ptw_wdata   : lsu_mem_data_wdata);

    assign data_addr_o           = ~enable_translation_i ? {2'b00,lsu_vaddr_i} :(ptw_active  ? ptw_addr     : lsu_paddr);
    assign data_req_o            = ~enable_translation_i ? lsu_req_i           :(ptw_active  ? ptw_data_req : lsu_valid);
    assign data_we_o             = ~enable_translation_i ? lsu_is_store_i      :(ptw_active  ? ptw_data_we  : lsu_data_we);

    assign data_size_o           = ptw_active  ? ptw_data_size: 2'b10;   
    assign tag_valid_o           = ptw_tag_valid;   
    /////////////////////////////////

    tlb #(
        .TLB_ENTRIES      ( INSTR_TLB_ENTRIES          ),
        .ASID_WIDTH       ( ASID_WIDTH                 )
    ) i_itlb (
        .clk_i            ( clk_i                      ),
        .rst_ni           ( rst_ni                     ),
        .flush_i          ( flush_tlb_i                ),

        .update_i         ( update_ptw_itlb            ),

        .lu_access_i      ( itlb_lu_access             ),
        .lu_asid_i        ( asid_i                     ),
        .lu_vaddr_i       ( fetch_vaddr_i              ),
        .lu_content_o     ( itlb_content               ),

        .lu_is_4M_o       ( itlb_is_4M                 ),
        .lu_hit_o         ( itlb_lu_hit                )
    );

    tlb #(
        .TLB_ENTRIES     ( DATA_TLB_ENTRIES             ),
        .ASID_WIDTH      ( ASID_WIDTH                   )
    ) i_dtlb (
        .clk_i            ( clk_i                       ),
        .rst_ni           ( rst_ni                      ),
        .flush_i          ( flush_tlb_i                 ),

        .update_i         ( update_ptw_dtlb             ),

        .lu_access_i      ( dtlb_lu_access              ),
        .lu_asid_i        ( asid_i                      ),
        .lu_vaddr_i       ( lsu_vaddr_i                 ),
        .lu_content_o     ( dtlb_content                ),

        .lu_is_4M_o       ( dtlb_is_4M                  ),
        .lu_hit_o         ( dtlb_lu_hit                 )
    );


    ptw  #(
        .ASID_WIDTH             ( ASID_WIDTH            )
    ) i_ptw (
        .clk_i                  ( clk_i                 ),
        .rst_ni                 ( rst_ni                ),
        .ptw_active_o           ( ptw_active            ),
        .walking_instr_o        ( walking_instr         ),
        .ptw_error_o            ( ptw_error             ),
        .faulting_address_o     ( faulting_address      ),
        .enable_translation_i   ( enable_translation_i  ),
        .en_ld_st_translation_i ( en_ld_st_translation_i),
        .lsu_is_store_i         ( lsu_is_store_i        ),

        // PTW Memory Port
        .data_address_o         ( ptw_addr              ),
        .data_wdata_o           ( ptw_wdata             ),
        .data_req_o             ( ptw_data_req          ),
        .data_we_o              ( ptw_data_we           ),
        .data_be_o              ( ptw_be                ),
        .data_size_o            ( ptw_data_size         ),
        .tag_valid_o            ( ptw_tag_valid         ),
        .data_gnt_i             ( data_gnt_i            ),
        .data_rvalid_i          ( data_rvalid_i         ),
        .data_rdata_i           ( data_rdata_i          ),
        // to TLBs, update logic
        .itlb_update_o          ( update_ptw_itlb       ),
        .dtlb_update_o          ( update_ptw_dtlb       ),
        .update_vaddr_o         ( update_vaddr          ),
        .asid_i                 ( asid_i                ),
        // from TLBs
        // did we miss?
        .itlb_access_i          ( itlb_lu_access        ),
        .itlb_hit_i             ( itlb_lu_hit           ),
        .itlb_vaddr_i           ( fetch_vaddr_i         ),
        .dtlb_access_i          ( dtlb_lu_access        ),
        .dtlb_hit_i             ( dtlb_lu_hit           ),
        .dtlb_vaddr_i           ( lsu_vaddr_i           ),
        // from CSR file
        .satp_ppn_i             ( satp_ppn_i            ), 
        .mxr_i                  ( mxr_i                 ),
        // Performance counters
        .itlb_miss_o            ( itlb_miss_o           ),
        .dtlb_miss_o            ( dtlb_miss_o           )
     );

    //-----------------------
    // Instruction Interface
    //-----------------------
    exception_t fetch_exception;
    logic exception_fifo_empty;
    // This is a full memory interface, e.g.: it handles all signals to the I$
    // Exceptions are always signaled together with the fetch_valid_o signal
    always_comb begin : instr_interface
        // MMU disabled: just pass through
        instr_if_data_req_o = fetch_req_i;
        instr_if_address_o  = {2'b00,fetch_vaddr_i}; // play through in case we disabled address translation
        fetch_gnt_o         = instr_if_data_gnt_i;
        // two potential exception sources:
        // 1. HPTW threw an exception -> signal with a page fault exception
        // 2. We got an access error because of insufficient permissions -> throw an access exception
        fetch_exception      = '0;
        ierr_valid_n         = 1'b0; // we keep a separate valid signal in case of an error
        // Check whether we are allowed to access this memory region from a fetch perspective
        iaccess_err   = fetch_req_i && (((priv_lvl_i == PRIV_LVL_U) && ~itlb_content.u)
                                     || ((priv_lvl_i == PRIV_LVL_S) && itlb_content.u));

        // check that the upper-most bits (63-39) are the same, otherwise throw a page fault exception...
        //if (fetch_req_i && !((&fetch_vaddr_i[63:39]) == 1'b1 || (|fetch_vaddr_i[63:39]) == 1'b0)) begin
        //    fetch_exception = {EXC_CAUSE_INSTR_PAGE_FAULT, fetch_vaddr_i, 1'b1};
        //    ierr_valid_n = 1'b1;
        //    fetch_gnt_o  = 1'b1;
        //end
        // MMU enabled: address from TLB, request delayed until hit. Error when TLB
        // hit and no access right or TLB hit and translated address not valid (e.g.
        // AXI decode error), or when PTW performs walk due to ITLB miss and raises
        // an error.
        if (enable_translation_i) begin
            instr_if_data_req_o = 1'b0;

            // 4K page
            instr_if_address_o = {itlb_content.ppn, fetch_vaddr_i[11:0]};
            // Mega page
            if (itlb_is_4M) begin
                instr_if_address_o[21:12] = fetch_vaddr_i[21:12];
            end
            // Giga page
            //if (itlb_is_1G) begin
            //    instr_if_address_o[29:12] = fetch_vaddr_i[29:12];
            //end

            // ---------
            // ITLB Hit
            // --------
            // if we hit the ITLB output the request signal immediately
            if (itlb_lu_hit) begin
                instr_if_data_req_o = fetch_req_i;
                // we got an access error
                if (iaccess_err) begin
                    // immediately grant a fetch which threw an exception, and stop the request from happening
                    instr_if_data_req_o = 1'b0;
                    // in case we hit the TLB with an exception we need to order the memory request e.g.
                    // we need to wait until all outstanding request drained otherwise we get an out-of order result
                    // which will be wrong
                    if (exception_fifo_empty) begin
                        fetch_gnt_o         = 1'b1;
                        ierr_valid_n        = 1'b1;
                    end
                    // throw a page fault
                    fetch_exception = {EXC_CAUSE_INSTR_PAGE_FAULT, fetch_vaddr_i, 1'b1};
                end
            end else
            // ---------
            // ITLB Miss
            // ---------
            // watch out for exceptions happening during walking the page table
            if (ptw_active && walking_instr) begin
                // check that the fetch address is equal with the faulting address as it could be that the page table walker
                // has walked an instruction the instruction fetch stage is no longer interested in as we didn't give a grant
                // we should not propagate back the exception when the request is no longer high
                if (faulting_address == fetch_vaddr_i && fetch_req_i) begin
                    // on an error pass through fetch with an error signaled
                    fetch_gnt_o  = ptw_error;
                    ierr_valid_n = ptw_error; // signal valid/error on next cycle
                end
                fetch_exception = {EXC_CAUSE_INSTR_PAGE_FAULT,  update_vaddr, 1'b1};
            end
        end
        // the fetch is valid if we either got an error in the previous cycle or the I$ gave us a valid signal.
        fetch_valid_o = instr_if_data_rvalid_i || ierr_valid_q;
    end
    // ---------------------------
    // Fetch exception register
    // ---------------------------
    // We can have two outstanding transactions
    fifo #(
        .dtype            ( exception_t          ),
        .DEPTH            ( 2                    )
    ) i_exception_fifo (
        .clk_i            ( clk_i                ),
        .rst_ni           ( rst_ni               ),
        .flush_i          ( 1'b0                 ),
        .full_o           (                      ),
        .empty_o          ( exception_fifo_empty ),
        .single_element_o (                      ),
        .data_i           ( fetch_exception      ),
        .push_i           ( fetch_gnt_o          ),
        .data_o           ( fetch_ex_o           ),
        .pop_i            ( fetch_valid_o        ),
        .*
    );

    // ----------
    // Registers
    // ----------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            ierr_valid_q <= 1'b0;
        end else begin
            ierr_valid_q <= ierr_valid_n;
        end
    end

    //-----------------------
    // Data Interface
    //-----------------------
    logic [31:0] lsu_vaddr_n,     lsu_vaddr_q;
    pte_t        dtlb_pte_n,      dtlb_pte_q;
    logic        misaligned_ex_n, misaligned_ex_q;
    logic        lsu_req_n,       lsu_req_q;
    logic        lsu_data_we_n,   lsu_data_we_q;
    logic [31:0] lsu_mem_data_wdata_n, lsu_mem_data_wdata_q;
    logic [3:0]  lsu_mem_data_be_n, lsu_mem_data_be_q;
    logic        lsu_is_store_n,  lsu_is_store_q;
    logic        dtlb_hit_n,      dtlb_hit_q;
    logic        dtlb_is_4M_n,    dtlb_is_4M_q;

    // check if we need to do translation or if we are always ready (e.g.: we are not translating anything)
    assign lsu_dtlb_hit_o = (en_ld_st_translation_i) ? dtlb_lu_hit :  1'b1;

    // The data interface is simpler and only consists of a request/response interface
    always_comb begin : data_interface
        // save request and DTLB response
        lsu_vaddr_n           = lsu_vaddr_i;
        lsu_req_n             = lsu_req_i;
        lsu_data_we_n         = lsu_is_store_i;
        lsu_mem_data_wdata_n  = lsu_mem_data_wdata_i;
        lsu_mem_data_be_n     = lsu_mem_data_be_i; 
        misaligned_ex_n       = misaligned_ex_i;
        dtlb_pte_n            = dtlb_content;
        dtlb_hit_n            = dtlb_lu_hit;
        lsu_is_store_n        = lsu_is_store_i;
        dtlb_is_4M_n          = dtlb_is_4M;
        
        lsu_paddr             = {2'b00,lsu_vaddr_q};
        lsu_valid             = lsu_req_q;
        lsu_exception_o       = misaligned_ex_q;
        lsu_data_we           =  lsu_data_we_q;
        lsu_mem_data_wdata    = lsu_mem_data_wdata_q;
        lsu_mem_data_be       = lsu_mem_data_be_q;
        // mute misaligned exceptions if there is no request otherwise they will throw accidental exceptions
        misaligned_ex_n = misaligned_ex_i & lsu_req_i;

        // Check if the User flag is set, then we may only access it in supervisor mode
        // if SUM is enabled
        daccess_err = (ld_st_priv_lvl_i == PRIV_LVL_S && !sum_i && dtlb_pte_q.u) || // SUM is not set and we are trying to access a user page in supervisor mode
                      (ld_st_priv_lvl_i == PRIV_LVL_U && !dtlb_pte_q.u);            // this is not a user page but we are in user mode and trying to access it
        // translation is enabled and no misaligned exception occurred
        if (en_ld_st_translation_i && !misaligned_ex_q) begin
            lsu_valid = 1'b0;
            lsu_data_we   = 1'b0;
            // 4K page
            lsu_paddr = {dtlb_pte_q.ppn, lsu_vaddr_q[11:0]};
            // Mega page
            if (dtlb_is_4M_q) begin
              lsu_paddr[21:12] = lsu_vaddr_q[21:12];
            end
            // ---------
            // DTLB Hit
            // --------
            if (dtlb_hit_q && lsu_req_q) begin
                lsu_valid = 1'b1;
                // this is a store
                if (lsu_is_store_q) begin
                    // check if the page is write-able and we are not violating privileges
                    // also check if the dirty flag is set
                    if (!dtlb_pte_q.w || daccess_err || !dtlb_pte_q.d) begin
                        lsu_exception_o = {EXC_CAUSE_STORE_PAGE_FAULT, lsu_vaddr_q, 1'b1};
                    end
                    lsu_data_we = 1'b1;
                // this is a load, check for sufficient access privileges - throw a page fault if necessary
                end else if (daccess_err) begin
                    lsu_exception_o = {EXC_CAUSE_LOAD_PAGE_FAULT, lsu_vaddr_q, 1'b1};
                end

            end else

            // ---------
            // DTLB Miss
            // ---------
            // watch out for exceptions
            if (ptw_active && !walking_instr) begin
                // page table walker threw an exception
                if (ptw_error) begin
                    // an error makes the translation valid
                    lsu_valid = 1'b1;
                    // the page table walker can only throw page faults
                    if (lsu_is_store_q) begin
                        lsu_exception_o = {EXC_CAUSE_STORE_PAGE_FAULT,  update_vaddr, 1'b1};
                    end else begin
                        lsu_exception_o = {EXC_CAUSE_LOAD_PAGE_FAULT,  update_vaddr, 1'b1};
                    end
                end
            end
        end
    end
    // ----------
    // Registers
    // ----------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            lsu_vaddr_q      <= '0;
            lsu_req_q        <= '0;
            lsu_data_we_q    <= '0;
            misaligned_ex_q  <= '0;
            dtlb_pte_q       <= '0;
            dtlb_hit_q       <= '0;
            lsu_is_store_q   <= '0;
            dtlb_is_4M_q     <= '0;
            lsu_mem_data_wdata_q <= '0;
            lsu_mem_data_be_q    <= '0;
        end else begin
            lsu_vaddr_q      <=  lsu_vaddr_n;
            lsu_req_q        <=  lsu_req_n;
            lsu_data_we_q    <=  lsu_data_we_n;
            lsu_mem_data_wdata_q <= lsu_mem_data_wdata_n;
            lsu_mem_data_be_q  <=  lsu_mem_data_be_n;
            misaligned_ex_q  <=  misaligned_ex_n;
            dtlb_pte_q       <=  dtlb_pte_n;
            dtlb_hit_q       <=  dtlb_hit_n;
            lsu_is_store_q   <=  lsu_is_store_n;
            dtlb_is_4M_q     <=  dtlb_is_4M_n;
        end
    end
endmodule
