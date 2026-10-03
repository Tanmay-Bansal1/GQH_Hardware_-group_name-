module uart_tx #(
    parameter CLKS_PER_BIT = 234 // 27 MHz clock / 115200 baud
)(
    input  wire       clk,
    input  wire       tx_dv,      // Pulse high to start transmission
    input  wire [7:0] tx_byte,    // 8-bit byte to transmit
    output reg        tx_ready,   // High when idle and ready for new data
    output reg        tx_serial   // Raw serial output to the FPGA pin
);

    // State Machine States
    localparam s_IDLE         = 3'b000;
    localparam s_TX_START_BIT = 3'b001;
    localparam s_TX_DATA_BITS = 3'b010;
    localparam s_TX_STOP_BIT  = 3'b011;
    localparam s_CLEANUP      = 3'b100;

    reg [2:0] state = s_IDLE;
    reg [7:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_data = 0;

    always @(posedge clk) begin
        case (state)
            s_IDLE: begin
                tx_serial <= 1'b1; // The UART line idles high
                tx_ready  <= 1'b1;
                clk_count <= 0;
                bit_index <= 0;

                // Latch data and begin transmission on Data Valid pulse
                if (tx_dv == 1'b1) begin
                    tx_ready <= 1'b0;
                    tx_data  <= tx_byte;
                    state    <= s_TX_START_BIT;
                end
            end

            s_TX_START_BIT: begin
                tx_serial <= 1'b0; // Start bit is always low

                // Hold for one full bit duration
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    clk_count <= 0;
                    state     <= s_TX_DATA_BITS;
                end
            end

            s_TX_DATA_BITS: begin
                // Protocol requires sending the least significant bit first
                tx_serial <= tx_data[bit_index];

                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    clk_count <= 0;

                    // Advance to the next bit or move to stop bit
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1'b1;
                    end else begin
                        bit_index <= 0;
                        state     <= s_TX_STOP_BIT;
                    end
                end
            end

            s_TX_STOP_BIT: begin
                tx_serial <= 1'b1; // Stop bit is always high[cite: 1, 2]

                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                end else begin
                    clk_count <= 0;
                    state     <= s_CLEANUP;
                end
            end

            s_CLEANUP: begin
                tx_ready <= 1'b1; // Signal that the transmitter is ready for the next byte
                state    <= s_IDLE;
            end

            default: begin
                state <= s_IDLE;
            end
        endcase
    end
endmodule