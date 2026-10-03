module trade_core (
    input  wire        clk,
    
    // Interface with uart_rx
    input  wire        rx_dv,
    input  wire  [7:0] rx_byte,
    
    // Interface with uart_tx
    output reg         tx_dv,
    output reg   [7:0] tx_byte,
    input  wire        tx_ready, // High when UART TX is idle
    
    // Interface with Moving Average Engines
    output reg         session_reset,
    output reg         process_enable,
    output reg  [15:0] price_A,
    output reg  [15:0] price_B,
    input  wire  [7:0] action_A,
    input  wire  [7:0] action_B
);

    // BL616 Delay constant (approx. 50us at 27MHz to prevent byte drops)
    localparam INTER_BYTE_DELAY = 1350;

    // State Machine
    localparam s_RX_GATHER = 3'd0;
    localparam s_PROCESS   = 3'd1;
    localparam s_ASSEMBLE  = 3'd2;
    localparam s_TX_SEND   = 3'd3;
    localparam s_TX_DELAY  = 3'd4;

    reg [2:0] state = s_RX_GATHER;
    
    // Buffers for the 8-byte request and 8-byte response
    reg [7:0] rx_buf [0:7];
    reg [7:0] tx_buf [0:7];
    
    reg [3:0] byte_count = 0;
    reg [15:0] delay_count = 0;

    always @(posedge clk) begin
        case (state)
            s_RX_GATHER: begin
                tx_dv <= 1'b0;
                session_reset <= 1'b0;
                process_enable <= 1'b0;
                
                if (rx_dv) begin
                    rx_buf[byte_count] <= rx_byte;
                    
                    if (byte_count == 7) begin
                        byte_count <= 0;
                        state <= s_PROCESS;
                    end else begin
                        byte_count <= byte_count + 1'b1;
                    end
                end
            end
            
            s_PROCESS: begin
                // Check if this is Index 0 (New Session)[cite: 2]
                if ({rx_buf[0], rx_buf[1]} == 16'd0) begin
                    session_reset <= 1'b1;
                end
                
                // Route prices based exclusively on Item ID, not slot[cite: 1, 2]
                // Multi-byte fields are big-endian (Most Significant Byte first)[cite: 2]
                if (rx_buf[2] == 8'h11) begin
                    price_A <= {rx_buf[3], rx_buf[4]}; // Slot 1 is A
                    price_B <= {rx_buf[6], rx_buf[7]}; // Slot 2 is B
                end else begin
                    price_B <= {rx_buf[3], rx_buf[4]}; // Slot 1 is B
                    price_A <= {rx_buf[6], rx_buf[7]}; // Slot 2 is A
                end
                
                process_enable <= 1'b1; // Trigger MA engines to clock in the prices
                state <= s_ASSEMBLE;
            end
            
            s_ASSEMBLE: begin
                process_enable <= 1'b0;
                session_reset <= 1'b0;
                
                // Assemble the 8-byte response echoing the index and slots[cite: 1, 2]
                tx_buf[0] <= rx_buf[0]; // Echo Index MSB
                tx_buf[1] <= rx_buf[1]; // Echo Index LSB
                
                tx_buf[2] <= rx_buf[2]; // Echo Slot 1 Item ID
                tx_buf[3] <= (rx_buf[2] == 8'h11) ? action_A : action_B; // Slot 1 Action
                
                tx_buf[4] <= rx_buf[5]; // Echo Slot 2 Item ID
                tx_buf[5] <= (rx_buf[5] == 8'h11) ? action_A : action_B; // Slot 2 Action
                
                tx_buf[6] <= 8'h00; // Reserved = 0x0000[cite: 1, 2]
                tx_buf[7] <= 8'h00; 
                
                byte_count <= 0;
                state <= s_TX_SEND;
            end
            
            s_TX_SEND: begin
                if (tx_ready) begin
                    tx_byte <= tx_buf[byte_count];
                    tx_dv <= 1'b1;
                    delay_count <= 0;
                    state <= s_TX_DELAY;
                end
            end
            
            s_TX_DELAY: begin
                tx_dv <= 1'b0; // Pulse tx_dv for only one clock cycle
                
                // Enforce an idle delay between bytes to prevent BL616 packet loss[cite: 1, 2]
                if (delay_count < INTER_BYTE_DELAY) begin
                    delay_count <= delay_count + 1'b1;
                end else if (tx_ready) begin
                    if (byte_count == 7) begin
                        byte_count <= 0;
                        state <= s_RX_GATHER; // Transaction complete, wait for next request
                    end else begin
                        byte_count <= byte_count + 1'b1;
                        state <= s_TX_SEND;
                    end
                end
            end
            
            default: state <= s_RX_GATHER;
        endcase
    end
endmodule