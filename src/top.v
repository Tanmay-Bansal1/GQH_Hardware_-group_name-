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

    wire       rx_dv;
    wire [7:0] rx_byte;
    
    wire       tx_dv;
    wire [7:0] tx_byte;
    wire       tx_ready;
    
    wire        session_reset;
    wire        process_enable;
    wire [15:0] price_A;
    wire [15:0] price_B;
    wire [7:0]  action_A;
    wire [7:0]  action_B;

    uart_rx #(
        .CLKS_PER_BIT(234)
    ) u_uart_rx (
        .clk(sys_clk),
        .rx_serial(uart_rx_i),
        .rx_dv(rx_dv),
        .rx_byte(rx_byte)
    );

    trade_core u_trade_core (
        .clk(sys_clk),
        .rx_dv(rx_dv),
        .rx_byte(rx_byte),
        .tx_dv(tx_dv),
        .tx_byte(tx_byte),
        .tx_ready(tx_ready),
        .session_reset(session_reset),
        .process_enable(process_enable),
        .price_A(price_A),
        .price_B(price_B),
        .action_A(action_A),
        .action_B(action_B)
    );

    moving_average u_ma_engine_A (
        .clk(sys_clk),
        .reset(session_reset),
        .enable(process_enable),
        .price_in(price_A),
        .action_out(action_A)
    );

    moving_average u_ma_engine_B (
        .clk(sys_clk),
        .reset(session_reset),
        .enable(process_enable),
        .price_in(price_B),
        .action_out(action_B)
    );

    uart_tx #(
        .CLKS_PER_BIT(234)
    ) u_uart_tx (
        .clk(sys_clk),
        .tx_dv(tx_dv),
        .tx_byte(tx_byte),
        .tx_ready(tx_ready),
        .tx_serial(uart_tx_o)
    );

endmodule