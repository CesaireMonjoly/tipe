`ifndef MEMORY_SV
`define MEMORY_SV

module memory #(parameter COUNT = 64, parameter DATA_WIDTH = 12, parameter WRITE_PRG = 0) (
        input clk,
        input logic [DATA_WIDTH-1:0] addr,
        input logic write_enable,
        input logic [DATA_WIDTH-1:0] data_in ,
        output logic [DATA_WIDTH-1:0] data_out 
    );

    logic [DATA_WIDTH-1:0] ram [0:COUNT-1];
    logic [DATA_WIDTH-1:0] addr_reg;

    initial begin 
        if (WRITE_PRG) begin 
            $readmemh("program", ram);
        end
    end

    always_ff @(posedge clk) begin
        if(write_enable) begin
            ram[addr] <= data_in;
        end
        else begin
            data_out <= ram[addr_reg];
            addr_reg <= addr;
        end
    end
endmodule

`endif
