`timescale 1ns/1ps

module tb_cpu_iob;

    // Parameters
    parameter FE_ADDR_W = 32;
    parameter FE_DATA_W = 32;
    parameter CLK_PERIOD = 10;

    // Testbench signals
    reg clk;
    reg reset;
    reg iob_ready_i;
    reg [FE_DATA_W-1:0] iob_rdata_i;
    wire iob_valid_o;
    wire [FE_ADDR_W-1:0] iob_addr_o;
    wire [FE_DATA_W-1:0] iob_wdata_o;
    wire [FE_DATA_W/8-1:0] iob_wstrb_o;
    reg MemWrite;
    reg [31:0] WriteData;
    reg [31:0] DataAdr;
    wire [31:0] ReadData;

    // Instantiate DUT
    cpu_iob #(
        .FE_ADDR_W(FE_ADDR_W),
        .FE_DATA_W(FE_DATA_W)
    ) dut (
        .clk(clk),
        .reset(reset),
        .iob_ready_i(iob_ready_i),
        .iob_rdata_i(iob_rdata_i),
        .iob_valid_o(iob_valid_o),
        .iob_addr_o(iob_addr_o),
        .iob_wdata_o(iob_wdata_o),
        .iob_wstrb_o(iob_wstrb_o),
        .MemWrite(MemWrite),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .ReadData(ReadData)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        iob_ready_i = 0;
        iob_rdata_i = 0;
        MemWrite = 0;
        WriteData = 0;
        DataAdr = 0;

        // Reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD);

        // Test 1: Write operation
        $display("Test 1: Write operation");
        DataAdr = 32'h1000;
        WriteData = 32'hDEADBEEF;
        MemWrite = 1;
        #(CLK_PERIOD);
        iob_ready_i = 1;
        #(CLK_PERIOD);
        iob_ready_i = 0;
        MemWrite = 0;
        DataAdr = 0;
        #(CLK_PERIOD*2);

        // Test 2: Read operation
        $display("Test 2: Read operation");
        DataAdr = 32'h2000;
        MemWrite = 0;
        iob_rdata_i = 32'hCAFEBABE;
        #(CLK_PERIOD);
        iob_ready_i = 1;
        #(CLK_PERIOD);
        iob_ready_i = 0;
        DataAdr = 0;
        #(CLK_PERIOD*2);

        // Test 3: Back-to-back operations
        $display("Test 3: Back-to-back write then read");
        DataAdr = 32'h3000;
        WriteData = 32'h12345678;
        MemWrite = 1;
        #(CLK_PERIOD);
        iob_ready_i = 1;
        #(CLK_PERIOD);
        iob_ready_i = 0;
        
        DataAdr = 32'h4000;
        MemWrite = 0;
        iob_rdata_i = 32'h87654321;
        #(CLK_PERIOD);
        iob_ready_i = 1;
        #(CLK_PERIOD);
        iob_ready_i = 0;
        DataAdr = 0;
        #(CLK_PERIOD*2);

        $display("All tests completed");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | State=%b | Valid=%b | Addr=%h | WData=%h | Wstrb=%b | RData=%h | Ready=%b", 
                 $time, dut.state, iob_valid_o, iob_addr_o, iob_wdata_o, iob_wstrb_o, ReadData, iob_ready_i);
    end

    // Optional: VCD dump for waveform viewing
    initial begin
        $dumpfile("dump.vcd");
       // $dumpvars(0, frontend_top_tb);
    end

endmodule