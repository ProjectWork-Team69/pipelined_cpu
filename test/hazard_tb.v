`timescale 1ns/1ps

module difficult_test_tb;

    // Inputs to DUT
    reg clk;
    reg reset;

    // Unused external memory write signals for this test
    reg Ext_MemWrite = 0;
    reg [31:0] Ext_WriteData = 0, Ext_DataAdr = 0;

    // Wires from DUT
    wire MemWrite;
    wire [31:0] WriteData, DataAdr, ReadData;
    wire [31:0] PCW, Result, ALUResultW, WriteDataW;

    // Instantiate your top-level module
    pl_riscv_cpu uut (
        .clk(clk),
        .reset(reset),
        .Ext_MemWrite(Ext_MemWrite),
        .Ext_WriteData(Ext_WriteData),
        .Ext_DataAdr(Ext_DataAdr),
        .MemWrite(MemWrite),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .ReadData(ReadData),
        .PCW(PCW),
        .Result(Result),
        .ALUResultW(ALUResultW),
        .WriteDataW(WriteDataW)
    );

    // Clock generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test execution and final state verification
    initial begin

        // 2. Apply reset
        reset = 1;
        #20;
        reset = 0;

        // 3. Let the simulation run long enough for the program to finish
        #500;

        // 4. Verification: Check the final state of all registers
        $display("--- FINAL REGISTER STATE VERIFICATION (Difficult Test) ---");
        check_register(1, 32'd100);
        check_register(2, 32'd200);
        check_register(3, 32'd100);
        check_register(4, 32'd8);
        check_register(5, 32'd20);    // Return address from JALR
        check_register(6, 32'dx);     // Flushed by JALR
        check_register(7, 32'd4096);  // From LUI
        check_register(8, 32'd100);   // Loaded from memory
        check_register(9, 32'd99);
        check_register(10, 32'dx);    // Flushed by BNE
        check_register(11, 32'd20);   // Result of final ADD using JALR's return address

        // 5. Verification: Check the final state of memory
        $display("--- FINAL MEMORY STATE VERIFICATION ---");
        // The SW instruction stored the value of x3 (100) at address x7 (4096).
        // The word address is 4096 / 4 = 1024.
        if (uut.datamem.data_ram[1024] === 32'd100) begin
            $display("OK: Memory[4096] = 100");
        end else begin
            $display("FAIL: Memory[4096] = %d (Expected: 100)", uut.datamem.data_ram[1024]);
        end

        $display("--- VERIFICATION COMPLETE ---");
        $finish;
    end

task check_register (input [4:0] addr, input [31:0] expected_val);
begin : check_block // Block is now named
    reg [31:0] actual_val;
    // This hierarchical path must exactly match your design structure
    actual_val = uut.rvcpu.dp.rf.reg_file_arr[addr];
    if (actual_val === expected_val) begin
        $display("OK: x%0d = %h (hex)", addr, actual_val);
    end else begin
        $display("FAIL: x%0d = %h (hex) -- Expected: %h (hex)", addr, actual_val, expected_val);
    end
end
endtask

endmodule