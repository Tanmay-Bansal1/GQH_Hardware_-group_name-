module uart_rx #(
    parameter CLKS_PER_BIT = 234 // 27 MHz clock / 115200 baud
)(
    input  wire       clk,
    input  wire       rx_serial, // Raw incoming serial signal
    output reg        rx_dv,     // Data Valid pulse (1 clock cycle)
    output reg  [7:0] rx_byte    // 8-bit output byte
);

    // State Machine States
    localparam s_IDLE         = 3'b000;
    localparam s_RX_START_BIT = 3'b001;
    localparam s_RX_DATA_BITS = 3'b010;
    localparam s_RX_STOP_BIT  = 3'b011;
    localparam s_CLEANUP      = 3'b100;

    reg [2:0] state = s_IDLE;
    reg [7:0] clk_count = 0;
    reg [2:0] bit_index = 0; 
    
    // Double-register the incoming rx signal to prevent metastability
    reg rx_data_r = 1'b1;
    reg rx_data   = 1'b1;
    
    always @(posedge clk) begin
        rx_data_r <= rx_serial;
        rx_data   <= rx_data_r;
    end

    always @(posedge clk) begin
        case (state)
            s_IDLE: begin
                rx_dv     <= 1'b0;
                clk_count <= 0;
                bit_index <= 0;
                
                // Start bit detected (line drops to 0)
                if (rx_data == 1'b0) begin
                    state <= s_RX_START_BIT;
                end else begin
                    state <= s_IDLE;
                end
            end
            
            s_RX_START_BIT: begin
                // Wait until the middle of the start bit
                if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                    if (rx_data == 1'b0) begin // Verify it is still low
                        clk_count <= 0;
                        state     <= s_RX_DATA_BITS;
                    end else begin
                        state     <= s_IDLE;
                    end
                end else begin
                    clk_count <= clk_count + 1'b1;
                    state     <= s_RX_START_BIT;
                end
            end
            
            s_RX_DATA_BITS: begin
                // Wait one full bit duration
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                    state     <= s_RX_DATA_BITS;
                end else begin
                    clk_count <= 0;
                    
                    // The protocol sends the least significant bit first
                    rx_byte[bit_index] <= rx_data; 
                    
                    // Check if we have received all 8 bits
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1'b1;
                        state     <= s_RX_DATA_BITS;
                    end else begin
                        bit_index <= 0;
                        state     <= s_RX_STOP_BIT;
                    end
                end
            end
            
            s_RX_STOP_BIT: begin
                // Wait one full bit duration for the stop bit
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1'b1;
                    state     <= s_RX_STOP_BIT;
                end else begin
                    rx_dv     <= 1'b1; // Pulse Data Valid high
                    clk_count <= 0;
                    state     <= s_CLEANUP;
                end
            end
            
            s_CLEANUP: begin
                rx_dv <= 1'b0; // Reset Data Valid
                state <= s_IDLE;
            end
            
            default: begin
                state <= s_IDLE;
            end
        endcase
    end
endmodule