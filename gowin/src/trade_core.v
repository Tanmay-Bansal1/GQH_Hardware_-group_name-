module trade_core (
    input  wire        clk,
    input  wire [15:0] idx,
    input  wire [15:0] rA,
    input  wire [15:0] rB,
    input  wire        s1A,
    input  wire        nz,
    input  wire        pkt_done,
    output wire        nz_clr,
    output wire        tx_start,
    output reg  [7:0]  tx_byte,
    input  wire        tx_busy
);
    localparam S_IDLE = 3'd0, S_CLR = 3'd1, S_UPD = 3'd2, S_GO = 3'd3, S_WAIT = 3'd4;
    reg [2:0] st = S_IDLE;
    reg [2:0] bc = 3'd0;
    reg [3:0] ptr = 4'd0;
    reg       full = 1'b0;

    wire clr = (st == S_CLR) & ~nz;       // index 0 -> new session
    wire upd = (st == S_UPD);
    wire [15:0] pA = {rA[7:0], rA[15:8]};
    wire [15:0] pB = {rB[7:0], rB[15:8]};
    wire [1:0]  actA, actB;

    moving_average eA (.clk(clk), .clr(clr), .upd(upd), .price(pA), .ptr(ptr), .full(full), .act(actA));
    moving_average eB (.clk(clk), .clr(clr), .upd(upd), .price(pB), .ptr(ptr), .full(full), .act(actB));

    always @(posedge clk) begin
        case (st)
            S_IDLE: if (pkt_done) st <= S_CLR;
            S_CLR:  st <= S_UPD;
            S_UPD:  st <= S_GO;
            S_GO:   st <= S_WAIT;                       // start pulse; busy rises next cycle
            S_WAIT: if (!tx_busy) begin bc <= bc + 1'b1; st <= (bc == 3'd7) ? S_IDLE : S_GO; end
            default: st <= S_IDLE;
        endcase
        if (clr) begin ptr <= 4'd0; full <= 1'b0; end
        else if (upd) begin ptr <= ptr + 1'b1; if (ptr == 4'd15) full <= 1'b1; end
    end

    assign nz_clr   = (st == S_UPD);
    assign tx_start = (st == S_GO);

    always @(*) begin
        case (bc)
            3'd0: tx_byte = idx[7:0];
            3'd1: tx_byte = idx[15:8];
            3'd2: tx_byte = {2'b00, ~s1A, s1A, 2'b00, ~s1A, s1A};   // item1 echo (0x11 / 0x22)
            3'd3: tx_byte = {6'd0, s1A ? actA : actB};
            3'd4: tx_byte = {2'b00, s1A, ~s1A, 2'b00, s1A, ~s1A};   // item2 echo
            3'd5: tx_byte = {6'd0, s1A ? actB : actA};
            default: tx_byte = 8'd0;
        endcase
    end
endmodule
