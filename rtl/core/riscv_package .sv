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


package riscv_package;

  typedef enum logic { 
    SINGLE_REQ, 
    CACHE_LINE_REQ 
  } req_t;


  // Privileged mode
  typedef enum logic[1:0] {
    PRIV_LVL_M = 2'b11,
    PRIV_LVL_H = 2'b10,
    PRIV_LVL_S = 2'b01,
    PRIV_LVL_U = 2'b00
  } PrivLvl_t;

  //Change it by **, 2018.5.11
  typedef struct packed {
      logic          sd;          //31 bit
      logic [7:0]    wpri4;       //30:23 bit
      logic          tsr;         //22 bit
      logic          tw;          //21 bit
      logic          tvm;         //20 bit
      logic          mxr;         //19 bit
      logic          sum;         //18 bit
      logic          mprv;        //17 bit
      logic [1:0]    xs;          //16:15 bit
      logic [1:0]    fs;          //14:13 bit
      PrivLvl_t      mpp;         //12:11 bit
      logic [1:0]    wpri3;       //10:9  bit
      logic          spp;         //8 bit
      logic          mpie;        //7 bit
      logic          wpri2;       //6 bit
      logic          spie;        //5 bit
      logic          upie;        //4 bit
      logic          mie;         //3 bit
      logic          wpri1;       //2 bit
      logic          sie;         //1 bit
      logic          uie;         //0 bit
  } Status_t;

  // memory management, pte
  typedef struct packed {
      logic [21:0] ppn;
      logic [1:0]  rsw;
      logic d;
      logic a;
      logic g;
      logic u;
      logic x;
      logic w;
      logic r;
      logic v;
  } pte_t;
  
  typedef struct packed {
      logic [5:0] cause; // cause of exception
      logic [31:0] tval;  // additional information of causing exception (e.g.: instruction causing it),
                          // address of LD/ST fault
      logic        valid;
  } exception_t;
      
  typedef struct packed {
      logic                  valid;      // valid flag
      logic                  is_4M;      //
      logic [19:0]           vpn;
      logic [8:0]            asid;       //change it , 2018.5.14
      pte_t                  content;
  } tlb_update_t;
      
  typedef struct packed {
      logic        mode;
      logic [8:0]  asid;
      logic [21:0] ppn;
  } satp_t;


  typedef struct packed {
      logic [1:0]      id;     // id for which we handle the miss
      logic            valid;
      logic            we;
      
      //logic [55:0]     addr;
      logic [33:0]     addr;
      
      logic [7:0][7:0] wdata;
      logic [7:0]      be;
  } mshr_t;

  typedef struct packed {
      logic         valid;
      
      //logic [63:0]  addr;
      logic [31:0]  addr;
      
      logic [3:0]   be;
      logic [1:0]   size;
      logic         we;
      
      //logic [63:0]  wdata;
      logic [31:0]  wdata;
      
      logic         bypass;
  } miss_req_t;

/////////////////////////////////////////////////
//
//
//for data cache
//
/////////////////////////////////////////////////

  localparam int unsigned INDEX_WIDTH       = 7;  // 8 + 1 + 2
  localparam int unsigned TAG_WIDTH         = 27;
  localparam int unsigned CACHE_LINE_WIDTH  = 64;
  localparam int unsigned SET_ASSOCIATIVITY = 8;
  localparam int unsigned NR_MSHR           = 1;
  
  // Calculated parameter
  localparam BYTE_OFFSET = $clog2(CACHE_LINE_WIDTH/8);   // 3
  localparam NUM_WORDS   = 2**(INDEX_WIDTH-BYTE_OFFSET); // 256
  localparam DIRTY_WIDTH = SET_ASSOCIATIVITY*2;          // 16
 
  typedef struct packed {
      logic [TAG_WIDTH-1:0]           tag;    // tag array
      logic [CACHE_LINE_WIDTH-1:0]    data;   // data array
      logic                           valid;  // state array
      logic                           dirty;  // state array
  } cache_line_t;

  // cache line byte enable
  typedef struct packed {
      logic [TAG_WIDTH-1:0]        tag;   // byte enable into tag array
      logic [CACHE_LINE_WIDTH-1:0] data;  // byte enable into data array
      logic [DIRTY_WIDTH/2-1:0]    dirty; // byte enable into state array
      logic [DIRTY_WIDTH/2-1:0]    valid; // byte enable into state array
  } cl_be_t;


  // convert one hot to bin for -> needed for cache replacement
  function automatic logic [$clog2(SET_ASSOCIATIVITY)-1:0] one_hot_to_bin (input logic [SET_ASSOCIATIVITY-1:0] in);
      for (int unsigned i = 0; i < SET_ASSOCIATIVITY; i++) begin
          if (in[i])
              return i;
      end
  endfunction
  // get the first bit set, returns one hot value
  function automatic logic [SET_ASSOCIATIVITY-1:0] get_victim_cl (input logic [SET_ASSOCIATIVITY-1:0] valid_dirty);
      // one-hot return vector
      logic [SET_ASSOCIATIVITY-1:0] oh = '0;
      for (int unsigned i = 0; i < SET_ASSOCIATIVITY; i++) begin
          if (valid_dirty[i]) begin
              oh[i] = 1'b1;
              return oh;
          end
      end
  endfunction
//////////////////////////////////////////////////

endpackage // riscv_package
