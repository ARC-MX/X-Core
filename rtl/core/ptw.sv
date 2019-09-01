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
// Author: David Schaffenrath, TU Graz
// Author: Florian Zaruba, ETH Zurich
// Date: 24.4.2017
// Description: Hardware-PTW

/* verilator lint_off WIDTH */
import riscv_package::*;

module ptw #(
        parameter int ASID_WIDTH = 1
    )(
    input  logic                    clk_i,                  // Clock
    input  logic                    rst_ni,                 // Asynchronous reset active low
    //input  logic                    flush_i,                // flush everything, we need to do this because
                                                            // actually everything we do is speculative at this stage
                                                            // e.g.: there could be a CSR instruction that changes everything
    output logic                    ptw_active_o,
    output logic                    walking_instr_o,        // set when walking for TLB
    output logic                    ptw_error_o,            // set when an error occurred
    output logic [31:0]             faulting_address_o,     // the address which threw the page-fault exception
    input  logic                    enable_translation_i,   // CSRs indicate to enable SV32
    input  logic                    en_ld_st_translation_i, // enable virtual memory translation for load/stores

    input  logic                    lsu_is_store_i,         // this translation was triggered by a store
    // PTW Memory Port
    output logic [33:0]             data_address_o,
    output logic [31:0]             data_wdata_o,
    output logic                    data_req_o,
    output logic                    data_we_o,
    output logic [3:0]              data_be_o,
    output logic [1:0]              data_size_o,
    output logic                    tag_valid_o,
    input  logic                    data_gnt_i,
    input  logic                    data_rvalid_i,
    input  logic [31:0]             data_rdata_i,
    // to TLBs, update logic
    output tlb_update_t             itlb_update_o,
    output tlb_update_t             dtlb_update_o,

    output logic [31:0]             update_vaddr_o,

    input  logic [ASID_WIDTH-1:0]   asid_i,
    // from TLBs
    // did we miss?
    input  logic                    itlb_access_i,
    input  logic                    itlb_hit_i,
    input  logic [31:0]             itlb_vaddr_i,

    input  logic                    dtlb_access_i,
    input  logic                    dtlb_hit_i,
    input  logic [31:0]             dtlb_vaddr_i,
    // from CSR file
    input  logic [21:0]             satp_ppn_i, // ppn from satp
    input  logic                    mxr_i,
    // Performance counters
    output logic                    itlb_miss_o,
    output logic                    dtlb_miss_o

);
    // input registers
    logic data_rvalid_q;
    logic [31:0] data_rdata_q;

    pte_t pte;
    assign pte = pte_t'(data_rdata_q);

    enum logic[2:0] {
      IDLE,
      WAIT_GRANT,
      PTE_LOOKUP,
      WAIT_RVALID,
      PROPAGATE_ERROR
    } CS, NS;

    // SV32 defines three levels of page tables
    enum logic [1:0] {
        LVL1, LVL2
    } ptw_lvl_q, ptw_lvl_n;

    // is this an instruction page table walk?
    logic is_instr_ptw_q,   is_instr_ptw_n;
    logic global_mapping_q, global_mapping_n;
    // latched tag signal
    logic tag_valid_n,      tag_valid_q;
    // register the ASID
    logic [ASID_WIDTH-1:0]  tlb_update_asid_q, tlb_update_asid_n;
    // register the VPN we need to walk, SV32 defines a 32 bit virtual address
    logic [31:0] vaddr_q,   vaddr_n;
    // 4 byte aligned physical pointer
    logic[33:0] ptw_pptr_q, ptw_pptr_n;

    // Assignments
    assign update_vaddr_o  = vaddr_q;

    assign ptw_active_o    = (CS != IDLE);
    assign walking_instr_o = is_instr_ptw_q;
    // directly output the correct physical address
    assign data_address_o   = ptw_pptr_q[33:0];
    // we are never going to write with the HPTW
    assign data_wdata_o    = 64'b0;
    // -----------
    // TLB Update
    // -----------
    assign itlb_update_o.vpn = vaddr_q[31:12];
    assign dtlb_update_o.vpn = vaddr_q[31:12];
    // update the correct page table level
    //assign itlb_update_o.is_2M = (ptw_lvl_q == LVL2);
    //assign itlb_update_o.is_1G = (ptw_lvl_q == LVL1);
    //assign dtlb_update_o.is_2M = (ptw_lvl_q == LVL2);
    //assign dtlb_update_o.is_1G = (ptw_lvl_q == LVL1);
    assign itlb_update_o.is_4M = (ptw_lvl_q == LVL1);
    assign dtlb_update_o.is_4M = (ptw_lvl_q == LVL1);
    // output the correct ASID
    assign itlb_update_o.asid = tlb_update_asid_q;
    assign dtlb_update_o.asid = tlb_update_asid_q;
    // set the global mapping bit
    assign itlb_update_o.content = pte | (global_mapping_q << 5);
    assign dtlb_update_o.content = pte | (global_mapping_q << 5);

    assign tag_valid_o      = tag_valid_q;

    //-------------------
    // Page table walker
    //-------------------
    // A virtual address va is translated into a physical address pa as follows:
    // 1. Let a be sptbr.ppn 脳 PAGESIZE, and let i = LEVELS-1. (For Sv32,
    //    PAGESIZE=2^12 and LEVELS=2.)
    // 2. Let pte be the value of the PTE at address a+va.vpn[i]脳PTESIZE. (For
    //    Sv32, PTESIZE=4.)
    // 3. If pte.v = 0, or if pte.r = 0 and pte.w = 1, stop and raise an access
    //    exception.
    // 4. Otherwise, the PTE is valid. If pte.r = 1 or pte.x = 1, go to step 5.
    //    Otherwise, this PTE is a pointer to the next level of the page table.
    //    Let i=i-1. If i < 0, stop and raise an access exception. Otherwise, let
    //    a = pte.ppn 脳 PAGESIZE and go to step 2.
    // 5. A leaf PTE has been found. Determine if the requested memory access
    //    is allowed by the pte.r, pte.w, and pte.x bits. If not, stop and
    //    raise an access exception. Otherwise, the translation is successful.
    //    Set pte.a to 1, and, if the memory access is a store, set pte.d to 1.
    //    The translated physical address is given as follows:
    //      - pa.pgoff = va.pgoff.
    //      - If i > 0, then this is a superpage translation and
    //        pa.ppn[i-1:0] = va.vpn[i-1:0].
    //      - pa.ppn[LEVELS-1:i] = pte.ppn[LEVELS-1:i].
    always_comb begin : ptw
        // default assignments
        // PTW memory interface
        tag_valid_n         = 1'b0;
        data_req_o          = 1'b0;
        data_be_o           = 4'hF;
        data_size_o         = 2'b10;
        data_we_o           = 1'b0;
        ptw_error_o         = 1'b0;
        itlb_update_o.valid = 1'b0;
        dtlb_update_o.valid = 1'b0;
        is_instr_ptw_n      = is_instr_ptw_q;
        ptw_lvl_n           = ptw_lvl_q;
        ptw_pptr_n          = ptw_pptr_q;
        NS                  = CS;
        global_mapping_n    = global_mapping_q;
        // input registers
        tlb_update_asid_n   = tlb_update_asid_q;
        vaddr_n             = vaddr_q;
        faulting_address_o  = '0;

        itlb_miss_o         = 1'b0;
        dtlb_miss_o         = 1'b0;

        case (CS)

            IDLE: begin
                // by default we start with the top-most page table
                ptw_lvl_n        = LVL1;
                global_mapping_n = 1'b0;
                is_instr_ptw_n   = 1'b0;
                // if we got an ITLB miss
                if (enable_translation_i & itlb_access_i & ~itlb_hit_i & ~dtlb_access_i) begin
                    ptw_pptr_n          = {satp_ppn_i, itlb_vaddr_i[31:22], 2'b0};
                    is_instr_ptw_n      = 1'b1;
                    tlb_update_asid_n   = asid_i;
                    vaddr_n             = itlb_vaddr_i;
                    NS                  = WAIT_GRANT;
                    itlb_miss_o         = 1'b1;
                // we got an DTLB miss
                end else if (en_ld_st_translation_i & dtlb_access_i & ~dtlb_hit_i) begin
                    ptw_pptr_n          = {satp_ppn_i, dtlb_vaddr_i[31:22], 2'b0};
                    tlb_update_asid_n   = asid_i;
                    vaddr_n             = dtlb_vaddr_i;
                    NS                  = WAIT_GRANT;
                    dtlb_miss_o         = 1'b1;
                end
            end

            WAIT_GRANT: begin
                // send a request out
                data_req_o = 1'b1;
                // wait for the WAIT_GRANT
                if (data_gnt_i) begin
                    // send the tag valid signal one cycle later
                    tag_valid_n = 1'b1;
                    NS          = PTE_LOOKUP;
                end
            end

            PTE_LOOKUP: begin
                // we wait for the valid signal
                if (data_rvalid_q) begin

                    // check if the global mapping bit is set
                    if (pte.g)
                        global_mapping_n = 1'b1;

                    // -------------
                    // Invalid PTE
                    // -------------
                    // If pte.v = 0, or if pte.r = 0 and pte.w = 1, stop and raise a page-fault exception.
                    if (!pte.v || (!pte.r && pte.w))
                        NS = PROPAGATE_ERROR;
                    // -----------
                    // Valid PTE
                    // -----------
                    else begin
                        NS = IDLE;
                        // it is a valid PTE
                        // if pte.r = 1 or pte.x = 1 it is a valid PTE
                        if (pte.r || pte.x) begin
                            // Valid translation found (either 4M or 4K entry)
                            if (is_instr_ptw_q) begin
                                // ------------
                                // Update ITLB
                                // ------------
                                // If page is not executable, we can directly raise an error. This
                                // doesn't put a useless entry into the TLB. The same idea applies
                                // to the access flag since we let the access flag be managed by SW.
                                if (!pte.x || !pte.a)
                                  NS = PROPAGATE_ERROR;
                                else
                                  itlb_update_o.valid = 1'b1;

                            end else begin
                                // ------------
                                // Update DTLB
                                // ------------
                                // Check if the access flag has been set, otherwise throw a page-fault
                                // and let the software handle those bits.
                                // If page is not readable (there are no write-only pages)
                                // we can directly raise an error. This doesn't put a useless
                                // entry into the TLB.
                                if (pte.a && (pte.r || (pte.x && mxr_i))) begin
                                  dtlb_update_o.valid = 1'b1;
                                end else begin
                                  NS   = PROPAGATE_ERROR;
                                end
                                // Request is a store: perform some additional checks
                                // If the request was a store and the page is not write-able, raise an error
                                // the same applies if the dirty flag is not set
                                if (lsu_is_store_i && (!pte.w || !pte.d)) begin
                                    dtlb_update_o.valid = 1'b0;
                                    NS   = PROPAGATE_ERROR;
                                end
                            end
                            // check if the ppn is correctly aligned:
                            // 6. If i > 0 and pa.ppn[i 鈭? 1 : 0] != 0, this is a misaligned superpage; stop and raise a page-fault
                            // exception.
                            if (ptw_lvl_q == LVL1 && pte.ppn[21:0] != '0) begin
                                NS = PROPAGATE_ERROR;
                                dtlb_update_o.valid = 1'b0;
                                itlb_update_o.valid = 1'b0;
                            end 
                        // this is a pointer to the next TLB level
                        end else begin
                            // pointer to next level of page table
                            if (ptw_lvl_q == LVL1) begin
                                // we are in the second level now
                                ptw_lvl_n  = LVL2;
                                ptw_pptr_n = {pte.ppn, vaddr_q[21:12], 2'b0};
                            end

                            NS = WAIT_GRANT;

                            if (ptw_lvl_q == LVL2) begin
                              // Should already be the last level page table => Error
                              ptw_lvl_n   = LVL2;
                              NS = PROPAGATE_ERROR;
                            end
                        end
                    end
                end
                // we've got a data WAIT_GRANT so tell the cache that the tag is valid
            end
            // Propagate error to MMU/LSU
            PROPAGATE_ERROR: begin
                NS = IDLE;
                ptw_error_o        = 1'b1;
                faulting_address_o = vaddr_q;
            end
            // wait for the rvalid before going back to IDLE
            WAIT_RVALID: begin
                if (data_rvalid_q)
                    NS = IDLE;
            end
        endcase

        // -------
        // Flush
        // -------
        // should we have flushed before we got an rvalid, wait for it until going back to IDLE
        //if (flush_i) begin
        //    // on a flush check whether we are waiting for a grant, if so: wait for it
        //    // if not go back to idle
        //    if ((CS == WAIT_GRANT) && data_gnt_i)
        //        NS = WAIT_RVALID;
        //    else
        //        NS = IDLE;
        //end
    end

    // sequential process
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            CS                 <= IDLE;
            is_instr_ptw_q     <= 1'b0;
            ptw_lvl_q          <= LVL1;
            tag_valid_q        <= 1'b0;
            tlb_update_asid_q  <= '{default: 0};
            vaddr_q            <= '0;
            ptw_pptr_q         <= '{default: 0};
            global_mapping_q   <= 1'b0;
            data_rdata_q       <= '0;
            data_rvalid_q      <= 1'b0;
        end else begin
            CS                 <= NS;
            ptw_pptr_q         <= ptw_pptr_n;
            is_instr_ptw_q     <= is_instr_ptw_n;
            ptw_lvl_q          <= ptw_lvl_n;
            tag_valid_q        <= tag_valid_n;
            tlb_update_asid_q  <= tlb_update_asid_n;
            vaddr_q            <= vaddr_n;
            global_mapping_q   <= global_mapping_n;
            data_rdata_q       <= data_rdata_i;
            data_rvalid_q      <= data_rvalid_i;
        end
    end

endmodule
/* verilator lint_on WIDTH */
