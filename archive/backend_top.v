module backend_top #(
parameter FE_ADDR_W     = 32,
parameter FE_DATA_W     = 32,
parameter BE_ADDR_W     = 32,
parameter BE_DATA_W     = 32,
parameter NWAYS_W       = 2,
parameter NLINES_W      = 7,   // number of index bits for lines (must match frontend & backend)
parameter WORD_OFFSET_W = 4,   // offset bits within a cache line (must match frontend & backend)
parameter WTBUF_DEPTH_W = 4,
parameter REP_POLICY    = 1,   // e.g. PLRU_MRU
parameter WRITE_POL     = 1,   // 1 = WRITE_THROUGH (match both)
parameter USE_CTRL      = 0,
parameter USE_CTRL_CNT  = 0,
parameter AXI_ID_W      = 8,
parameter AXI_ID        = 0,
parameter AXI_LEN_W     = 8,

// AXI RAM / backend-only params (ok to include on both)
parameter READ_ON_WRITE   = 1,
parameter PIPELINE_OUTPUT = 0
//parameter RAM_FILE        = "none"


) (
   input  wire                   clk_i,
   input  wire                   cke_i,
   input  wire                   arst_i,
   
   // Front-end interface (IOb native slave)
   input  wire                   iob_valid_i,
   input  wire [FE_ADDR_W-1:0]   iob_addr_i,
   input  wire [FE_DATA_W-1:0]   iob_wdata_i,
   input  wire [FE_DATA_W/8-1:0] iob_wstrb_i,
   output wire                   iob_rvalid_o,
   output wire [FE_DATA_W-1:0]   iob_rdata_o,
   output wire                   iob_ready_o,
   
   // Cache control
   input  wire                   invalidate_i,
   output wire                   invalidate_o,
   input  wire                   wtb_empty_i,
   output wire                   wtb_empty_o
);

   // Derived parameters for cache
  // localparam FE_NBYTES     = FE_DATA_W / 8;
  // localparam FE_NBYTES_W   = $clog2(FE_NBYTES);
   localparam BE_NBYTES     = BE_DATA_W / 8;
   localparam BE_NBYTES_W   = $clog2(BE_NBYTES);
   localparam LINE2BE_W     = WORD_OFFSET_W - $clog2(BE_DATA_W / FE_DATA_W);
 //  localparam ADDR_W        = USE_CTRL + FE_ADDR_W - FE_NBYTES_W;
   localparam DATA_W        = FE_DATA_W;

