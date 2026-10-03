module moving_average (
    input  wire        clk,
    input  wire        reset,      // Triggered by Index 0 to clear session state
    input  wire        enable,     // High when the packet parser routes a new price
    input  wire [15:0] price_in,   // Unsigned 16-bit current price
    output reg  [7:0]  action_out  // Output action code (0x00, 0x01, or 0x02)
);
    // Action Code Constants
    localparam ACT_NONE = 8'h00;
    localparam ACT_SELL = 8'h01;
    localparam ACT_BUY  = 8'h02;

    // State Variables
    reg [15:0] window [0:15];      // Circular buffer, never reset (RAM-friendly)
    reg [3:0]  ptr        = 4'd0;
    reg        full       = 1'b0;  // Set once 16 samples are in the window
    reg [19:0] sum        = 20'd0; // 20-bit rolling sum
    reg [15:0] prev_price = 16'd0; // Previous price

    // Combinational Math
    // During warm-up, subtract 0 so stale window contents don't matter
    wire [15:0] oldest_price = full ? window[ptr] : 16'd0;
    wire [19:0] new_sum      = sum - oldest_price + price_in;
    wire [15:0] old_avg      = sum[19:4];      // floor(sum / 16)
    wire [15:0] new_avg      = new_sum[19:4];  // floor(new_sum / 16)

    // Window memory: write only, no reset, so the tool can infer RAM
    always @(posedge clk) begin
        if (enable)
            window[ptr] <= price_in;
    end

    // Control and decision logic
    always @(posedge clk) begin
        if (reset) begin
            ptr        <= 4'd0;
            full       <= 1'b0;
            sum        <= 20'd0;
            prev_price <= 16'd0;
            action_out <= ACT_NONE;
        end else if (enable) begin
            ptr        <= ptr + 1'b1;
            sum        <= new_sum;
            prev_price <= price_in;

            if (!full) begin
                // Warm-up phase: fill the window and output NONE
                if (ptr == 4'd15)
                    full <= 1'b1;
                action_out <= ACT_NONE;
            end else if ((prev_price <= old_avg) && (price_in > new_avg)) begin
                // Upward crossing
                action_out <= ACT_BUY;
            end else if ((prev_price >= old_avg) && (price_in < new_avg)) begin
                // Downward crossing
                action_out <= ACT_SELL;
            end
            // Otherwise, action_out holds the last action
        end
    end
endmodule