`timescale 1ns / 1ps

module tb_top();
    reg  sys_clk = 0;
    reg  reset_btn = 0;
    reg  uart_rx_i = 1;  // Idle high
    wire uart_tx_o;
    wire led0_n;
    wire led1_n;

    always #18.518 sys_clk = ~sys_clk;

    top uut (
        .sys_clk(sys_clk),
        .reset_btn(reset_btn),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .led0_n(led0_n),
        .led1_n(led1_n)
    );

   
    localparam BIT_PERIOD = 8680.5;


    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            uart_rx_i = 0; 
            #(BIT_PERIOD);
            

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop bit
            uart_rx_i = 1; 
            #(BIT_PERIOD);
            
           
            #10000; 
        end
    endtask

    initial begin

        uart_rx_i = 1;
        #100000; 

        send_uart_byte(8'h00); // Index MSB = 0
        send_uart_byte(8'h00); // Index LSB = 0
        send_uart_byte(8'h11); // Item A
        send_uart_byte(8'h00); // Price A MSB
        send_uart_byte(8'h64); // Price A LSB (100)
        send_uart_byte(8'h22); // Item B
        send_uart_byte(8'h00); // Price B MSB
        send_uart_byte(8'h64); // Price B LSB (100)
        

        #2000000;

        send_uart_byte(8'h00); // Index MSB = 0
        send_uart_byte(8'h10); // Index LSB = 16
        send_uart_byte(8'h11); // Item A
        send_uart_byte(8'h00); // Price A MSB = 0
        send_uart_byte(8'h50); // Price A LSB = 80
        send_uart_byte(8'h22); // Item B
        send_uart_byte(8'h00); // Price B MSB = 0
        send_uart_byte(8'hC8); // Price B LSB = 200 (0xC8)

    
        #2000000;
        $stop;
    end
endmodule
