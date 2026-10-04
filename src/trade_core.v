module trade_core (
    input  wire        clk,
    input  wire [63:0] pkt,
    input  wire        pkt_done,
    output wire        tx_dv,
    output reg  [7:0]  tx_byte,
    input  wire        tx_busy
);
    localparam S_IDLE = 2'd0, S_CLR = 2'd1, S_UPD = 2'd2, S_TX = 2'd3;
    reg [1:0] st = S_IDLE;
    reg [2:0] bc = 3'd0;
    reg [3:0] ptr = 4'd0;
    reg       full = 1'b0;

    wire        idx0 = (pkt[15:0] == 16'd0);
    wire        s1A  = pkt[16];                    // item1 = 0x11 (A) vs 0x22 (B): bit0 differs
    wire [15:0] p1   = {pkt[31:24], pkt[39:32]};
    wire [15:0] p2   = {pkt[55:48], pkt[63:56]};
    wire [15:0] pA   = s1A ? p1 : p2;
    wire [15:0] pB   = s1A ? p2 : p1;
    wire        clr  = (st == S_CLR) & idx0;
    wire        upd  = (st == S_UPD);
    wire [1:0]  actA, actB;

    moving_average eA (.clk(clk), .clr(clr), .upd(upd), .price(pA), .ptr(ptr), .full(full), .act(actA));
    moving_average eB (.clk(clk), .clr(clr), .upd(upd), .price(pB), .ptr(ptr), .full(full), .act(actB));

    always @(posedge clk) begin
        case (st)
            S_IDLE: if (pkt_done) st <= S_CLR;
            S_CLR:  st <= S_UPD;                       // clear cycle, then load idx-0 prices
            S_UPD:  st <= S_TX;                        // engines update on this edge
            S_TX:   if (!tx_busy) begin bc <= bc + 1'b1; if (bc == 3'd7) st <= S_IDLE; end
        endcase
        if (clr) begin ptr <= 4'd0; full <= 1'b0; end
        else if (upd) begin ptr <= ptr + 1'b1; if (ptr == 4'd15) full <= 1'b1; end
    end

    assign tx_dv = (st == S_TX) & ~tx_busy;

    always @(*) begin
        case (bc)
            3'd0: tx_byte = pkt[7:0];                  // index hi
            3'd1: tx_byte = pkt[15:8];                 // index lo
            3'd2: tx_byte = pkt[23:16];                // item1 echo
            3'd3: tx_byte = {6'd0, s1A ? actA : actB}; // action1
            3'd4: tx_byte = pkt[47:40];                // item2 echo
            3'd5: tx_byte = {6'd0, s1A ? actB : actA}; // action2
            default: tx_byte = 8'd0;                   // reserved
        endcase
    end
endmodule
