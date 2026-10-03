module top #(
    // generic list: constants that configure the block but are not physical pins.
    parameter CLK_FREQ = 27_000_000 // constants are UPPERCASE
)(
    // list of ports: the actual signals entering and leaving the block
    input wire sys_clk,       // single bit input
    input wire reset_btn,
    output wire [5:0] led0_n // 6-bit output (5 down to 0)
);

    // DECLARATIVE PART: internal signals, constants
    localparam HALF_SEC = 13_500_000;
    
    // cnt must be wide enough to hold HALF_SEC - 1. 
    // 13,500,000 requires 24 bits (2^24 = 16,777,216)
    reg [23:0] cnt = 24'd0; 
    
    wire [5:0] pattern = 6'b000001;

    // STATEMENT PART: everything here runs in parallel

    // a) Sequential logic (always block with clock)
    always @(posedge sys_clk) begin
        // rising edge: clk goes from 0 to 1
        // clocked logic goes here
    end

    // b) Concurrent assignment (pure wiring / combinational)
    // a permanent wire which is always active. Bitwise NOT is used for inversion.
    assign led0_n = ~pattern;

endmodule