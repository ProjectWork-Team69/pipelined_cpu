module FF_de_ex (
    input   clk, clr,
    //control signals
    input   RegWriteD,
    input   [1:0] ResultSrcD,
    input   MemWriteD,
    input   JumpD, JalrD, BranchD,
    input   [3:0] ALUControlD,
    input   ALUSrcD,
    input   [31:0]InstrD,

    //data signals
    input [31:0] RD1D, RD2D,
    input [31:0] PCD,
    input [4:0] Rs1D, Rs2D, RdD,
    input [31:0] ImmExtD,PC_plus4D,
    input [2:0] funct3D,

    output reg   RegWriteE,
    output reg   [1:0] ResultSrcE,
    output reg   MemWriteE,
    output reg   JumpE, JalrE, BranchE,
    output reg   [3:0] ALUControlE,
    output reg   ALUSrcE,
    output reg  [31:0] InstrE,
    output reg [31:0] RD1E, RD2E,
    output reg [31:0] PCE,
    output reg [4:0] Rs1E, Rs2E, RdE,
    output reg [31:0] ImmExtE,PC_plus4E,
    output reg [2:0] funct3E
);

// initial begin
//     RegWriteE   = 0;
//     ResultSrcE  = 0;
//     MemWriteE   = 0;
//     JumpE       = 0; JalrE = 0; BranchE = 0;
//     ALUControlE = 0; ALUSrcE = 0;InstrE = 0;
//     RD1E        = 0; RD2E = 0;
//     PCE         = 0;
//     Rs1E        = 0; Rs2E = 0; RdE = 0;
//     ImmExtE     = 0; PC_plus4E = 0;
//     funct3E     = 0;
// end
always @(posedge clk) begin
    if (clr) begin
        RegWriteE   <= 0;
        ResultSrcE  <= 0;
        MemWriteE   <= 0;
        JumpE       <= 0; JalrE <= 0; BranchE <= 0;
        ALUControlE <= 0; ALUSrcE <= 0;InstrE <= 0;
        RD1E        <= 0; RD2E <= 0;
        PCE         <= 0;
        Rs1E        <= 0; Rs2E <= 0; RdE <= 0;
        ImmExtE     <= 0; PC_plus4E <= 0; 
        funct3E     <= 0;
    end else begin
        RegWriteE   <= RegWriteD;
        ResultSrcE  <= ResultSrcD;
        MemWriteE   <= MemWriteD;
        JumpE       <= JumpD; JalrE <= JalrD; BranchE <= BranchD;
        ALUControlE <= ALUControlD; ALUSrcE <= ALUSrcD;InstrE <= InstrD;
        RD1E        <= RD1D; RD2E <= RD2D;
        PCE         <= PCD;
        Rs1E        <= Rs1D; Rs2E <= Rs2D; RdE <= RdD;
        ImmExtE     <= ImmExtD; PC_plus4E <= PC_plus4D;
        funct3E     <= funct3D; 
    end
end


    endmodule