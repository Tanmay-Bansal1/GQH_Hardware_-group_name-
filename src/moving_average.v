
module moving_average (
    input  wire        clk,
    input  wire        clr,     
    input  wire        upd,
    input  wire [15:0] price,
    input  wire [3:0]  ptr,
    input  wire        full,    
    output reg  [1:0]  act = 2'd0 
);
    reg [15:0] mem [0:15];
    reg [15:0] oldest_q = 16'd0;
    reg [19:0] sum = 20'd0;
    reg        pgt = 1'b0, plt = 1'b0;

    always @(posedge clk) begin
        oldest_q <= mem[ptr];
        if (upd) mem[ptr] <= price;
    end

    wire [15:0] oldest = full ? oldest_q : 16'd0;
    wire [16:0] delta  = {1'b0, price} - {1'b0, oldest};
    wire [19:0] nsum   = sum + {{3{delta[16]}}, delta};
    wire [15:0] navg   = nsum[19:4];
    wire [16:0] d      = {1'b0, price} - {1'b0, navg};   
    wire        lt     = d[16];
    wire        gt     = ~d[16] & (d[15:0] != 16'd0);

    always @(posedge clk) begin
        if (clr)      sum <= 20'd0;
        else if (upd) sum <= nsum;
        if (upd) begin
            pgt <= gt;
            plt <= lt;
            if (!full)             act <= 2'b00;
            else if (!pgt && gt)   act <= 2'b10;   // BUY
            else if (!plt && lt)   act <= 2'b01;   // SELL
        end
    end
endmodule
