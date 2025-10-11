module dumper #(
    parameter FE_ADDR_W     = 32,
    parameter FE_DATA_W     = 32,
    parameter BE_ADDR_W     = 32,
    parameter BE_DATA_W     = 32,
    parameter NWAYS_W       = 2,
    parameter NLINES_W      = 7,
    parameter WORD_OFFSET_W = 4,
    parameter WTBUF_DEPTH_W = 4,
    parameter REP_POLICY    = 1,
    parameter WRITE_POL     = 1,  // Write-through
    parameter USE_CTRL      = 0,
    parameter USE_CTRL_CNT  = 0
) (
    // System signals
    reg         clk,
    reg         reset,
    
    // External control/debug interface
    reg         Ext_MemWrite,
    reg  [31:0] Ext_WriteData,
    reg  [31:0] Ext_DataAdr,
    
    // Back-end memory interface (to external memory)
    wire        be_valid_o,
    wire [31:0] be_addr_o,
    wire [31:0] be_wdata_o,
    wire [3:0]  be_wstrb_o,
    reg  [31:0] be_rdata_i,
    reg         be_rvalid_i,
    reg         be_ready_i,
    
    // Cache control
    reg         invalidate_i,
    wire        invalidate_o,
    reg         wtb_empty_i,
    wire        wtb_empty_o,
    
    // CPU wires for monitoring
    wire        MemWrite,
    wire [31:0] WriteData,
    wire [31:0] DataAdr,
    wire [31:0] ReadData,
    wire [31:0] PCW,
    wire [31:0] Result,
    wire [31:0] ALUResultW,
    wire [31:0] WriteDataW
);

frontend_top #(
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
    .USE_CTRL_CNT  (USE_CTRL_CNT)
) dut (
    // System signals
    .clk                (clk),
    .reset              (reset),
    
    // External control/debug interface
    .Ext_MemWrite      (Ext_MemWrite),
    .Ext_WriteData     (Ext_WriteData),
    .Ext_DataAdr       (Ext_DataAdr),
    
    // Back-end memory interface (to external memory)
    .be_valid_o        (be_valid_o),
    .be_addr_o         (be_addr_o),
    .be_wdata_o        (be_wdata_o),
    .be_wstrb_o        (be_wstrb_o),
    .be_rdata_i        (be_rdata_i),
    .be_rvalid_i       (be_rvalid_i),
    .be_ready_i        (be_ready_i),
    
    // Cache control
    .invalidate_i      (invalidate_i),
    .invalidate_o      (invalidate_o),
    .wtb_empty_i       (wtb_empty_i),
    .wtb_empty_o       (wtb_empty_o),
    
    // CPU outputs for monitoring
    .MemWrite          (MemWrite),
    .WriteData         (WriteData),
    .DataAdr           (DataAdr),
    .ReadData          (ReadData),
    .PCW               (PCW),
    .Result            (Result),
    .ALUResultW        (ALUResultW),
    .WriteDataW        (WriteDataW)
);