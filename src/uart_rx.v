
module uart_rx #(parameter CLKS_PER_BIT = 234)(
    input  wire        clk,
    input  wire        rx_serial,
    output reg  [63:0] pkt = 64'd0,
    output reg         pkt_done = 1'b0   // 1-clk pulse, mid stop-bit of 8th byte
);
    localparam HALF = (CLKS_PER_BIT - 1) / 2;
    reg s0 = 1'b1, s1 = 1'b1;
    reg [1:0] st = 2'd0;                 // 0 idle, 1 start, 2 data, 3 stop
    reg [7:0] c  = 8'd0;
    reg [5:0] nb = 6'd0;                 // data bits received; wraps to 0 after 64
    wire tick = (c == CLKS_PER_BIT - 1);

    always @(posedge clk) begin
        s0 <= rx_serial; s1 <= s0;
        pkt_done <= 1'b0;
        if (st == 2'd0) begin
            if (!s1) begin st <= 2'd1; c <= CLKS_PER_BIT - 1 - HALF; end
        end else if (tick) begin
            c <= 8'd0;
            case (st)
                2'd1: st <= s1 ? 2'd0 : 2'd2;           // still low at mid-start?
                2'd2: begin
                    pkt <= {s1, pkt[63:1]};
                    nb  <= nb + 1'b1;
                    if (nb[2:0] == 3'd7) st <= 2'd3;
                end
                default: begin st <= 2'd0; pkt_done <= (nb == 6'd0); end
            endcase
        end else c <= c + 1'b1;
    end
endmodule
