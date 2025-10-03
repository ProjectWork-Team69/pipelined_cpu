module system_top (
    input clk, rstn,
    // AXI master interface to external memory
    output wire [31:0] m_axil_awaddr,
    // ... other AXI ports
    // AXI slave interface for debug
    input wire [31:0] s_axil_awaddr,
    // ... other AXI slave ports
);

    // Internal signals between CPU and wrapper
    wire        Ext_MemWrite;
    wire [31:0] Ext_WriteData, Ext_DataAdr;
    wire        MemWrite;
    wire [31:0] WriteData, DataAdr, ReadData;
    wire [31:0] PCW, Result, ALUResultW, WriteDataW;

    // Instantiate AXI wrapper
    AXI_CPU_wrapper axi_wrapper_inst (
        .clk(clk),
        .rstn(rstn),
        .Ext_MemWrite(Ext_MemWrite),
        .Ext_WriteData(Ext_WriteData),
        .Ext_DataAdr(Ext_DataAdr),
        .MemValid(1'b1),  // Or your control logic
        .MemReady(MemReady),
        .MemWrite(MemWrite),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .ReadData(ReadData),
        // ... connect AXI ports
    );

    // Instantiate CPU
    pl_riscv_cpu cpu_inst (
        .clk(clk),
        .reset(~rstn),
        .Ext_MemWrite(Ext_MemWrite),
        .Ext_WriteData(Ext_WriteData),
        .Ext_DataAdr(Ext_DataAdr),
        .MemWrite(MemWrite),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .ReadData(ReadData),
        .PCW(PCW),
        .Result(Result),
        .ALUResultW(ALUResultW),
        .WriteDataW(WriteDataW)
    );

endmodule