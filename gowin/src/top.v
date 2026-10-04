module top (
    input  wire sys_clk,
    input  wire reset_btn,
    input  wire uart_rx_i,
    output wire uart_tx_o,
    output wire led0_n,
    output wire led1_n
);
    assign led0_n = 1'b1;
    assign led1_n = 1'b1;
    wire [15:0] idx, rA, rB; wire s1A, nz, pkt_done, nz_clr, tx_start, tx_busy; wire [7:0] tx_byte;

    uart_rx #(.CLKS_PER_BIT(234)) u_rx (.clk(sys_clk), .rx_serial(uart_rx_i), .nz_clr(nz_clr),
        .idx(idx), .rA(rA), .rB(rB), .s1A(s1A), .nz(nz), .pkt_done(pkt_done));
    trade_core u_core (.clk(sys_clk), .idx(idx), .rA(rA), .rB(rB), .s1A(s1A), .nz(nz), .pkt_done(pkt_done),
        .nz_clr(nz_clr), .tx_start(tx_start), .tx_byte(tx_byte), .tx_busy(tx_busy));
    uart_tx #(.CLKS_PER_BIT(234), .GAP_BITS(4)) u_tx (.clk(sys_clk), .start(tx_start), .tx_byte(tx_byte),
        .busy(tx_busy), .tx_serial(uart_tx_o));
endmodule
