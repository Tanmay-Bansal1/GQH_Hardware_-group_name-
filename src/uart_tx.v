
module uart_tx #(
    parameter CLKS_PER_BIT = 234,
    parameter GAP_BITS     = 4
)(
    input  wire       clk,
    input  wire       tx_dv,      // launch pulse (only honoured while !tx_busy)
    input  wire [7:0] tx_byte,
    output reg        tx_busy = 1'b0,
    output wire       tx_serial
);
    reg [9:0] sh = 10'h3FF;
    reg [7:0] c  = 8'd0;
    reg [4:0] n  = 5'd0;
    assign tx_serial = sh[0];

    always @(posedge clk) begin
        if (!tx_busy) begin
            if (tx_dv) begin
                sh <= {1'b1, tx_byte, 1'b0};
                tx_busy <= 1'b1; c <= 8'd0; n <= 5'd0;
            end
        end else if (c == CLKS_PER_BIT - 1) begin
            c  <= 8'd0;
            sh <= {1'b1, sh[9:1]};
            n  <= n + 1'b1;
            if (n == 9 + GAP_BITS) tx_busy <= 1'b0;
        end else c <= c + 1'b1;
    end
endmodule
