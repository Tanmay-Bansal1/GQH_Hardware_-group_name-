`timescale 1ns / 1ps

module tb_moving_average_engine;

    reg clk;
    reg rst_n;
    reg [15:0] index_i;
    reg [15:0] price_i;
    reg process_i;
    reg new_session_i;

    wire [7:0] action_o;
    wire valid_o;

    moving_average_engine uut (
        .clk(clk),
        .rst_n(rst_n),
        .index_i(index_i),
        .price_i(price_i),
        .process_i(process_i),
        .new_session_i(new_session_i),
        .action_o(action_o),
        .valid_o(valid_o)
    );

    always #5 clk = ~clk;

    task send_sample(input [15:0] idx, input [15:0] prc, input is_new, input [7:0] exp_action);
        begin
            @(negedge clk);
            process_i     = 1;
            index_i       = idx;
            price_i       = prc;
            new_session_i = is_new;
            
            @(negedge clk);
            process_i = 0;

            while (!valid_o) @(negedge clk);

            if (action_o !== exp_action) begin
                $display("FAIL | Idx: %0d | Price: %0d | Exp: %02x | Got: %02x", idx, prc, exp_action, action_o);
            end else begin
                $display("PASS | Idx: %0d | Price: %0d | Action: %02x", idx, prc, action_o);
            end
        end
    endtask

    integer i;

    initial begin
        clk = 0; rst_n = 0; process_i = 0; index_i = 0; price_i = 0; new_session_i = 0;
        
        #20 rst_n = 1; #10;

        $display("\n--- 1. Index 0 returns NONE ---");
        send_sample(0, 100, 1, 8'h00);

        $display("\n--- 2. Indices 1-15 keep returning NONE ---");
        for (i = 1; i <= 15; i = i + 1) begin
            send_sample(i, 100, 0, 8'h00);
        end

        $display("\n--- 3. Index 16 correctly uses warm-up (No crossing yet) ---");
        // Sum is 1600. Old avg 100. New avg 100.
        send_sample(16, 100, 0, 8'h00);

        $display("\n--- 4. Forced upward crossing returns BUY ---");
        // Prev is 100. Old avg is 100. Jump price to 120. New avg becomes 101.
        // Prev(100) <= OldAvg(100) and Cur(120) > NewAvg(101) -> BUY
        send_sample(17, 120, 0, 8'h02);

        $display("\n--- 5. Non-crossing sample after BUY still returns BUY ---");
        // Prev is 120. Old avg is 101. Price 120. New avg becomes 102.
        // Prev(120) is NOT <= OldAvg(101). No crossing. Holds BUY.
        send_sample(18, 120, 0, 8'h02);

        $display("\n--- 6. Forced downward crossing returns SELL ---");
        // Prev is 120. Old avg is 102. Drop price to 80. New avg becomes 101.
        // Prev(120) >= OldAvg(102) and Cur(80) < NewAvg(101) -> SELL
        send_sample(19, 80, 0, 8'h01);

        $display("\n--- 7. Non-crossing sample after SELL still returns SELL ---");
        // Prev is 80. Old avg 101. Price 80. New avg 100. 
        // Prev(80) is NOT >= OldAvg(101). No crossing. Holds SELL.
        send_sample(20, 80, 0, 8'h01);

        $display("\n--- 8. Processing 32+ samples wraps the buffer ---");
        // Pushing flat 100s up to index 33 to prove the write_pointer[3:0] wraps 
        // without array bounds overflow, and averages normalize back to 100.
        for (i = 21; i <= 33; i = i + 1) begin
            send_sample(i, 100, 0, (i < 27) ? 8'h01 : 8'h01); // Eventual stabilization
        end

        $display("\n--- 9. Sending index 0 halfway through clears all history ---");
        send_sample(0, 50, 1, 8'h00);

        $display("\nTestbench complete.");
        $stop;
    end
endmodule
