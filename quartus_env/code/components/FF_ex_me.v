module FF_ex_me (
    input  clk,
    input RegWriteE,
    input [1:0] ResultSrcE,
    input MemWriteE,
    input [31:0] ALUResultE,
    input [31:0] WriteDataE,PCE,
    input [4:0] RdE,
    input [31:0] PC_plus4E,
    input [31:0] lAuiPC,
    input [2:0] funct3E,

    output reg RegWriteM,
    output reg [1:0] ResultSrcM,
    output reg MemWriteM,
    output reg [31:0] ALUResultM,
    output reg [31:0] WriteDataM,PCW,
    output reg [4:0] RdM,
    output reg [31:0] PC_plus4M,
    output reg [31:0] lAuiPCM,
    output reg [2:0] funct3M
);
initial begin
    RegWriteM   = 0;
    ResultSrcM  = 0;
    MemWriteM   = 0;
    ALUResultM  = 0;
    WriteDataM  = 0;
    PCW         = 0;
    RdM         = 0;
    PC_plus4M   = 0;
    lAuiPCM     = 0;
    funct3M     = 0;
end
always @(posedge clk) begin
    RegWriteM   <= RegWriteE;
    ResultSrcM  <= ResultSrcE;
    MemWriteM   <= MemWriteE;
    ALUResultM  <= ALUResultE;
    WriteDataM  <= WriteDataE;
    PCW         <= PCE;
    RdM         <= RdE;
    PC_plus4M   <= PC_plus4E;
    lAuiPCM     <= lAuiPC;
    funct3M     <= funct3E;
end


endmodule