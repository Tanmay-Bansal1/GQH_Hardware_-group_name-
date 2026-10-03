module trade_core (
    input  wire        clk,
    
    // Interface with uart_rx
    input  wire        rx_dv,
    input  wire  [7:0] rx_byte,
    
    // Interface with uart_tx
    output reg         tx_dv,
    output reg   [7:0] tx_byte,
    input  wire        tx_ready,
    
    // Interface with Moving Average Engines
    output reg         session_reset,
    output reg         process_enable,
    output reg  [15:0] price_A,
    output reg  [15:0] price_B,
    input  wire  [7:0] action_A,
    input  wire  [7:0] action_B
);

    localparam INTER_BYTE_DELAY = 1;

    // Expanded State Machine for Proper Pipelining
    localparam s_RX_GATHER  = 3'd0;
    localparam s_PROCESS    = 3'd1;
    localparam s_EVALUATE   = 3'd2;
    localparam s_LATCH      = 3'd3;
    localparam s_ASSEMBLE   = 3'd4;
    localparam s_TX_SEND    = 3'd5;
    localparam s_TX_DELAY   = 3'd6;

    reg [2:0] state = s_RX_GATHER;
    
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
                // Step 1: Route prices and isolate the reset flag[cite: 1, 2]
                if ({rx_buf[0], rx_buf[1]} == 16'd0) begin
                    session_reset <= 1'b1;
                end else begin
                    session_reset <= 1'b0;
                end
                
                if (rx_buf[2] == 8'h11) begin
                    price_A <= {rx_buf[3], rx_buf[4]}; 
                    price_B <= {rx_buf[6], rx_buf[7]}; 
                end else begin
                    price_B <= {rx_buf[3], rx_buf[4]}; 
                    price_A <= {rx_buf[6], rx_buf[7]}; 
                end
                
                state <= s_EVALUATE;
            end
            
            s_EVALUATE: begin
                // Step 2: The MA engine resets here if session_reset is high.
                // We assert process_enable now so prices clock in next cycle.
                session_reset <= 1'b0;
                process_enable <= 1'b1; 
                state <= s_LATCH;
            end
            
            s_LATCH: begin
                // Step 3: The MA engine clocks in the prices and updates its action_out.
                process_enable <= 1'b0;
                state <= s_ASSEMBLE;
            end
            
            s_ASSEMBLE: begin
                // Step 4: The new actions are fully valid. Safely assemble the packet[cite: 1, 2].
                tx_buf[0] <= rx_buf[0]; 
                tx_buf[1] <= rx_buf[1]; 
                
                tx_buf[2] <= rx_buf[2]; 
                tx_buf[3] <= (rx_buf[2] == 8'h11) ? action_A : action_B; 
                
                tx_buf[4] <= rx_buf[5]; 
                tx_buf[5] <= (rx_buf[5] == 8'h11) ? action_A : action_B; 
                
                tx_buf[6] <= 8'h00; 
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
                tx_dv <= 1'b0; 
                
                // Keep the idle delay that gave you a flawless 0 timeout score[cite: 1, 2]
                if (delay_count < INTER_BYTE_DELAY) begin
                    delay_count <= delay_count + 1'b1;
                end else if (tx_ready) begin
                    if (byte_count == 7) begin
                        byte_count <= 0;
                        state <= s_RX_GATHER; 
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