localparam FE_NBYTES   = FE_DATA_W / 8;
localparam FE_NBYTES_W = $clog2(FE_NBYTES);
localparam ADDR_W      = USE_CTRL + FE_ADDR_W - FE_NBYTES_W;


   // AXI signals between cache and RAM
   wire [BE_ADDR_W-1:0] axi_araddr;
   wire [         2:0]  axi_arprot;
   wire                 axi_arvalid;
   wire                 axi_arready;
   wire [BE_DATA_W-1:0] axi_rdata;
   wire [         1:0]  axi_rresp;
   wire                 axi_rvalid;
   wire                 axi_rready;
   wire [AXI_ID_W-1:0]  axi_arid;
   wire [AXI_LEN_W-1:0] axi_arlen;
   wire [         2:0]  axi_arsize;
   wire [         1:0]  axi_arburst;
   wire [         1:0]  axi_arlock;
   wire [         3:0]  axi_arcache;
   wire [         3:0]  axi_arqos;
   wire [AXI_ID_W-1:0]  axi_rid;
   wire                 axi_rlast;

   wire [BE_ADDR_W-1:0] axi_awaddr;
   wire [         2:0]  axi_awprot;
   wire                 axi_awvalid;
   wire                 axi_awready;
   wire [BE_DATA_W-1:0] axi_wdata;
   wire [BE_NBYTES-1:0] axi_wstrb;
   wire                 axi_wvalid;
   wire                 axi_wready;
   wire [         1:0]  axi_bresp;
   wire                 axi_bvalid;
   wire                 axi_bready;
   wire [AXI_ID_W-1:0]  axi_awid;
   wire [AXI_LEN_W-1:0] axi_awlen;
   wire [         2:0]  axi_awsize;
   wire [         1:0]  axi_awburst;
   wire [         1:0]  axi_awlock;
   wire [         3:0]  axi_awcache;
   wire [         3:0]  axi_awqos;
   wire                 axi_wlast;
   wire [AXI_ID_W-1:0]  axi_bid;

   // Cache instance
   iob_cache_axi #(
      .FE_ADDR_W     (FE_ADDR_W),
      .FE_DATA_W     (FE_DATA_W),
      .BE_ADDR_W     (BE_ADDR_W),
      .BE_DATA_W     (BE_DATA_W),
      .NWAYS_W       (NWAYS_W),
      .NLINES_W      (NLINES_W),
      .WORD_OFFSET_W (WORD_OFFSET_W),
      .WTBUF_DEPTH_W (WTBUF_DEPTH_W),
      .REP_POLICY    (REP_POLICY),
      .WRITE_POL     (WRITE_POL),
      .USE_CTRL      (USE_CTRL),
      .USE_CTRL_CNT  (USE_CTRL_CNT),
      .AXI_ID_W      (AXI_ID_W),
      .AXI_ID        (AXI_ID),
      .AXI_LEN_W     (AXI_LEN_W),
      .AXI_ADDR_W    (BE_ADDR_W),
      .AXI_DATA_W    (BE_DATA_W)
   ) cache_inst (
      .clk_i          (clk_i),
      .cke_i          (cke_i),
      .arst_i         (arst_i),
      
      // Front-end interface
      .iob_valid_i    (iob_valid_i),
      .iob_addr_i     (iob_addr_i[ADDR_W-1:0]),
      .iob_wdata_i    (iob_wdata_i),
      .iob_wstrb_i    (iob_wstrb_i),
      .iob_rvalid_o   (iob_rvalid_o),
      .iob_rdata_o    (iob_rdata_o),
      .iob_ready_o    (iob_ready_o),
      
      // Cache control
      .invalidate_i   (invalidate_i),
      .invalidate_o   (invalidate_o),
      .wtb_empty_i    (wtb_empty_i),
      .wtb_empty_o    (wtb_empty_o),
      
      // AXI Read interface
      .axi_araddr_o   (axi_araddr),
      .axi_arprot_o   (axi_arprot),
      .axi_arvalid_o  (axi_arvalid),
      .axi_arready_i  (axi_arready),
      .axi_rdata_i    (axi_rdata),
      .axi_rresp_i    (axi_rresp),
      .axi_rvalid_i   (axi_rvalid),
      .axi_rready_o   (axi_rready),
      .axi_arid_o     (axi_arid),
      .axi_arlen_o    (axi_arlen),
      .axi_arsize_o   (axi_arsize),
      .axi_arburst_o  (axi_arburst),
      .axi_arlock_o   (axi_arlock),
      .axi_arcache_o  (axi_arcache),
      .axi_arqos_o    (axi_arqos),
      .axi_rid_i      (axi_rid),
      .axi_rlast_i    (axi_rlast),
      
      // AXI Write interface
      .axi_awaddr_o   (axi_awaddr),
      .axi_awprot_o   (axi_awprot),
      .axi_awvalid_o  (axi_awvalid),
      .axi_awready_i  (axi_awready),
      .axi_wdata_o    (axi_wdata),
      .axi_wstrb_o    (axi_wstrb),
      .axi_wvalid_o   (axi_wvalid),
      .axi_wready_i   (axi_wready),
      .axi_bresp_i    (axi_bresp),
      .axi_bvalid_i   (axi_bvalid),
      .axi_bready_o   (axi_bready),
      .axi_awid_o     (axi_awid),
      .axi_awlen_o    (axi_awlen),
      .axi_awsize_o   (axi_awsize),
      .axi_awburst_o  (axi_awburst),
      .axi_awlock_o   (axi_awlock),
      .axi_awcache_o  (axi_awcache),
      .axi_awqos_o    (axi_awqos),
      .axi_wlast_o    (axi_wlast),
      .axi_bid_i      (axi_bid)
   );

   // AXI RAM instance
   iob_axi_ram #(
      .DATA_WIDTH      (BE_DATA_W),
      .ADDR_WIDTH      (BE_ADDR_W),
      .STRB_WIDTH      (BE_NBYTES),
      .READ_ON_WRITE   (READ_ON_WRITE),
      .ID_WIDTH        (AXI_ID_W),
      .LEN_WIDTH       (AXI_LEN_W),
      .PIPELINE_OUTPUT (PIPELINE_OUTPUT),
      .FILE            (RAM_FILE)
   ) ram_inst (
      .clk_i          (clk_i),
      .rst_i          (arst_i),
      
      // AXI Write Address Channel
      .axi_awid_i     (axi_awid),
      .axi_awaddr_i   (axi_awaddr),
      .axi_awlen_i    (axi_awlen),
      .axi_awsize_i   (axi_awsize),
      .axi_awburst_i  (axi_awburst),
      .axi_awlock_i   (axi_awlock),
      .axi_awcache_i  (axi_awcache),
      .axi_awprot_i   (axi_awprot),
      .axi_awqos_i    (axi_awqos),
      .axi_awvalid_i  (axi_awvalid),
      .axi_awready_o  (axi_awready),
      
      // AXI Write Data Channel
      .axi_wdata_i    (axi_wdata),
      .axi_wstrb_i    (axi_wstrb),
      .axi_wlast_i    (axi_wlast),
      .axi_wvalid_i   (axi_wvalid),
      .axi_wready_o   (axi_wready),
      
      // AXI Write Response Channel
      .axi_bid_o      (axi_bid),
      .axi_bresp_o    (axi_bresp),
      .axi_bvalid_o   (axi_bvalid),
      .axi_bready_i   (axi_bready),
      
      // AXI Read Address Channel
      .axi_arid_i     (axi_arid),
      .axi_araddr_i   (axi_araddr),
      .axi_arlen_i    (axi_arlen),
      .axi_arsize_i   (axi_arsize),
      .axi_arburst_i  (axi_arburst),
      .axi_arlock_i   (axi_arlock),
      .axi_arcache_i  (axi_arcache),
      .axi_arprot_i   (axi_arprot),
      .axi_arqos_i    (axi_arqos),
      .axi_arvalid_i  (axi_arvalid),
      .axi_arready_o  (axi_arready),
      
      // AXI Read Data Channel
      .axi_rid_o      (axi_rid),
      .axi_rdata_o    (axi_rdata),
      .axi_rresp_o    (axi_rresp),
      .axi_rlast_o    (axi_rlast),
      .axi_rvalid_o   (axi_rvalid),
      .axi_rready_i   (axi_rready)
   );

endmodule