
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrcD,
    input         ALUSrcD, RegWriteD,MemWriteD,
    input [1:0]   ImmSrcD,
    input [3:0]   ALUControlD,
    input         BranchD, JumpD, JalrD,
    output [31:0] PCF,
    output        MemWriteM,
    input  [31:0] InstrF,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadDataM,
    output [31:0] ResultW,
    output [31:0] PCW, ALUResultW, WriteDataW,
    output [2:0] funct3M,
    output [31:0] InstrD
);

//alu wires
wire [31:0] PCNext, PCJalr,PCPlus4E,PCPlus4W, PCTargetE, AuiPC, lAuiPC;
wire [31:0]  SrcA, SrcB, WriteDataE ;
wire Zero, TakeBranch;
wire [2:0] funct3E,funct3D;


//wire for pipleine registers fetch to decode
wire StallF,stallD;
wire FlushD;
wire [31:0] PCPlus4F;
wire [31:0] InstrD,InstrE,PCD;
wire [31:0] PCPlus4D;


// wires for pipeline registers decode to execute
wire RegWriteE;
wire [1:0] ResultSrcE,ResultSrcW;
wire MemWriteE;
wire JumpE,JalrE;
wire BranchE;
wire [3:0] ALUControlE;
wire ALUSrcE;
wire [31:0] RD1E,RD2E,RD1D,RD2D;
wire [31:0] PCE,PCM;
wire [4:0] Rs1E,Rs2E,RdE;
wire [31:0] ImmExtE,ImmExtD;
wire FlushE;

// wires for pipeline registers execute to memory
wire RegWriteM;
wire [1:0] ResultSrcM;
wire [31:0] ALUResultE,PCPlus4M,WriteDataM;
wire [4:0]RdM;

// wires for pipeline registers memory to writeback 
wire [31:0]ALUResultM;
wire RegWriteW;
wire [31:0] lAuiPCW,ReadDataW;
wire [4:0]RdW;
wire [1:0]ForwardBE,ForwardAE;

wire PCSrc = ((BranchE & TakeBranch) || JumpE || JalrE) ? 1'b1 : 1'b0;


// next PC logic
mux2 #(32)     pcmux(PCPlus4F, PCTargetE, PCSrc, PCNext);
mux2 #(32)     jalrmux (PCNext, ALUResultE, JalrE, PCJalr);

 
reset_ff #(32) pcreg(clk, reset, StallF, PCJalr, PCF);
adder          pcadd4(PCF, 32'd4, PCPlus4F);

// Pipeline Register 1 -> Fetch | Decode
FF_fe_de reg1 (clk,FlushD,stallD,InstrF,PCF,PCPlus4F,InstrD,PCD,PCPlus4D);
assign funct3D = InstrD[14:12];

// register file logic
reg_file       rf (clk, RegWriteW, InstrD[19:15], InstrD[24:20], RdW, ResultW, RD1D, RD2D);
imm_extend     ext (InstrD[31:7], ImmSrcD, ImmExtD);


// Pipeline Register 2 -> Decode | Execute
FF_de_ex reg2(clk,FlushE,RegWriteD,ResultSrcD,MemWriteD,JumpD,JalrD,BranchD,ALUControlD,ALUSrcD,InstrD,RD1D,RD2D,PCD,InstrD[19:15],InstrD[24:20],InstrD[11:7],ImmExtD,PCPlus4D,funct3D,
            RegWriteE,ResultSrcE,MemWriteE,JumpE,JalrE,BranchE,ALUControlE,ALUSrcE,InstrE,RD1E,RD2E,PCE,Rs1E,Rs2E,RdE,ImmExtE,PCPlus4E,funct3E);


// ALU logic
mux3 #(32)  srcbmux(RD2E, ResultW,ALUResultM, ForwardBE, WriteDataE);
mux2 #(32)     bmux(WriteDataE, ImmExtE, ALUSrcE, SrcB);

mux3 #(32)  srcamux(RD1E, ResultW,ALUResultM, ForwardAE, SrcA);
alu            alu (SrcA, SrcB, ALUControlE, ALUResultE, Zero);

// branch target adder
adder          pcaddbranch(PCE, ImmExtE, PCTargetE);

adder #(32)    auipcadder ({InstrE[31:12], 12'b0}, PCE, AuiPC);
mux2 #(32)     lauipcmux (AuiPC, {InstrE[31:12], 12'b0}, InstrE[5], lAuiPC);

branching_unit bu (InstrE[14:12], Zero, ALUResultE[31], TakeBranch);

// Pipeline Register 3 -> Execute | Memory
FF_ex_me reg3(clk,RegWriteE,ResultSrcE,MemWriteE,ALUResultE,WriteDataE,PCE,RdE,PCPlus4E,lAuiPC,funct3E,
            RegWriteM,ResultSrcM,MemWriteM,ALUResultM,WriteDataM,PCM,RdM,PCPlus4M,lAuiPCM,funct3M);

// Pipeline Register 4 -> Memory | Writeback

FF_me_wr reg4(clk,RegWriteM,ResultSrcM,ALUResultM,ReadDataM,PCM,RdM,PCPlus4M,lAuiPCM,WriteDataM,
            RegWriteW,ResultSrcW,ALUResultW,ReadDataW,PCW,RdW,PCPlus4W,lAuiPCW,WriteDataW);

// Result Source
mux4 #(32)     resultmux(ALUResultW, ReadDataW, PCPlus4W, lAuiPCW, ResultSrcW, ResultW);

// hazard unit

hazard h (InstrD[19:15],InstrD[24:20], Rs1E, Rs2E, RdE, RdM, RdW, PCSrc, ResultSrcE[0], RegWriteM, RegWriteW,
            StallF, stallD, FlushD, FlushE, ForwardAE, ForwardBE);

assign Mem_WrData = WriteDataM;
assign Mem_WrAddr = ALUResultM;


endmodule
