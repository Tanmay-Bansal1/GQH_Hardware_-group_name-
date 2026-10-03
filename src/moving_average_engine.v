module moving_average_engine (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] index_i,
    input  wire [15:0] price_i,
    input  wire        process_i,
    input  wire        new_session_i,
    output reg  [7:0]  action_o,
    output reg         valid_o
);

    localparam STATE_IDLE = 1'b0;
    localparam STATE_EVAL = 1'b1;

    reg state;

    // 5 Required State Elements
    reg [15:0] window [0:15];
    reg [19:0] sum_reg;
    reg [15:0] prev_price;
    reg [7:0]  last_action;
    reg [3:0]  write_pointer;

    // Latched inputs for pipelining
    reg [15:0] cur_price;
    reg [15:0] cur_index;
    reg        is_new_session;

    // Combinational math
    wire [19:0] next_sum = sum_reg - {4'd0, window[write_pointer]} + {4'd0, cur_price};
    wire [15:0] old_avg  = sum_reg[19:4];
    wire [15:0] new_avg  = next_sum[19:4];

    integer i;

    always @(posedge clk) begin
        if (~rst_n) begin
            state          <= STATE_IDLE;
            valid_o        <= 1'b0;
            action_o       <= 8'h00;
            sum_reg        <= 20'd0;
            prev_price     <= 16'd0;
            last_action    <= 8'h00;
            write_pointer  <= 4'd0;
            for (i = 0; i < 16; i = i + 1) begin
                window[i] <= 16'd0;
            end
        end else begin
            case (state)
                STATE_IDLE: begin
                    valid_o <= 1'b0; 
                    if (process_i) begin
                        cur_price      <= price_i;
                        cur_index      <= index_i;
                        is_new_session <= new_session_i;
                        write_pointer  <= index_i[3:0]; // Bottom 4 bits handle 0-15 wrapping natively
                        state          <= STATE_EVAL;
                    end
                end

                STATE_EVAL: begin
                    if (is_new_session) begin
                        // 1. Clear state and initialize with sample 0
                        window[0] <= cur_price;
                        for (i = 1; i < 16; i = i + 1) begin
                            window[i] <= 16'd0;
                        end
                        sum_reg     <= {4'd0, cur_price};
                        prev_price  <= cur_price;
                        last_action <= 8'h00; // NONE
                        action_o    <= 8'h00; // NONE
                    end else begin
                        // 2. Standard operation: update window and sum
                        window[write_pointer] <= cur_price;
                        sum_reg               <= next_sum;
                        prev_price            <= cur_price;

                        if (cur_index < 16'd16) begin
                            // Warm-up range (1 - 15)
                            action_o    <= 8'h00; // NONE
                            last_action <= 8'h00;
                        end else begin
                            // Crossing detection range (16+)
                            if ((prev_price <= old_avg) && (cur_price > new_avg)) begin
                                action_o    <= 8'h02; // BUY
                                last_action <= 8'h02;
                            end else if ((prev_price >= old_avg) && (cur_price < new_avg)) begin
                                action_o    <= 8'h01; // SELL
                                last_action <= 8'h01;
                            end else begin
                                action_o    <= last_action; // Held prior action
                            end
                        end
                    end
                    
                    valid_o <= 1'b1;
                    state   <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
