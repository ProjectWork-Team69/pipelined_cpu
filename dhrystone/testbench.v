`timescale 1 ns / 1 ps

module testbench;
    parameter DATA_MEM_SIZE_BYTES = 256*1024;
    parameter MMIO_BASE_ADDR      = 32'h1000_0000; 
    parameter MMIO_SIZE_BYTES     = 1024;
    
    reg clk = 1;
    reg reset = 1;
    
    wire [31:0] PC, Instr, DataAdr, WriteData, ReadData, Result;
    wire MemWrite;
    wire [2:0]  funct3;
    wire [31:0] PCW, ALUResultW, WriteDataW;
    
    integer i;
    always #5 clk = ~clk;
    
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
    
    reg [7:0] instruction_memory [0:DATA_MEM_SIZE_BYTES-1];
    reg [7:0] data_memory [0:DATA_MEM_SIZE_BYTES-1];
    reg [7:0] mmio_memory [0:MMIO_SIZE_BYTES-1];

    initial begin
        for (i = 0; i < DATA_MEM_SIZE_BYTES; i = i + 1) begin
            instruction_memory[i] = 8'b0;
            data_memory[i] = 8'b0;
        end
        for (i = 0; i < MMIO_SIZE_BYTES; i = i + 1)
            mmio_memory[i] = 8'b0;

        $display("Loading dhry.hex into Instruction Memory...");
        $readmemh("dhry.hex", instruction_memory);  
        
        reset = 1'b1;
        #100;
        reset = 1'b0;
    end
    
    assign Instr = {instruction_memory[PC+3], instruction_memory[PC+2], instruction_memory[PC+1], instruction_memory[PC]};
    
    reg [31:0] read_data;
    wire is_mmio_addr = (DataAdr >= MMIO_BASE_ADDR) && (DataAdr < (MMIO_BASE_ADDR + MMIO_SIZE_BYTES));
    wire [9:0] mmio_offset = DataAdr[9:0];
    
    always @(posedge clk) begin
        if (is_mmio_addr) begin
            case(funct3)
                3'b000: read_data = {{24{mmio_memory[mmio_offset][7]}}, mmio_memory[mmio_offset]};
                3'b001: read_data = {{16{mmio_memory[mmio_offset+1][7]}}, mmio_memory[mmio_offset+1], mmio_memory[mmio_offset]};
                3'b010: read_data = {mmio_memory[mmio_offset+3], mmio_memory[mmio_offset+2], mmio_memory[mmio_offset+1], mmio_memory[mmio_offset]};
                3'b100: read_data = {24'b0, mmio_memory[mmio_offset]};
                3'b101: read_data = {16'b0, mmio_memory[mmio_offset+1], mmio_memory[mmio_offset]};
                default: read_data = 32'b0;
            endcase
        end else begin
            case(funct3)
                3'b000: read_data = {{24{data_memory[DataAdr][7]}}, data_memory[DataAdr]};
                3'b001: read_data = {{16{data_memory[DataAdr+1][7]}}, data_memory[DataAdr+1], data_memory[DataAdr]};
                3'b010: read_data = {data_memory[DataAdr+3], data_memory[DataAdr+2], data_memory[DataAdr+1], data_memory[DataAdr]};
                3'b100: read_data = {24'b0, data_memory[DataAdr]};
                3'b101: read_data = {16'b0, data_memory[DataAdr+1], data_memory[DataAdr]};
                default: read_data = 32'b0;
            endcase
        end
    end
    assign ReadData = read_data;
    
    always @(posedge clk) begin
        if (MemWrite && !reset) begin
            if (is_mmio_addr) begin
                if (DataAdr == MMIO_BASE_ADDR)
                    $write("%c", WriteData[7:0]); 
                case(funct3)
                    3'b000: mmio_memory[mmio_offset] <= WriteData[7:0];
                    3'b001: begin
                        mmio_memory[mmio_offset]   <= WriteData[7:0];
                        mmio_memory[mmio_offset+1] <= WriteData[15:8];
                    end
                    3'b010: begin
                        mmio_memory[mmio_offset]   <= WriteData[7:0];
                        mmio_memory[mmio_offset+1] <= WriteData[15:8];
                        mmio_memory[mmio_offset+2] <= WriteData[23:16];
                        mmio_memory[mmio_offset+3] <= WriteData[31:24];
                    end
                endcase
            end else begin
                case(funct3)
                    3'b000: data_memory[DataAdr] <= WriteData[7:0];
                    3'b001: begin
                        data_memory[DataAdr]   <= WriteData[7:0];
                        data_memory[DataAdr+1] <= WriteData[15:8];
                    end
                    3'b010: begin
                        data_memory[DataAdr]   <= WriteData[7:0];
                        data_memory[DataAdr+1] <= WriteData[15:8];
                        data_memory[DataAdr+2] <= WriteData[23:16];
                        data_memory[DataAdr+3] <= WriteData[31:24];
                    end
                endcase
            end
        end
    end
    
    integer cycle_count = 0;
    integer instr_count = 0;
    
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            if (PCW != 0) instr_count = instr_count + 1;
            if (instr_count % 1000000 == 0 && instr_count > 0)
                $display("\n[%0d M instructions] PC=0x%08x, Cycles=%0d", instr_count/1000000, PCW, cycle_count);
        end
    end
    
    reg [31:0] last_pc = 0;
    integer stuck_count = 0;
    
    always @(posedge clk) begin
        if (!reset) begin
            if (PCW == last_pc && PCW != 0) begin
                stuck_count = stuck_count + 1;
                if (stuck_count > 250000) begin
                    $display("\n========================================");
                    $display("CPU STUCK DETECTED (Likely program _exit loop)");
                    $display("STUCK at PC = 0x%08x", PCW);
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
    
    initial begin
        repeat (250000000) @(posedge clk); 
        $display("\n=========================================");
        $display("TIMEOUT REACHED (250M Cycles)");
        $display("Total Cycles: %0d", cycle_count);
        $display("Total Instructions: %0d", instr_count);
        if (instr_count > 0)
            $display("CPI: %.2f", cycle_count * 1.0 / instr_count);
        $display("=========================================");
        $finish;
    end
    
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end
endmodule
