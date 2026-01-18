`ifndef CLOCK
`define CLOCK

module clock_enable #(parameter [32:0] MAX) (
        input clk,
        input reset,
        output logic ce
    );
        
    logic [32:0] counter = 0;
    always_ff @ (posedge clk) begin
        if (reset) begin
            counter <= 0;
            ce <= 0;
        end else begin
            if (counter >= MAX - 1) begin
                counter <= 0;
                ce <= 1; 
            end else begin
                counter <= counter + 1;
                ce <= 0; 
            end
        end
    end
endmodule

`endif
