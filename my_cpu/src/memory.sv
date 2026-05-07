`ifndef MEMORY_SV
`define MEMORY_SV

module memory #(parameter COUNT = 4096, parameter DATA_WIDTH = 12, parameter WRITE_PRG = 0) (
        input clk,
        input logic [DATA_WIDTH-1:0] addr,
        input logic write_enable,
        input logic [DATA_WIDTH-1:0] data_in ,
        output logic [DATA_WIDTH-1:0] data_out 
    );

    logic [DATA_WIDTH-1:0] ram [0:COUNT-1];

    logic [DATA_WIDTH-1:0] ram_0;
    logic [DATA_WIDTH-1:0] ram_1;
    logic [DATA_WIDTH-1:0] ram_2;
    logic [DATA_WIDTH-1:0] ram_3;
    logic [DATA_WIDTH-1:0] ram_4;

    assign ram_0 = ram[0];
    assign ram_1 = ram[1];
    assign ram_2 = ram[2];
    assign ram_3 = ram[3];
    assign ram_4 = ram[4];

    initial begin 
        if (WRITE_PRG) begin 
            $readmemb("prog.txt", ram);
        end else begin
            for(int i = 0; i < COUNT; i++) begin
                ram[i] <= 0;
            end 
        end
    end

    always_ff @(negedge clk) begin
        if(write_enable) begin
            ram[addr] <= data_in;
        end
        else begin
            data_out <= ram[addr];
        end
    end
endmodule

`endif
