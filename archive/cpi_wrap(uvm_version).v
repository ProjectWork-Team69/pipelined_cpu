module AXI_CPU_wrapper #
(
    parameter ADDR_WIDTH = 32,
    parameter S_DATA_WIDTH = 32,
    parameter M_DATA_WIDTH = 32,
    parameter SLAVE_ENABLE = 1  // 1=enabled, 0=disabled
)
(
    input         clk, rstn,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    input         MemValid,
    output        MemReady, MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,

    // Master enable for slave interface
    input         slave_enable,

    /*
     * AXI lite master interface - CPU initiates transactions here
     */
    output wire [ADDR_WIDTH-1:0]    m_axil_awaddr,
    output wire                     m_axil_awvalid,
    input  wire                     m_axil_awready,
    output wire [M_DATA_WIDTH-1:0]  m_axil_wdata,
    output wire                     m_axil_wvalid,
    input  wire                     m_axil_wready,
    input  wire [1:0]               m_axil_bresp,
    input  wire                     m_axil_bvalid,
    output wire                     m_axil_bready,
    output wire [ADDR_WIDTH-1:0]    m_axil_araddr,
    output wire                     m_axil_arvalid,
    input  wire                     m_axil_arready,
    input  wire [M_DATA_WIDTH-1:0]  m_axil_rdata,
    input  wire [1:0]               m_axil_rresp,
    input  wire                     m_axil_rvalid,
    output wire                     m_axil_rready,

    /*
     * AXI lite slave interface - For UVM testing and debug
     */
    input  wire [ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire                     s_axil_awvalid,
    output wire                     s_axil_awready,
    input  wire [S_DATA_WIDTH-1:0]  s_axil_wdata,
    input  wire                     s_axil_wvalid,
    output wire                     s_axil_wready,
    output wire [1:0]               s_axil_bresp,
    output wire                     s_axil_bvalid,
    input  wire                     s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire                     s_axil_arvalid,
    output wire                     s_axil_arready,
    output wire [S_DATA_WIDTH-1:0]  s_axil_rdata,
    output wire [1:0]               s_axil_rresp,
    output wire                     s_axil_rvalid,
    input  wire                     s_axil_rready
);

// ============================================================================
// AXI Master Interface (CPU-initiated transactions)
// ============================================================================

// Master Interface State Machine
localparam [2:0] 
    M_IDLE     = 3'd0,
    M_WRITE_AW = 3'd1, 
    M_WRITE_W  = 3'd2,
    M_WRITE_B  = 3'd3,
    M_READ_AR  = 3'd4,
    M_READ_R   = 3'd5;

reg [2:0] m_state, m_next_state;

// Master control registers
reg        m_awvalid_reg, m_wvalid_reg, m_arvalid_reg;
reg [31:0] m_awaddr_reg, m_wdata_reg, m_araddr_reg;
reg        m_bready_reg, m_rready_reg;

// CPU interface registers
reg        MemReady_reg, MemWrite_reg;
reg [31:0] WriteData_reg, DataAdr_reg, ReadData_reg;

// CPU Interface outputs
assign MemReady = MemReady_reg;
assign MemWrite = MemWrite_reg;
assign WriteData = WriteData_reg;
assign DataAdr = DataAdr_reg;
assign ReadData = ReadData_reg;

// AXI Master outputs
assign m_axil_awaddr = m_awaddr_reg;
assign m_axil_awvalid = m_awvalid_reg;
assign m_axil_wdata = m_wdata_reg;
assign m_axil_wvalid = m_wvalid_reg;
assign m_axil_araddr = m_araddr_reg;
assign m_axil_arvalid = m_arvalid_reg;
assign m_axil_bready = m_bready_reg;
assign m_axil_rready = m_rready_reg;

// Master State Machine
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        m_state <= M_IDLE;
    end else begin
        m_state <= m_next_state;
    end
end

always @(*) begin
    m_next_state = m_state;
    
    case (m_state)
        M_IDLE: begin
            if (MemValid && Ext_MemWrite) begin
                m_next_state = M_WRITE_AW;
            end else if (MemValid && !Ext_MemWrite) begin
                m_next_state = M_READ_AR;
            end
        end
        
        M_WRITE_AW: begin
            if (m_axil_awready) begin
                m_next_state = M_WRITE_W;
            end
        end
        
        M_WRITE_W: begin
            if (m_axil_wready) begin
                m_next_state = M_WRITE_B;
            end
        end
        
        M_WRITE_B: begin
            if (m_axil_bvalid) begin
                m_next_state = M_IDLE;
            end
        end
        
        M_READ_AR: begin
            if (m_axil_arready) begin
                m_next_state = M_READ_R;
            end
        end
        
        M_READ_R: begin
            if (m_axil_rvalid) begin
                m_next_state = M_IDLE;
            end
        end
        
        default: m_next_state = M_IDLE;
    endcase
end

// Master Control Logic
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        MemReady_reg <= 1'b0;
        MemWrite_reg <= 1'b0;
        WriteData_reg <= 32'b0;
        DataAdr_reg <= 32'b0;
        ReadData_reg <= 32'b0;
        
        m_awvalid_reg <= 1'b0;
        m_wvalid_reg <= 1'b0;
        m_arvalid_reg <= 1'b0;
        m_awaddr_reg <= 32'b0;
        m_wdata_reg <= 32'b0;
        m_araddr_reg <= 32'b0;
        m_bready_reg <= 1'b0;
        m_rready_reg <= 1'b0;
    end else begin
        // Default assignments
        MemReady_reg <= 1'b0;
        m_bready_reg <= 1'b0;
        m_rready_reg <= 1'b0;
        
        case (m_state)
            M_IDLE: begin
                MemWrite_reg <= 1'b0;
                if (MemValid) begin
                    DataAdr_reg <= Ext_DataAdr;
                    if (Ext_MemWrite) begin
                        MemWrite_reg <= 1'b1;
                        WriteData_reg <= Ext_WriteData;
                        // Setup write address
                        m_awvalid_reg <= 1'b1;
                        m_awaddr_reg <= Ext_DataAdr;
                    end else begin
                        // Setup read address  
                        m_arvalid_reg <= 1'b1;
                        m_araddr_reg <= Ext_DataAdr;
                    end
                end else begin
                    m_awvalid_reg <= 1'b0;
                    m_arvalid_reg <= 1'b0;
                end
            end
            
            M_WRITE_AW: begin
                MemWrite_reg <= 1'b1;
                WriteData_reg <= Ext_WriteData;
                // Setup write data once address is accepted
                if (m_axil_awready) begin
                    m_awvalid_reg <= 1'b0;
                    m_wvalid_reg <= 1'b1;
                    m_wdata_reg <= Ext_WriteData;
                end
            end
            
            M_WRITE_W: begin
                MemWrite_reg <= 1'b1;
                if (m_axil_wready) begin
                    m_wvalid_reg <= 1'b0;
                    m_bready_reg <= 1'b1;  // Ready for write response
                end
            end
            
            M_WRITE_B: begin
                if (m_axil_bvalid) begin
                    m_bready_reg <= 1'b0;
                    MemReady_reg <= 1'b1;  // Write complete
                end
            end
            
            M_READ_AR: begin
                if (m_axil_arready) begin
                    m_arvalid_reg <= 1'b0;
                    m_rready_reg <= 1'b1;  // Ready for read data
                end
            end
            
            M_READ_R: begin
                if (m_axil_rvalid) begin
                    m_rready_reg <= 1'b0;
                    ReadData_reg <= m_axil_rdata;
                    MemReady_reg <= 1'b1;  // Read complete
                end
            end
        endcase
    end
end

// ============================================================================
// AXI Slave Interface (For UVM Testing - Fully Pipelined)
// ============================================================================

// Slave Interface State Machine
localparam [1:0]
    S_IDLE     = 2'd0,
    S_WRITE    = 2'd1,
    S_READ     = 2'd2,
    S_RESP     = 2'd3;

reg [1:0] s_state, s_next_state;

// Slave control registers
reg        s_awready_reg, s_wready_reg, s_arready_reg;
reg        s_bvalid_reg, s_rvalid_reg;
reg [1:0]  s_bresp_reg, s_rresp_reg;
reg [31:0] s_rdata_reg;

// Internal registers for UVM testing
reg [31:0] test_regs [0:15];  // 16 test registers
reg [31:0] s_awaddr_reg, s_araddr_reg, s_wdata_reg;
reg        s_write_pending, s_read_pending;

// AXI Slave outputs (conditionally enabled)
assign s_axil_awready = (SLAVE_ENABLE && slave_enable) ? s_awready_reg : 1'b0;
assign s_axil_wready  = (SLAVE_ENABLE && slave_enable) ? s_wready_reg : 1'b0;
assign s_axil_arready = (SLAVE_ENABLE && slave_enable) ? s_arready_reg : 1'b0;
assign s_axil_bvalid  = (SLAVE_ENABLE && slave_enable) ? s_bvalid_reg : 1'b0;
assign s_axil_bresp   = (SLAVE_ENABLE && slave_enable) ? s_bresp_reg : 2'b00;
assign s_axil_rvalid  = (SLAVE_ENABLE && slave_enable) ? s_rvalid_reg : 1'b0;
assign s_axil_rresp   = (SLAVE_ENABLE && slave_enable) ? s_rresp_reg : 2'b00;
assign s_axil_rdata   = (SLAVE_ENABLE && slave_enable) ? s_rdata_reg : 32'b0;

// Slave State Machine
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_state <= S_IDLE;
    end else if (SLAVE_ENABLE && slave_enable) begin
        s_state <= s_next_state;
    end else begin
        s_state <= S_IDLE;
    end
end

// Slave Next State Logic
always @(*) begin
    s_next_state = s_state;
    
    if (SLAVE_ENABLE && slave_enable) begin
        case (s_state)
            S_IDLE: begin
                if (s_axil_awvalid && s_axil_wvalid) begin
                    s_next_state = S_WRITE;
                end else if (s_axil_arvalid) begin
                    s_next_state = S_READ;
                end
            end
            
            S_WRITE: begin
                s_next_state = S_RESP;
            end
            
            S_READ: begin
                s_next_state = S_RESP;
            end
            
            S_RESP: begin
                if ((s_bvalid_reg && s_axil_bready) || (s_rvalid_reg && s_axil_rready)) begin
                    s_next_state = S_IDLE;
                end
            end
        endcase
    end else begin
        s_next_state = S_IDLE;
    end
end

// Slave Control Logic and Register Access
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        s_awready_reg <= 1'b0;
        s_wready_reg <= 1'b0;
        s_arready_reg <= 1'b0;
        s_bvalid_reg <= 1'b0;
        s_rvalid_reg <= 1'b0;
        s_bresp_reg <= 2'b00;
        s_rresp_reg <= 2'b00;
        s_rdata_reg <= 32'b0;
        s_awaddr_reg <= 32'b0;
        s_araddr_reg <= 32'b0;
        s_wdata_reg <= 32'b0;
        s_write_pending <= 1'b0;
        s_read_pending <= 1'b0;
        
        // Initialize test registers
        for (integer i = 0; i < 16; i = i + 1) begin
            test_regs[i] <= 32'b0;
        end
    end else if (SLAVE_ENABLE && slave_enable) begin
        // Default assignments
        s_awready_reg <= 1'b0;
        s_wready_reg <= 1'b0;
        s_arready_reg <= 1'b0;
        
        case (s_state)
            S_IDLE: begin
                s_awready_reg <= 1'b1;
                s_wready_reg <= 1'b1;
                s_arready_reg <= 1'b1;
                
                // Capture write transaction
                if (s_axil_awvalid && s_axil_wvalid) begin
                    s_awaddr_reg <= s_axil_awaddr;
                    s_wdata_reg <= s_axil_wdata;
                    s_write_pending <= 1'b1;
                    s_awready_reg <= 1'b0;
                    s_wready_reg <= 1'b0;
                    s_arready_reg <= 1'b0;
                end 
                // Capture read transaction
                else if (s_axil_arvalid) begin
                    s_araddr_reg <= s_axil_araddr;
                    s_read_pending <= 1'b1;
                    s_awready_reg <= 1'b0;
                    s_wready_reg <= 1'b0;
                    s_arready_reg <= 1'b0;
                end
            end
            
            S_WRITE: begin
                // Perform write operation to test registers
                if (s_write_pending) begin
                    // Map address to register index (4-byte aligned)
                    if (s_awaddr_reg[31:4] == 28'b0) begin // Only map lower 16 registers
                        integer reg_index = s_awaddr_reg[5:2]; // 4-bit index for 16 registers
                        if (reg_index < 16) begin
                            test_regs[reg_index] <= s_wdata_reg;
                            s_bresp_reg <= 2'b00; // OKAY
                        end else begin
                            s_bresp_reg <= 2'b10; // SLVERR
                        end
                    end else begin
                        s_bresp_reg <= 2'b10; // SLVERR
                    end
                    s_bvalid_reg <= 1'b1;
                    s_write_pending <= 1'b0;
                end
            end
            
            S_READ: begin
                // Perform read operation from test registers
                if (s_read_pending) begin
                    if (s_araddr_reg[31:4] == 28'b0) begin // Only map lower 16 registers
                        integer reg_index = s_araddr_reg[5:2]; // 4-bit index for 16 registers
                        if (reg_index < 16) begin
                            s_rdata_reg <= test_regs[reg_index];
                            s_rresp_reg <= 2'b00; // OKAY
                        end else begin
                            s_rdata_reg <= 32'hDEADBEEF;
                            s_rresp_reg <= 2'b10; // SLVERR
                        end
                    end else begin
                        s_rdata_reg <= 32'hDEADBEEF;
                        s_rresp_reg <= 2'b10; // SLVERR
                    end
                    s_rvalid_reg <= 1'b1;
                    s_read_pending <= 1'b0;
                end
            end
            
            S_RESP: begin
                // Clear response when accepted
                if (s_bvalid_reg && s_axil_bready) begin
                    s_bvalid_reg <= 1'b0;
                end
                if (s_rvalid_reg && s_axil_rready) begin
                    s_rvalid_reg <= 1'b0;
                end
            end
        endcase
    end else begin
        // Slave interface disabled
        s_awready_reg <= 1'b0;
        s_wready_reg <= 1'b0;
        s_arready_reg <= 1'b0;
        s_bvalid_reg <= 1'b0;
        s_rvalid_reg <= 1'b0;
        s_bresp_reg <= 2'b00;
        s_rresp_reg <= 2'b00;
        s_rdata_reg <= 32'b0;
        s_write_pending <= 1'b0;
        s_read_pending <= 1'b0;
    end
end

// ============================================================================
// UVM-Compatible Features
// ============================================================================

// Status outputs for UVM monitoring
wire [31:0] uvm_slave_status;
assign uvm_slave_status = {
    28'b0,                    // Reserved
    s_rvalid_reg,             // Read response valid
    s_bvalid_reg,             // Write response valid  
    s_arready_reg,            // Read address ready
    s_awready_reg             // Write address ready
};

// Test register 0: Control register
// Test register 1: Status register  
// Test register 2-15: General purpose test registers

// UVM register access functions (for direct testbench access)
// These would typically be in a separate interface for UVM

endmodule