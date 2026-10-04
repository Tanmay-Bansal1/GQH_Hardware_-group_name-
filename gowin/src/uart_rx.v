// Receiver that steers data bits straight into their final registers:
//   idx (16b), pA/pB (16b each, routed by item1), s1A (item1 is A?), nz (index != 0)
// -> no packet buffer, no price-routing muxes, no 16-bit zero compare.
// Raw layout: 16-bit fields arrive hi-byte first, each byte LSB first, shifted in at the top,
// so value = {raw[7:0], raw[15:8]}.
module uart_rx #(parameter CLKS_PER_BIT = 234)(
    input  wire        clk,
    input  wire        rx_serial,
    input  wire        nz_clr,
    output reg  [15:0] idx = 16'd0,
    output reg  [15:0] rA  = 16'd0,
    output reg  [15:0] rB  = 16'd0,
    output reg         s1A = 1'b0,
    output reg         nz  = 1'b0,
    output reg         pkt_done = 1'b0
);
    reg s0 = 1'b1, s1 = 1'b1;
    reg [1:0] st = 2'd0;                 // 0 idle, 1 start, 2 data, 3 stop
    reg [7:0] c  = 8'd0;
    reg [5:0] nb = 6'd0;                 // data bits received; wraps to 0 after 64
    localparam [7:0] RELOAD = 256 - CLKS_PER_BIT;
    wire [8:0] cn = {1'b0, c} + 9'd1;
    // bit-time tick = counter carry-out; in the start state sample at c[7] (~0.46 bit) instead
    wire tick  = (st == 2'd1) ? c[7] : cn[8];
    wire dtick = tick & (st == 2'd2);
    wire [2:0] byt = nb[5:3];
    wire b34 = (byt == 3'd3) | (byt == 3'd4);   // price1 bytes
    wire b67 = (byt[2:1] == 2'b11);             // price2 bytes
    wire shA = dtick & ((b34 & s1A) | (b67 & ~s1A));
    wire shB = dtick & ((b34 & ~s1A) | (b67 & s1A));

    always @(posedge clk) begin
        s0 <= rx_serial; s1 <= s0;
        pkt_done <= 1'b0;
        if (nz_clr) nz <= 1'b0;
        if (dtick & (byt[2:1] == 2'b00)) begin
            idx <= {s1, idx[15:1]};
            if (s1) nz <= 1'b1;
        end
        if (dtick & (nb == 6'd16)) s1A <= s1;          // item1 bit0: 0x11 -> 1, 0x22 -> 0
        if (shA) rA <= {s1, rA[15:1]};
        if (shB) rB <= {s1, rB[15:1]};

        if (st == 2'd0) begin
            if (!s1) begin st <= 2'd1; c <= RELOAD; end
        end else if (tick) begin
            c <= RELOAD;
            case (st)
                2'd1: st <= s1 ? 2'd0 : 2'd2;
                2'd2: begin
                    nb <= nb + 1'b1;
                    if (nb[2:0] == 3'd7) st <= 2'd3;
                end
                default: begin st <= 2'd0; pkt_done <= (byt == 3'd0); end   // nb[2:0] is 0 here by construction
            endcase
        end else c <= cn[7:0];
    end
endmodule
