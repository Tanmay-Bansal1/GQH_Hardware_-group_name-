module moving_average (
    input  wire        clk,
    input  wire        clr,
    input  wire        upd,
    input  wire [15:0] price,
    input  wire [3:0]  ptr,
    input  wire        full,
    output reg  [1:0]  act = 2'd0   // 00 NONE, 01 SELL, 10 BUY
);
    reg [15:0] mem [0:15];
    reg [15:0] oldest = 16'd0;       // RAM read register; sync-reset to 0 while window not full
    reg [19:0] sum = 20'd0;
    reg        pgt = 1'b0, plt = 1'b0;

    always @(posedge clk) begin
        if (clr | ~full) oldest <= 16'd0;
        else             oldest <= mem[ptr];
        if (upd) mem[ptr] <= price;
    end

    wire [16:0] delta = {1'b0, price} - {1'b0, oldest};
    wire [19:0] nsum  = sum + {{3{delta[16]}}, delta};
    wire [15:0] navg  = nsum[19:4];
    wire [16:0] d     = {1'b0, price} - {1'b0, navg};
    wire        lt    = d[16];
    wire        gt    = ~d[16] & (d[15:0] != 16'd0);

    always @(posedge clk) begin
        if (clr)      sum <= 20'd0;
        else if (upd) sum <= nsum;
        if (upd) begin
            pgt <= gt;
            plt <= lt;
            if (!full)             act <= 2'b00;
            else if (!pgt && gt)   act <= 2'b10;
            else if (!plt && lt)   act <= 2'b01;
        end
    end
endmodule
