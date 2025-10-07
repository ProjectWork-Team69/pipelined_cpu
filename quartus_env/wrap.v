module wrap #
(
    parameter ADDR_WIDTH = 32,
    parameter S_DATA_WIDTH = 32,
    parameter M_DATA_WIDTH = 32
)
(
    input         clk, rstn,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    input         MemValid,
    output        MemReady, MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,

    /*
     * AXI lite master interface
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
    output wire                     m_axil_rready
);

pl_riscv_cpu u_cpu (
    .clk         (clk),
    .rstn        (rstn),
    .Ext_MemWrite(Ext_MemWrite),
    .Ext_WriteData(Ext_WriteData),
    .Ext_DataAdr (Ext_DataAdr),
    .MemValid    (MemValid),
    .MemReady    (MemReady),
    .MemWrite    (MemWrite),
    .WriteData   (WriteData),
    .DataAdr     (DataAdr),
    .ReadData    (ReadData)
);
reg [2:0] state, next_state;
parameter IDLE=3'd0, WRITE_REQ=3'd1, WRITE_DATA=3'd2, READ_REQ=3'd3, WAIT_RDATA=3'd4, WAIT_BRESP=3'd5;

// Registered outputs
reg        MemReady_reg, MemWrite_reg;
reg [31:0] WriteData_reg, DataAdr_reg, ReadData_reg;

// AXI Master control signals
reg        awvalid_reg, wvalid_reg, arvalid_reg;
reg [31:0] awaddr_reg, wdata_reg, araddr_reg;

// AXI Slave control signals  
reg        awready_reg, wready_reg, arready_reg;
reg        bvalid_reg, rvalid_reg;
reg [1:0]  bresp_reg, rresp_reg;
reg [31:0] rdata_reg;

// Assign outputs
assign MemReady = MemReady_reg;
assign MemWrite = MemWrite_reg;
assign WriteData = WriteData_reg;
assign DataAdr = DataAdr_reg;
assign ReadData = ReadData_reg;

// AXI Master outputs
assign m_axil_awaddr = awaddr_reg;
assign m_axil_awvalid = awvalid_reg;
assign m_axil_wdata = wdata_reg;
assign m_axil_wvalid = wvalid_reg;
assign m_axil_araddr = araddr_reg;
assign m_axil_arvalid = arvalid_reg;
assign m_axil_bready = 1'b1;  // Always ready to accept write response
assign m_axil_rready = 1'b1;  // Always ready to accept read data

// AXI Slave outputs
assign s_axil_awready = awready_reg;
assign s_axil_wready = wready_reg;
assign s_axil_arready = arready_reg;
assign s_axil_bvalid = bvalid_reg;
assign s_axil_bresp = bresp_reg;
assign s_axil_rvalid = rvalid_reg;
assign s_axil_rresp = rresp_reg;
assign s_axil_rdata = rdata_reg;

// State machine
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin
            if (MemValid && Ext_MemWrite) begin
                next_state = WRITE_REQ;
            end else if (MemValid && !Ext_MemWrite) begin
                next_state = READ_REQ;
            end
        end
        WRITE_REQ: begin
            if (m_axil_awready && m_axil_wready) begin
                next_state = WAIT_BRESP;
            end else if (m_axil_awready) begin
                next_state = WRITE_DATA;
            end
        end
        WRITE_DATA: begin
            if (m_axil_wready) begin
                next_state = WAIT_BRESP;
            end
        end
        READ_REQ: begin
            if (m_axil_arready) begin
                next_state = WAIT_RDATA;
            end
        end
        WAIT_RDATA: begin
            if (m_axil_rvalid) begin
                next_state = IDLE;
            end
        end
        WAIT_BRESP: begin
            if (m_axil_bvalid) begin
                next_state = IDLE;
            end
        end
        default: next_state = IDLE;
    endcase
end

// Main control logic
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        MemReady_reg <= 1'b0;
        MemWrite_reg <= 1'b0;
        WriteData_reg <= 32'b0;
        DataAdr_reg <= 32'b0;
        ReadData_reg <= 32'b0;
        
        awvalid_reg <= 1'b0;
        wvalid_reg <= 1'b0;
        arvalid_reg <= 1'b0;
        awaddr_reg <= 32'b0;
        wdata_reg <= 32'b0;
        araddr_reg <= 32'b0;
        
        // AXI Slave defaults
        awready_reg <= 1'b0;
        wready_reg <= 1'b0;
        arready_reg <= 1'b0;
        bvalid_reg <= 1'b0;
        rvalid_reg <= 1'b0;
        bresp_reg <= 2'b00;
        rresp_reg <= 2'b00;
        rdata_reg <= 32'b0;
    end else begin
        // Default values
        MemReady_reg <= 1'b0;
        awvalid_reg <= 1'b0;
        wvalid_reg <= 1'b0;
        arvalid_reg <= 1'b0;
        awready_reg <= 1'b0;
        wready_reg <= 1'b0;
        arready_reg <= 1'b0;
        bvalid_reg <= 1'b0;
        rvalid_reg <= 1'b0;
        
        case (state)
            IDLE: begin
                MemWrite_reg <= 1'b0;
                if (MemValid) begin
                    DataAdr_reg <= Ext_DataAdr;
                    if (Ext_MemWrite) begin
                        MemWrite_reg <= 1'b1;
                        WriteData_reg <= Ext_WriteData;
                        // Setup write transaction
                        awvalid_reg <= 1'b1;
                        wvalid_reg <= 1'b1;
                        awaddr_reg <= Ext_DataAdr;
                        wdata_reg <= Ext_WriteData;
                    end else begin
                        // Setup read transaction
                        arvalid_reg <= 1'b1;
                        araddr_reg <= Ext_DataAdr;
                    end
                end
            end
            WRITE_REQ: begin
                MemWrite_reg <= 1'b1;
                WriteData_reg <= Ext_WriteData;
                awvalid_reg <= 1'b1;
                wvalid_reg <= 1'b1;
                awaddr_reg <= Ext_DataAdr;
                wdata_reg <= Ext_WriteData;
            end
            WRITE_DATA: begin
                MemWrite_reg <= 1'b1;
                WriteData_reg <= Ext_WriteData;
                wvalid_reg <= 1'b1;
                wdata_reg <= Ext_WriteData;
            end
            READ_REQ: begin
                MemWrite_reg <= 1'b0;
                arvalid_reg <= 1'b1;
                araddr_reg <= Ext_DataAdr;
            end
            WAIT_RDATA: begin
                MemWrite_reg <= 1'b0;
                if (m_axil_rvalid) begin
                    ReadData_reg <= m_axil_rdata;
                    MemReady_reg <= 1'b1;
                end
            end
            WAIT_BRESP: begin
                MemWrite_reg <= 1'b0;
                if (m_axil_bvalid) begin
                    MemReady_reg <= 1'b1;
                end
            end
        endcase
        
//         // Simple AXI Slave handling - always ready to accept transactions
//         if (s_axil_awvalid) awready_reg <= 1'b1;
//         if (s_axil_wvalid) wready_reg <= 1'b1;
//         if (s_axil_arvalid) arready_reg <= 1'b1;
        
//         // Generate write response
//         if (s_axil_bready && bvalid_reg) begin
//             bvalid_reg <= 1'b0;
//         end else if (awready_reg && wready_reg) begin
//             bvalid_reg <= 1'b1;
//             bresp_reg <= 2'b00; // OKAY response
//         end
        
//         // Generate read response
//         if (s_axil_rready && rvalid_reg) begin
//             rvalid_reg <= 1'b0;
//         end else if (arready_reg) begin
//             rvalid_reg <= 1'b1;
//             rresp_reg <= 2'b00; // OKAY response
//             rdata_reg <= 32'hDEADBEEF; // Example data
//         end
//     end
// end

endmodule

/* AXI parameters
1. CPU-Side Interface (your “native” signals)

| **Signal**      | **Dir** | **Meaning**                                             |
| --------------- | ------- | ------------------------------------------------------- |
| `Ext_MemWrite`  | in      | External request → whether it’s a store (1) or load (0) |
| `Ext_WriteData` | in      | Data for store                                          |
| `Ext_DataAdr`   | in      | Address for read/write                                  |
| `MemValid`      | in      | CPU/external request valid (start transaction)          |
| `MemReady`      | in      | Transaction done (ack from AXI)                         |
| `MemWrite`      | out     | To CPU: actual write enable (after arbitration)         |
| `WriteData`     | out     | To CPU: the data going to AXI write channel             |
| `DataAdr`       | out     | To CPU: the address going to AXI (read or write)        |
| `ReadData`      | out     | To CPU: data returned from AXI read channel             |

2. AXI-Lite Master Interface (towards memory or interconnect)

| **AXI Master Signal** | **Maps to/from CPU Signals**                | **Notes**                                    |
| --------------------- | ------------------------------------------- | -------------------------------------------- |
| `m_axil_awaddr`       | `Ext_DataAdr` (when write)                  | CPU write address                            |
| `m_axil_awvalid`      | `MemValid & Ext_MemWrite`                   | Assert only when write is requested          |
| `m_axil_wdata`        | `Ext_WriteData`                             | Data for AXI write                           |
| `m_axil_wvalid`       | `MemValid & Ext_MemWrite`                   | Valid for AXI write                          |
| `m_axil_bready`       | `1` (always ready)                          | Accept write response immediately            |
| `m_axil_araddr`       | `Ext_DataAdr` (when read)                   | CPU read address                             |
| `m_axil_arvalid`      | `MemValid & ~Ext_MemWrite`                  | Assert only when read is requested           |
| `m_axil_rready`       | `1` (always ready)                          | Always ready to accept read data             |
| `m_axil_rdata`        | → `ReadData`                                | Data returned to CPU                         |
| `m_axil_rvalid`       | → generates `MemReady` (for read)           | CPU can latch `ReadData` when this goes high |
| `m_axil_bvalid`       | → generates `MemReady` (for write complete) | CPU sees store is done when this goes high   |
*/