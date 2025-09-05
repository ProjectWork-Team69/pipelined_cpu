
// branching_unit.v - logic for branching in execute stage

module branching_unit (
    input [2:0] funct3,
    input       Zero, ALUR31,
    input       SrcA_sign, SrcB_sign,
    output reg  Branch
);

initial begin
    Branch = 1'b0;
end

always @(*) begin
    case (funct3)
        3'b000: Branch =    Zero;      // beq (Correct)
        3'b001: Branch =   !Zero;      // bne (Correct)
        3'b101: Branch = !ALUR31;      // bge (Correct)
        3'b100: Branch =  ALUR31;      // blt (Correct)
        3'b110: Branch = (SrcA_sign == SrcB_sign) ? ALUR31 : SrcA_sign; // bltu
        3'b111: Branch = (SrcA_sign == SrcB_sign) ? !ALUR31 : !SrcA_sign; // bgeu
        
        default: Branch = 1'b0;
    endcase
end

endmodule