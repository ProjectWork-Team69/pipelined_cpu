ddmodule FF_me_wr (
    input clk,
    input RegWriteM,
    input [1:0] ResultSrcM,
    input [31:0] ALUResultM,
    input [31:0] ReadDataM,PCM,
    input [4:0] RdM,
    input [31:0] PC_plus4M,
    input [31:0] lAuiPCM,WriteDataM,

    output reg RegWriteW,
    output reg [1:0] ResultSrcW,
    output reg [31:0] ALUResultW,
    output reg [31:0] ReadDataW,PCW,
    output reg [4:0] RdW,
    output reg [31:0] PC_plus4W,
    output reg [31:0] lAuiPCW,WriteDataW
);


initial begin
    RegWriteW   = 0;
    ResultSrcW  = 0;
    ALUResultW  = 0;
    ReadDataW   = 0;
    PCW        = 0;
    RdW         = 0;
    PC_plus4W   = 0;
    lAuiPCW     = 0;
    WriteDataW  = 0;
end
always @(posedge clk) begin
    RegWriteW   <= RegWriteM;
    ResultSrcW  <= ResultSrcM;
    ALUResultW  <= ALUResultM;
    ReadDataW   <= ReadDataM;
    PCW         <= PCM;
    RdW         <= RdM;
    PC_plus4W   <= PC_plus4M;
    lAuiPCW     <= lAuiPCM;
    WriteDataW  <= WriteDataM;
end 
endmodule