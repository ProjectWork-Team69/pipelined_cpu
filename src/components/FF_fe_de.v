module FF_fe_de  (
    input       clk, clr,en,
    input       [31:0] RD,PCF,PC_plus4F,
    output reg  [31:0] InstrD,PCD,PC_plus4D
);

initial begin
    InstrD    = 0;
    PCD       = 0;
    PC_plus4D = 0;
end
always @(posedge clk) begin
    if (!clr && !en) begin
        InstrD   <= RD;
        PCD      <= PCF;
        PC_plus4D<= PC_plus4F;
    end
    else if (clr) begin
        InstrD   <= 0;
        PCD      <= 0;
        PC_plus4D<= 0;
    end
    else begin
        InstrD   <= InstrD;
        PCD      <= PCD;
        PC_plus4D<= PC_plus4D;
    end
end


endmodule