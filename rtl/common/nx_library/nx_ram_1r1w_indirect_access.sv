/*************************************************************************
*
* Copyright � Microsoft Corporation. All rights reserved.
* Copyright � Broadcom Inc. All rights reserved.
* Licensed under the MIT License.
*
*************************************************************************/
































`include "messages.vh"
`include "ccx_std.vh"
`include "nx_mem_typePKG_v2.svp"
module nx_ram_1r1w_indirect_access
  #(parameter 
    CMND_ADDRESS=0,       
    STAT_ADDRESS=0,       
    ALIGNMENT=2,          
    N_TIMER_BITS=6,       
                          
    N_REG_ADDR_BITS=16,   
                          
    N_DATA_BITS=32,       
    N_ENTRIES=1,          
    N_INIT_INC_BITS=0,    
                          
                          
    SPECIALIZE=1,         
    IN_FLOP=0,
    OUT_FLOP=0,
    RD_LATENCY=1,
    parameter [`BIT_VEC(N_DATA_BITS)] RESET_DATA=0)
   (input logic                             clk,
    input logic                             rst_n,

    
    input logic [`BIT_VEC(N_REG_ADDR_BITS)] reg_addr,
    
    input logic [3:0]                       cmnd_op,
    input logic [`LOG_VEC(N_ENTRIES)]       cmnd_addr,

    output logic [2:0]                      stat_code,
    output logic [`BIT_VEC(5)]              stat_datawords,
    output logic [`LOG_VEC(N_ENTRIES)]      stat_addr,

    output logic [15:0]                     capability_lst,
    output logic [3:0]                      capability_type,    
    
    input logic                             wr_stb,
    input logic [`BIT_VEC(N_DATA_BITS)]     wr_dat,
    
    output logic [`BIT_VEC(N_DATA_BITS)]    rd_dat,


`ifdef ENA_BIMC
    input logic                             lvm, 
    input logic                             mlvm, 
    input logic                             mrdten,
    input logic                             bimc_rst_n,
    input logic                             bimc_isync,
    input logic                             bimc_idat,
    output logic                            bimc_odat,
    output logic                            bimc_osync,
    output logic                            ro_uncorrectable_ecc_error,
`endif

    
    input logic                             hw_cs,
    input logic [`LOG_VEC(N_ENTRIES)]       hw_raddr,
    input logic [`LOG_VEC(N_ENTRIES)]       hw_waddr,
    input logic                             hw_we,
    input logic                             hw_re, 
    input logic [`BIT_VEC(N_DATA_BITS)]     hw_din, 
    output logic [`BIT_VEC(N_DATA_BITS)]    hw_dout,
    output logic                            hw_yield
  );

  import nx_mem_typePKG_v2::*;
  
 
   localparam capabilities_t capabilities_t_set
     =  { init_inc     : (N_INIT_INC_BITS>0)? TRUE : FALSE, 
          compare      : FALSE,
          reserved_op  : 4'b0,
          default      : TRUE};   
 /*

	localparam capabilities_t capabilities_t_set =
		{
		1'b0, //ack error
		1'b0, // sim_tmo
		4'b0000, //reserved_op
		1'b0, // compare
		1'b0, // set_init_start
		(N_INIT_INC_BITS > 0) ? 1'b1 : 1'b0, // init_inc
		1'b0, // init
		1'b0, //reset
		1'b0, //disabled
		1'b0, //enable
		1'b0, //write
		1'b0, //read
		1'b1 //nop

		};
   */
   
  logic                         enable;
  logic                         yield;
  logic [`LOG_VEC(N_ENTRIES)]   sw_add;
  logic                         sw_cs;  
  logic [`BIT_VEC(N_DATA_BITS)] sw_wdat;
  logic                         sw_we;

  logic [`LOG_VEC(N_ENTRIES)]   wadd;
  logic [`LOG_VEC(N_ENTRIES)]   radd;   
  logic                         cs;     
  logic [`BIT_VEC(N_DATA_BITS)] din;    
  logic                         web;
  logic                         reb;    
  logic [`BIT_VEC(N_DATA_BITS)] dout;   


   
   assign cs   = hw_cs ||  sw_cs;
   assign wadd = hw_cs ?  hw_waddr :   sw_add;
   assign radd = hw_cs ?  hw_raddr :   sw_add;
   assign din  = hw_cs ?  hw_din   :   sw_wdat;
   assign web  = hw_cs ? ~hw_we    : ~(sw_cs && sw_we);
   assign reb  = hw_cs ? ~hw_re    : ~(sw_cs & ~sw_we);

   assign hw_dout  = dout;   
   assign hw_yield = yield;

   localparam TOTAL_LATENCY = IN_FLOP+OUT_FLOP+RD_LATENCY;
   logic [`BIT_VEC(TOTAL_LATENCY)] r_rsp;
   always_ff@(posedge clk or negedge rst_n) begin
     if (!rst_n) begin
       r_rsp <= '0;
     end
     else begin
       r_rsp <= {r_rsp[TOTAL_LATENCY-2:0], (!hw_cs && !sw_we && sw_cs)};
     end
   end
   
   
   nx_ram_1r1w 
     #(.WIDTH(N_DATA_BITS), 
       .DEPTH(N_ENTRIES),
       .SPECIALIZE(SPECIALIZE), 
       .IN_FLOP(IN_FLOP),
       .OUT_FLOP(OUT_FLOP),
       .RD_LATENCY(RD_LATENCY))
   u_ram
     (
      
      .bimc_odat                        (bimc_odat),
      .bimc_osync                       (bimc_osync),
      .ro_uncorrectable_ecc_error       (ro_uncorrectable_ecc_error),
      .dout                             (dout[`BIT_VEC(N_DATA_BITS)]),
      
      .rst_n                            (rst_n),
      .clk                              (clk),
      .lvm                              (lvm),
      .mlvm                             (mlvm),
      .mrdten                           (mrdten),
      .bimc_rst_n                       (bimc_rst_n),
      .bimc_isync                       (bimc_isync),
      .bimc_idat                        (bimc_idat),
      .reb                              (reb),
      .ra                               (radd[`LOG_VEC(N_ENTRIES)]),
      .web                              (web),
      .wa                               (wadd[`LOG_VEC(N_ENTRIES)]),
      .din                              (din[`BIT_VEC(N_DATA_BITS)]),
      .bwe                              ({N_DATA_BITS{1'b1}})); 

  logic [`LOG_VEC(N_ENTRIES)] addr_limit; 
   assign addr_limit = N_ENTRIES-1;

   nx_indirect_access_cntrl_v2
     #(.MEM_TYPE              (RAM_1R1W),
       .CAPABILITIES          (capabilities_t_set),       
       .CMND_ADDRESS          (CMND_ADDRESS),
       .STAT_ADDRESS          (STAT_ADDRESS),
       .ALIGNMENT             (ALIGNMENT),
       .N_TIMER_BITS          (N_TIMER_BITS),
       .N_REG_ADDR_BITS       (N_REG_ADDR_BITS),
       .N_INIT_INC_BITS       (N_INIT_INC_BITS),
       .N_DATA_BITS           (N_DATA_BITS),
       .N_ENTRIES             (N_ENTRIES),
       .RESET_DATA            (RESET_DATA),
       .N_TABLES              (1))
   u_cntrl
       (.rsp                  (r_rsp[TOTAL_LATENCY-1]),
        .grant                (!hw_cs),
        .sw_rdat              (dout),
        .reset                (),
        .cmnd_table_id        ('0),
        .stat_table_id        (),
        .sw_ce                (),
        .sw_match ('0),
        .sw_aindex ('0),
        .*);
     
endmodule 






