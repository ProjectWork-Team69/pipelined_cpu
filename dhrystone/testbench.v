`timescale 1 ns / 1 ps

module testbench_unified;
    reg clk = 1;
    reg reset = 1;
    
    // CPU signals
    wire [31:0] PC;
    wire [31:0] Instr;
    wire        MemWrite;
    wire [31:0] DataAdr, WriteData, ReadData;
    wire [31:0] Result;
    wire [2:0]  funct3;
    wire [31:0] PCW, ALUResultW, WriteDataW;
    
    always #5 clk = ~clk;
    
    initial begin
        reset = 1;
        #100;
        reset = 0;
    end
    
    // Instantiate CPU
    riscv_cpu cpu (
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Instr(Instr),
        .MemWriteW(MemWrite),
        .Mem_WrAddr(DataAdr),
        .Mem_WrData(WriteData),
        .ReadData(ReadData),
        .Result(Result),
        .funct3(funct3),
        .PCW(PCW),
        .ALUResultW(ALUResultW),
        .WriteDataW(WriteDataW)
    );
    
    // Unified memory (256KB)
    reg [7:0] memory [0:256*1024-1];
    
    // Load program
    initial begin
        $readmemh("dhry.hex", memory);
    end
    
    // Instruction fetch (word-aligned, byte-addressed)
    assign Instr = {memory[PC+3], memory[PC+2], memory[PC+1], memory[PC]};
    
    // Data memory read (combinational)
    reg [31:0] read_data;
    
    always @(*) begin
        case(funct3)
            3'b000: begin // LB (Load Byte)
                case(DataAdr[1:0])
                    2'b00: read_data = {{24{memory[DataAdr][7]}}, memory[DataAdr]};
                    2'b01: read_data = {{24{memory[DataAdr][7]}}, memory[DataAdr]};
                    2'b10: read_data = {{24{memory[DataAdr][7]}}, memory[DataAdr]};
                    2'b11: read_data = {{24{memory[DataAdr][7]}}, memory[DataAdr]};
                endcase
            end
            
            3'b001: begin // LH (Load Halfword)
                case(DataAdr[1])
                    1'b0: read_data = {{16{memory[DataAdr+1][7]}}, memory[DataAdr+1], memory[DataAdr]};
                    1'b1: read_data = {{16{memory[DataAdr+1][7]}}, memory[DataAdr+1], memory[DataAdr]};
                endcase
            end
            
            3'b010: begin // LW (Load Word)
                read_data = {memory[DataAdr+3], memory[DataAdr+2], memory[DataAdr+1], memory[DataAdr]};
            end
            
            3'b100: begin // LBU (Load Byte Unsigned)
                case(DataAdr[1:0])
                    2'b00: read_data = {24'b0, memory[DataAdr]};
                    2'b01: read_data = {24'b0, memory[DataAdr]};
                    2'b10: read_data = {24'b0, memory[DataAdr]};
                    2'b11: read_data = {24'b0, memory[DataAdr]};
                endcase
            end
            
            3'b101: begin // LHU (Load Halfword Unsigned)
                case(DataAdr[1])
                    1'b0: read_data = {16'b0, memory[DataAdr+1], memory[DataAdr]};
                    1'b1: read_data = {16'b0, memory[DataAdr+1], memory[DataAdr]};
                endcase
            end
            
            default: read_data = 32'b0;
        endcase
    end
    
    assign ReadData = read_data;
    
    // Data memory write (synchronous)
    always @(posedge clk) begin
        if (MemWrite && !reset) begin
            case(funct3)
                3'b000: begin // SB (Store Byte)
                    case(DataAdr[1:0])
                        2'b00: memory[DataAdr] <= WriteData[7:0];
                        2'b01: memory[DataAdr] <= WriteData[7:0];
                        2'b10: memory[DataAdr] <= WriteData[7:0];
                        2'b11: memory[DataAdr] <= WriteData[7:0];
                    endcase
                end
                
                3'b001: begin // SH (Store Halfword)
                    case(DataAdr[1])
                        1'b0: begin
                            memory[DataAdr]   <= WriteData[7:0];
                            memory[DataAdr+1] <= WriteData[15:8];
                        end
                        1'b1: begin
                            memory[DataAdr]   <= WriteData[7:0];
                            memory[DataAdr+1] <= WriteData[15:8];
                        end
                    endcase
                end
                
                3'b010: begin // SW (Store Word)
                    memory[DataAdr]   <= WriteData[7:0];
                    memory[DataAdr+1] <= WriteData[15:8];
                    memory[DataAdr+2] <= WriteData[23:16];
                    memory[DataAdr+3] <= WriteData[31:24];
                end
            endcase
        end
    end
    
    // Performance monitoring
    integer cycle_count = 0;
    integer instr_count = 0;
    
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            if (PCW != 0) 
                instr_count = instr_count + 1;
                
            // Progress updates every 1M cycles
            if (cycle_count % 1000000 == 0) begin
                $display("[%0d M cycles] PC=0x%08x, Instructions=%0d", 
                         cycle_count/1000000, PCW, instr_count);
            end
        end
    end
    
    // Detect stuck CPU
    reg [31:0] last_pc = 0;
    integer stuck_count = 0;
    
    always @(posedge clk) begin
        if (!reset) begin
            if (PCW == last_pc && PCW != 0) begin
                stuck_count = stuck_count + 1;
                if (stuck_count > 10000) begin
                    $display("\n========================================");
                    $display("CPU STUCK at PC = 0x%08x", PCW);
                    $display("Total Cycles: %0d", cycle_count);
                    $display("Total Instructions: %0d", instr_count);
                    if (instr_count > 0)
                        $display("CPI: %.2f", cycle_count * 1.0 / instr_count);
                    $display("========================================");
                    $finish;
                end
            end else begin
                stuck_count = 0;
                last_pc = PCW;
            end
        end
    end
    
    // Timeout
    initial begin
        repeat (50000000) @(posedge clk);
        $display("\n========================================");
        $display("TIMEOUT REACHED");
        $display("Total Cycles: %0d", cycle_count);
        $display("Total Instructions: %0d", instr_count);
        if (instr_count > 0)
            $display("CPI: %.2f", cycle_count * 1.0 / instr_count);
        $display("========================================");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench_unified);
    end
    
    // Monitor writes for debugging
    always @(posedge clk) begin
        if (MemWrite && !reset) begin
            $display("[WRITE] Addr=0x%08x, Data=0x%08x, funct3=%0d", 
                     DataAdr, WriteData, funct3);
        end
    end

endmodule