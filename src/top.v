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
    wire [63:0] pkt; wire pkt_done, tx_dv, tx_busy; wire [7:0] tx_byte;

    uart_rx #(.CLKS_PER_BIT(234)) u_rx (.clk(sys_clk), .rx_serial(uart_rx_i), .pkt(pkt), .pkt_done(pkt_done));
    trade_core u_core (.clk(sys_clk), .pkt(pkt), .pkt_done(pkt_done), .tx_dv(tx_dv), .tx_byte(tx_byte), .tx_busy(tx_busy));
    uart_tx #(.CLKS_PER_BIT(234), .GAP_BITS(4)) u_tx (.clk(sys_clk), .tx_dv(tx_dv), .tx_byte(tx_byte), .tx_busy(tx_busy), .tx_serial(uart_tx_o));
endmodule
