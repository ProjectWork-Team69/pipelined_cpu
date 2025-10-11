`timescale 1 ns / 1 ps

module testbench;
    // Parameters for Memory Map
    parameter DATA_MEM_SIZE_BYTES = 256*1024; // 256KB
    // MMIO_BASE_ADDR MUST match UART_BASE in syscalls.c
    parameter MMIO_BASE_ADDR      = 32'h1000_0000; 
    parameter MMIO_SIZE_BYTES     = 1024;          // 1KB MMIO region
    
    // Clock and Reset
    reg clk = 1;
    reg reset = 1;
    
    // CPU signals (interface remains the same)
    wire [31:0] PC;
    wire [31:0] Instr;
    wire        MemWrite;
    wire [31:0] DataAdr, WriteData, ReadData;
    wire [31:0] Result;
    wire [2:0]  funct3;
    wire [31:0] PCW, ALUResultW, WriteDataW;
    
    // Local integers (moved to module scope to satisfy Verilog)
    integer i;

    // Clock generation
    always #5 clk = ~clk;
    
    // Instantiate CPU (Assuming riscv_cpu is defined in an imported file)
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
    
    // ===============================================
    // MEMORY DECLARATIONS (HARVARD ARCHITECTURE + MMIO)
    // ===============================================
    
    // Instruction Memory (Read-only, 256KB)
    reg [7:0] instruction_memory [0:DATA_MEM_SIZE_BYTES-1]; 

    // Data Memory (Read/Write, 256KB)
    reg [7:0] data_memory [0:DATA_MEM_SIZE_BYTES-1];
    
    // Memory Mapped I/O (Read/Write, 1KB)
    reg [7:0] mmio_memory [0:MMIO_SIZE_BYTES-1];

    // ===============================================
    // INITIALIZATION & PROGRAM LOAD
    // ===============================================
    initial begin
        // Initialize all memories to zero
        for (i = 0; i < DATA_MEM_SIZE_BYTES; i = i + 1) begin
            instruction_memory[i] = 8'b0;
            data_memory[i] = 8'b0;
        end
        for (i = 0; i < MMIO_SIZE_BYTES; i = i + 1) begin
            mmio_memory[i] = 8'b0;
        end

        // FIX: Ensure correct file is loaded (Makefile generates dhry.hex)
        $display("Loading dhry.hex into Instruction Memory...");
        $readmemh("dhry.hex", instruction_memory);  
        
        // Reset sequence
        reset = 1'b1;
        #100; // Reset for 100ns
        reset = 1'b0;
    end
    
    // ===============================================
    // INSTRUCTION FETCH (from Instruction Memory)
    // ===============================================
    
    // Instruction fetch (word-aligned, byte-addressed)
    assign Instr = {instruction_memory[PC+3], instruction_memory[PC+2], instruction_memory[PC+1], instruction_memory[PC]};
    
    // ===============================================
    // DATA MEMORY READ (from Data Memory or MMIO)
    // ===============================================
    
    reg [31:0] read_data;
    
    // Logic for determining if the address is within the MMIO range
    wire is_mmio_addr = (DataAdr >= MMIO_BASE_ADDR) && (DataAdr < (MMIO_BASE_ADDR + MMIO_SIZE_BYTES));
    wire [9:0] mmio_offset = DataAdr[9:0]; // 1KB access requires 10 bits of offset
    
    // Data Read logic: routes the read based on is_mmio_addr
    always @(posedge clk) begin
        if (is_mmio_addr) begin
            // MMIO Access
            case(funct3)
                // Assuming MMIO access is generally byte-wide (UART)
                3'b000: read_data = {{24{mmio_memory[mmio_offset][7]}}, mmio_memory[mmio_offset]}; // LB
                3'b001: read_data = {{16{mmio_memory[mmio_offset+1][7]}}, mmio_memory[mmio_offset+1], mmio_memory[mmio_offset]}; // LH
                3'b010: read_data = {mmio_memory[mmio_offset+3], mmio_memory[mmio_offset+2], mmio_memory[mmio_offset+1], mmio_memory[mmio_offset]}; // LW
                3'b100: read_data = {24'b0, mmio_memory[mmio_offset]}; // LBU
                3'b101: read_data = {16'b0, mmio_memory[mmio_offset+1], mmio_memory[mmio_offset]}; // LHU
                default: read_data = 32'b0;
            endcase
        end else begin
            // Standard Data Memory Access (low memory)
            case(funct3)
                3'b000: read_data = {{24{data_memory[DataAdr][7]}}, data_memory[DataAdr]}; // LB
                3'b001: read_data = {{16{data_memory[DataAdr+1][7]}}, data_memory[DataAdr+1], data_memory[DataAdr]}; // LH
                3'b010: read_data = {data_memory[DataAdr+3], data_memory[DataAdr+2], data_memory[DataAdr+1], data_memory[DataAdr]}; // LW
                3'b100: read_data = {24'b0, data_memory[DataAdr]}; // LBU
                3'b101: read_data = {16'b0, data_memory[DataAdr+1], data_memory[DataAdr]}; // LHU
                default: read_data = 32'b0;
            endcase
        end
    end
    
    assign ReadData = read_data;
    
    // ===============================================
    // DATA MEMORY WRITE (to Data Memory or MMIO)
    // ===============================================
    
    always @(posedge clk) begin
        if (MemWrite && !reset) begin
            if (is_mmio_addr) begin
                // MMIO Write Access
                // If the write is a byte write (SB, funct3=000) to the UART base address, print the character.
                if (DataAdr == MMIO_BASE_ADDR ) begin
                    // FIX: Output the character to the terminal
                    $write("%c", WriteData[7:0]); 
                end
                
                case(funct3)
                    3'b000: mmio_memory[mmio_offset] <= WriteData[7:0]; // SB (Byte for UART)
                    3'b001: begin // SH
                        mmio_memory[mmio_offset]   <= WriteData[7:0];
                        mmio_memory[mmio_offset+1] <= WriteData[15:8];
                    end
                    3'b010: begin // SW
                        mmio_memory[mmio_offset]   <= WriteData[7:0];
                        mmio_memory[mmio_offset+1] <= WriteData[15:8];
                        mmio_memory[mmio_offset+2] <= WriteData[23:16];
                        mmio_memory[mmio_offset+3] <= WriteData[31:24];
                    end
                endcase
            end else begin
                // Standard Data Memory Write Access (low memory)
                case(funct3)
                    3'b000: data_memory[DataAdr] <= WriteData[7:0]; // SB
                    3'b001: begin // SH
                        data_memory[DataAdr]   <= WriteData[7:0];
                        data_memory[DataAdr+1] <= WriteData[15:8];
                    end
                    3'b010: begin // SW
                        data_memory[DataAdr]   <= WriteData[7:0];
                        data_memory[DataAdr+1] <= WriteData[15:8];
                        data_memory[DataAdr+2] <= WriteData[23:16];
                        data_memory[DataAdr+3] <= WriteData[31:24];
                    end
                endcase
            end
        end
    end
    
    // ===============================================
    // PERFORMANCE MONITORING & DEBUG
    // ===============================================
    
    integer cycle_count = 0;
    integer instr_count = 0;
    
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            if (PCW != 0) 
                instr_count = instr_count + 1;
                
            
            if (instr_count % 1000000 == 0 && instr_count > 0) begin
    
                $display("\n[%0d M instructions] PC=0x%08x, Cycles=%0d", 
                         instr_count/1000000, PCW, cycle_count);
            end
        end
    end
    
    
    reg [31:0] last_pc = 0;
    integer stuck_count = 0;
    
    always @(posedge clk) begin
        if (!reset) begin
            if (PCW == last_pc && PCW != 0) begin
                stuck_count = stuck_count + 1;
                if (stuck_count > 250000) begin // Increased stuck limit substantially
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
    
    // Waveform dump
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end
    

endmodule
