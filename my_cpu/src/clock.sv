`ifndef CLOCK
`define CLOCK

module clock #(parameter [64:0] MAX) (
        input clk,
        input reset,
        output reg clock_div
    );
        
    logic [64:0] counter = 0;
    always_ff @ (posedge clk) begin
        if (reset) begin
            counter <= 0;
        end
        if (counter < MAX/2) 
            clock_div <= 1;
        else 
            clock_div <= 0;
        
        if (counter >= MAX) 
            counter <= 0;
        else 
            counter <= counter + 1;
    end
endmodule

`endif
