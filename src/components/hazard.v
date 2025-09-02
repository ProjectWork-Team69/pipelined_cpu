module hazard(
    input  [4:0] rs1D, rs2D,
    input  [4:0] rs1E, rs2E,
    input  [4:0] rdE, rdM, rdW,
    input        PCSrcE, ResultSrcE,
    input        RegWriteM, RegWriteW,

    output       StallF, StallD, FlushD, FlushE,
    output reg [1:0] ForwardAE, ForwardBE
);

    // --------------------
    // Load-Use Hazard (lwStall)
    // --------------------
    wire lwStall;
    assign lwStall = ResultSrcE & ((rs1D == rdE) | (rs2D == rdE));

    // --------------------
    // Stalling
    // --------------------
    assign StallF = lwStall;
    assign StallD = lwStall;

    // --------------------
    // Flushing
    // --------------------
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;

    // --------------------
    // Forwarding
    // --------------------
    always @(*) begin
        // Forward for rs1
        if((rs1E == rdM) && (rs1E != 0) && RegWriteM)
            ForwardAE = 2'b10;   // from MEM
        else if((rs1E == rdW) && (rs1E != 0) && RegWriteW)
            ForwardAE = 2'b01;   // from WB
        else
            ForwardAE = 2'b00;   // from reg file

        // Forward for rs2
        if((rs2E == rdM) && (rs2E != 0) && RegWriteM)
            ForwardBE = 2'b10;
        else if((rs2E == rdW) && (rs2E != 0) && RegWriteW)
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;
    end

endmodule
