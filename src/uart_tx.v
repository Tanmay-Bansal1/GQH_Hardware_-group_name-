// Transmitter with no data/shift register: tx_byte must stay stable while busy.
// Bit-time tick is the carry-out of the 8-bit counter (no compare logic); the counter
// reloads to 256-CLKS_PER_BIT. GAP_BITS (<=6) idle bit-times follow the stop bit.
module uart_tx #(
    parameter CLKS_PER_BIT = 234,
    parameter GAP_BITS     = 4
)(
    input  wire       clk,
    input  wire       start,      // pulse while !busy
    input  wire [7:0] tx_byte,    // held stable until busy falls
    output reg        busy = 1'b0,
    output reg        tx_serial = 1'b1
);
    localparam [7:0] RELOAD = 256 - CLKS_PER_BIT;
    reg [7:0] c = 8'd0;
    reg [3:0] n = 4'd0;
    wire [8:0] cn   = {1'b0, c} + 9'd1;
    wire       tick = cn[8];                     // c == 255
    always @(posedge clk) begin
        if (!busy) begin
            if (start) begin busy <= 1'b1; c <= RELOAD; n <= 4'd0; tx_serial <= 1'b0; end
        end else if (tick) begin
            c <= RELOAD;
            n <= n + 1'b1;
            tx_serial <= ~n[3] ? tx_byte[n[2:0]] : 1'b1;   // n=0..7 -> data bit n, else stop/idle
            if (n == 9 + GAP_BITS) busy <= 1'b0;
        end else c <= cn[7:0];
    end
endmodule
