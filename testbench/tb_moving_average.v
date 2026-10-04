`timescale 1ns / 1ps

module tb_moving_average();
    reg         clk = 0;
    reg         clr = 0;
    reg         upd = 0;
    reg  [15:0] price = 0;
    reg  [3:0]  ptr = 0;
    reg         full = 0;
    wire [1:0]  act;

    always #18.518 clk = ~clk;

    moving_average uut (
        .clk(clk),
        .clr(clr),
        .upd(upd),
        .price(price),
        .ptr(ptr),
        .full(full),
        .act(act)
    );


    task apply_price(input [15:0] new_price);
        begin
            @(posedge clk);
            price = new_price;
            upd = 1;
            @(posedge clk);
            upd = 0;
            // Advance pointer exactly as trade_core does
            ptr = ptr + 1;
            if (ptr == 4'd15) full = 1;
            #100; // Wait before next packet
        end
    endtask

    integer i;

    initial begin

        @(posedge clk);
        clr = 1;
        ptr = 0;
        full = 0;
        @(posedge clk);
        clr = 0;
        
        #100;

    
        for (i = 0; i < 16; i = i + 1) begin
            apply_price(16'd100);
        end

       
        #100;
        
       
        apply_price(16'd95);

        apply_price(16'd105);
        
        apply_price(16'd94);

        #500;
        $stop;
    end
endmodule
