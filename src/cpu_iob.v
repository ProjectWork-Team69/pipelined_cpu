module cpu_iob#(
    parameter FE_ADDR_W     = 32,
    parameter FE_DATA_W     = 32
)(
    input  clk,
    input  reset,

    // IOB Interface
    input         iob_ready_i,
    input  [FE_DATA_W-1:0] iob_rdata_i,
    output        iob_valid_o,
    output [FE_ADDR_W-1:0] iob_addr_o,
    output [FE_DATA_W-1:0] iob_wdata_o,
    output [FE_DATA_W/8-1:0] iob_wstrb_o,

    // CPU Interface
    input        MemWrite,
    input [31:0] WriteData,
    input [31:0] DataAdr,
    output reg [31:0] ReadData
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ  = 2'b10;

    reg [1:0] state, next_state;

    reg iob_valid;
    reg [FE_ADDR_W-1:0] iob_addr;
    reg [FE_DATA_W-1:0] iob_wdata;
    reg [FE_DATA_W/8-1:0] iob_wstrb;

    assign iob_valid_o = iob_valid;
    assign iob_addr_o  = iob_addr;
    assign iob_wdata_o = iob_wdata;
    assign iob_wstrb_o = iob_wstrb;

    wire is_write_request = MemWrite;
    wire is_read_request  = !MemWrite;
    wire new_mem_request  = (DataAdr != 32'b0 && (is_write_request || is_read_request));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            iob_valid <= 0;
            iob_addr  <= 0;
            iob_wdata <= 0;
            iob_wstrb <= 0;
            ReadData  <= 0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (new_mem_request) begin
                        iob_addr  <= DataAdr;
                        iob_wdata <= WriteData;
                        iob_valid <= 1'b1;
                        iob_wstrb <= is_write_request ? 4'b1111 : 4'b0000;
                    end else begin
                        iob_valid <= 1'b0;
                    end
                end

                WRITE: begin
                    if (iob_ready_i)
                        iob_valid <= 1'b0;
                end

                READ: begin
                    if (iob_ready_i) begin
                        iob_valid <= 1'b0;
                        ReadData  <= iob_rdata_i;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (new_mem_request && is_write_request) next_state = WRITE;
                   else if (new_mem_request && is_read_request) next_state = READ;
            WRITE: if (iob_ready_i) next_state = IDLE;
            READ:  if (iob_ready_i) next_state = IDLE;
        endcase
    end

endmodule
