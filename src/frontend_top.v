module frontend_top #(
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
    input         clk,
    input         reset,
    
    // External control/debug interface
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData,
    input  [31:0] Ext_DataAdr,
    
    // Back-end memory interface (to external memory)
    output        be_valid_o,
    output [31:0] be_addr_o,
    output [31:0] be_wdata_o,
    output [3:0]  be_wstrb_o,
    input  [31:0] be_rdata_i,
    input         be_rvalid_i,
    input         be_ready_i,
    
    // Cache control
    input         invalidate_i,
    output        invalidate_o,
    input         wtb_empty_i,
    output        wtb_empty_o,
    
    // CPU outputs for monitoring
    output        MemWrite,
    output [31:0] WriteData,
    output [31:0] DataAdr,
    output [31:0] ReadData,
    output [31:0] PCW,
    output [31:0] Result,
    output [31:0] ALUResultW,
    output [31:0] WriteDataW
);

    // Derived parameters
    localparam FE_NBYTES_W = $clog2(FE_DATA_W / 8);
    localparam ADDR_W = USE_CTRL + FE_ADDR_W - FE_NBYTES_W;
    
    // CPU interface signals
    wire        cpu_mem_write;
    wire [31:0] cpu_write_data;
    wire [31:0] cpu_data_adr;
    wire [31:0] cpu_read_data_out;  // CPU's ReadData output
    
    // IOB Cache interface signals
    reg         iob_valid;
    reg  [ADDR_W-1:0] iob_addr;
    reg  [31:0] iob_wdata;
    reg  [3:0]  iob_wstrb;
    wire        iob_rvalid;
    wire [31:0] iob_rdata;
    wire        iob_ready;
    
    // CPU-to-Cache adapter state machine
    localparam IDLE       = 3'b000;
    localparam REQ_SENT   = 3'b001;
    localparam WAIT_READ  = 3'b010;
    localparam READ_DONE  = 3'b011;
    localparam WRITE_DONE = 3'b100;
    
    reg [2:0]  state, next_state;
    reg [31:0] read_data_reg;
    reg        mem_access_pending;
    reg        last_was_write;
    
    // Detect new memory access request from CPU
    wire new_mem_request = (cpu_data_adr != 32'b0) && !mem_access_pending;
    wire is_write_request = cpu_mem_write;
    wire is_read_request = !cpu_mem_write;
    
    // CPU instantiation
    pl_riscv_cpu cpu (
        .clk(clk),
        .reset(reset),
        .Ext_MemWrite(Ext_MemWrite),
        .Ext_WriteData(Ext_WriteData),
        .Ext_DataAdr(Ext_DataAdr),
        .MemWrite(cpu_mem_write),
        .WriteData(cpu_write_data),
        .DataAdr(cpu_data_adr),
        .ReadData(cpu_read_data_out),
        .PCW(PCW),
        .Result(Result),
        .ALUResultW(ALUResultW),
        .WriteDataW(WriteDataW)
    );
    
    // State machine: CPU to IOB protocol adapter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            read_data_reg <= 32'b0;
            mem_access_pending <= 1'b0;
            last_was_write <= 1'b0;
            iob_valid <= 1'b0;
            iob_addr <= {ADDR_W{1'b0}};
            iob_wdata <= 32'b0;
            iob_wstrb <= 4'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (new_mem_request) begin
                        // Latch the request to IOB interface
                        iob_valid <= 1'b1;
                        iob_addr <= cpu_data_adr[ADDR_W+FE_NBYTES_W-1:FE_NBYTES_W];
                        iob_wdata <= cpu_write_data;
                        iob_wstrb <= is_write_request ? 4'b1111 : 4'b0000;
                        mem_access_pending <= 1'b1;
                        last_was_write <= is_write_request;
                    end else begin
                        iob_valid <= 1'b0;
                        mem_access_pending <= 1'b0;
                    end
                end
                
                REQ_SENT: begin
                    if (iob_ready) begin
                        iob_valid <= 1'b0;  // Request accepted
                        if (last_was_write) begin
                            // Write completes immediately when ready
                            mem_access_pending <= 1'b0;
                        end
                    end
                end
                
                WAIT_READ: begin
                    if (iob_rvalid) begin
                        read_data_reg <= iob_rdata;
                        mem_access_pending <= 1'b0;
                    end
                end
                
                READ_DONE: begin
                    // Hold read data for one cycle
                    mem_access_pending <= 1'b0;
                end
                
                WRITE_DONE: begin
                    mem_access_pending <= 1'b0;
                end
                
                default: begin
                    iob_valid <= 1'b0;
                    mem_access_pending <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (new_mem_request) begin
                    next_state = REQ_SENT;
                end
            end
            
            REQ_SENT: begin
                if (iob_ready) begin
                    if (last_was_write) begin
                        next_state = WRITE_DONE;
                    end else begin
                        if (iob_rvalid) begin
                            next_state = READ_DONE;
                        end else begin
                            next_state = WAIT_READ;
                        end
                    end
                end
            end
            
            WAIT_READ: begin
                if (iob_rvalid) begin
                    next_state = READ_DONE;
                end
            end
            
            READ_DONE: begin
                next_state = IDLE;
            end
            
            WRITE_DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output assignments for monitoring
    assign MemWrite = cpu_mem_write;
    assign WriteData = cpu_write_data;
    assign DataAdr = cpu_data_adr;
    // Provide read data from cache to external monitor
    assign ReadData = (state == READ_DONE || state == WAIT_READ) ? read_data_reg : 
                    (iob_rvalid ? iob_rdata : 32'b0);
    
    // IOB Cache instantiation
    iob_cache_iob #(
        .FE_ADDR_W(FE_ADDR_W),
        .FE_DATA_W(FE_DATA_W),
        .BE_ADDR_W(BE_ADDR_W),
        .BE_DATA_W(BE_DATA_W),
        .NWAYS_W(NWAYS_W),
        .NLINES_W(NLINES_W),
        .WORD_OFFSET_W(WORD_OFFSET_W),
        .WTBUF_DEPTH_W(WTBUF_DEPTH_W),
        .REP_POLICY(REP_POLICY),
        .WRITE_POL(WRITE_POL),
        .USE_CTRL(USE_CTRL),
        .USE_CTRL_CNT(USE_CTRL_CNT)
    ) cache (
        // Front-end interface (IOB protocol)
        .iob_valid_i(iob_valid),
        .iob_addr_i(iob_addr),
        .iob_wdata_i(iob_wdata),
        .iob_wstrb_i(iob_wstrb),
        .iob_rvalid_o(iob_rvalid),
        .iob_rdata_o(iob_rdata),
        .iob_ready_o(iob_ready),
        
        // Back-end interface (to memory)
        .be_valid_o(be_valid_o),
        .be_addr_o(be_addr_o),
        .be_wdata_o(be_wdata_o),
        .be_wstrb_o(be_wstrb_o),
        .be_rdata_i(be_rdata_i),
        .be_rvalid_i(be_rvalid_i),
        .be_ready_i(be_ready_i),
        
        // Cache control chain
        .invalidate_i(invalidate_i),
        .invalidate_o(invalidate_o),
        .wtb_empty_i(wtb_empty_i),
        .wtb_empty_o(wtb_empty_o),
        
        // System signals
        .clk_i(clk),
        .cke_i(1'b1),
        .arst_i(reset)
    );

endmodule