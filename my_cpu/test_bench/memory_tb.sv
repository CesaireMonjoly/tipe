`timescale 1ns/1ps
`include "src/memory.sv"

module memory_tb;
    // Parametres
    localparam CLK_PERIOD = 10;

    // Signaux
    logic [11:0] addr;
    logic write_enable;
    logic [11:0] data_in;
    logic [11:0] data_out;

    // Horloge
    logic clk;
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Instanciation de la memoire
    memory #(.COUNT(1337)) memmory_dut (
        .clk(clk),
        .addr(addr),
        .write_enable(write_enable),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Dump var
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, memmory_dut);
    end



    // Task
    task test_write;
        input [11:0] w_addr;
        input [11:0] value;

        begin
            @(negedge clk)
            addr = w_addr;
            data_in = value;
            write_enable = 1;
            @(posedge clk)
            #1
            write_enable = 0;
            $display("value %d is now set at addr %d\n", value, w_addr);
        end
    endtask

    task test_read;
        input [11:0] r_addr;

        begin
            @(negedge clk);
            addr = r_addr;
            write_enable = 0;
            @(posedge clk)
            #1;
            $display("Value at %d is %d\n", r_addr, data_out);
        end
    endtask

    // Main
    initial begin
        //Launch tests

        for (int i = 12'h000; i < 12'hfff; i++) begin
            test_write(i, i);
            test_read(i);
        end

    end

endmodule
