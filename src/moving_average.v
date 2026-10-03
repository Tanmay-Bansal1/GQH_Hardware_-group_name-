module moving_average (
    input  wire        clk,
    input  wire        reset,      // Triggered by Index 0 to clear session state[cite: 1]
    input  wire        enable,     // High when the packet parser routes a new price
    input  wire [15:0] price_in,   // Unsigned 16-bit current price[cite: 1]
    output reg  [7:0]  action_out  // Output action code (0x00, 0x01, or 0x02)[cite: 1]
);

    // Independent State Variables[cite: 1]
    reg [15:0] window [0:15];
    reg [3:0]  ptr = 0;
    reg [4:0]  count = 0;          // Tracks warm-up phase (0 to 16)
    reg [19:0] sum = 0;            // 20-bit rolling sum[cite: 1]
    reg [15:0] prev_price = 0;     // Previous price[cite: 1]
    
    // Action Code Constants[cite: 1]
    localparam ACT_NONE = 8'h00;
    localparam ACT_SELL = 8'h01;
    localparam ACT_BUY  = 8'h02;

    // Combinational Math: Evaluated immediately on the current inputs
    wire [15:0] oldest_price;
    wire [19:0] new_sum;
    wire [15:0] old_avg;
    wire [15:0] new_avg;

    assign oldest_price = window[ptr];
    
    // sum >> 4 performs floor division by 16, discarding the fraction[cite: 1]
    assign old_avg = sum[19:4]; 
    
    // new_sum = old_sum - oldest_price + current_price[cite: 1]
    assign new_sum = sum - oldest_price + price_in;
    assign new_avg = new_sum[19:4]; 

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            // Index 0 clears all previous session state[cite: 1]
            ptr <= 0;
            count <= 0;
            sum <= 0;
            prev_price <= 0;
            action_out <= ACT_NONE;
            for (i = 0; i < 16; i = i + 1) begin
                window[i] <= 0;
            end
        end else if (enable) begin
            // 1. Update the circular window and advance pointer
            window[ptr] <= price_in;
            ptr <= ptr + 1'b1;
            
            // 2. Update sum and log current price as the new previous price[cite: 1]
            sum <= new_sum;
            prev_price <= price_in;
            
            // 3. Determine action based on phase
            if (count < 16) begin
                // Warm-up phase: fill window and output NONE[cite: 1]
                count <= count + 1'b1;
                action_out <= ACT_NONE;
            end else begin
                // Update procedure (index 16 onward)[cite: 1]
                if ((prev_price <= old_avg) && (price_in > new_avg)) begin
                    // Upward crossing[cite: 1]
                    action_out <= ACT_BUY;
                end else if ((prev_price >= old_avg) && (price_in < new_avg)) begin
                    // Downward crossing[cite: 1]
                    action_out <= ACT_SELL;
                end
                // Otherwise, the last action naturally repeats (held in action_out)[cite: 1]
            end
        end
    end
endmodule