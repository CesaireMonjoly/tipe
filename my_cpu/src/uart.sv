`ifndef UART_SV
`define UART_SV

module uart_tx 
    #(
        parameter CLKS_PER_BIT,
        parameter SIZE = 7
    )
    (
        input clk,
        input ce,
        input i_data_available,
        input [SIZE:0] i_data_byte,
        output logic o_active,
        output logic o_done,
        output logic o_tx
    );

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam SEND_BIT = 2'b10;
    localparam STOP = 2'b11;

    logic [1:0] state = IDLE;
    logic [15:0] counter = 0;
    logic [2:0] bit_index = 0;
    logic [SIZE:0] data_byte = 0;

    always @ (posedge clk) begin
        if (ce) begin
            case (state) 
                IDLE : begin
                    o_tx <= 1;
                    o_done <= 0;
                    counter <= 0;
                    bit_index <= 0;
                    if (i_data_available == 1) begin
                        o_active <= 1;
                        data_byte <= i_data_byte;
                        state <= START;
                    end else begin
                        o_active <= 0;
                    end
                end
                START : begin
                    o_tx <= 0;
                    if (counter < CLKS_PER_BIT-1) begin
                        counter <= counter + 16'b1;
                    end else begin
                        state <= SEND_BIT;
                        counter <= 0;
                    end
                end
                SEND_BIT : begin
                    o_tx <= data_byte[bit_index];
                    if (counter < CLKS_PER_BIT-1) begin
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        if (bit_index < SIZE) begin
                            bit_index <= bit_index + 1;
                        end else begin 
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                STOP : begin
                    o_tx <= 1;
                    if (counter < CLKS_PER_BIT-1) begin 
                        counter <= counter + 1;
                    end else begin
                        counter <= 0;
                        state <= IDLE;
                        o_active <= 0;
                    end
                end
            endcase
        end
    end
endmodule

module uart_rx
    #(parameter CLKS_PER_BIT, parameter SIZE = 7)
    (
        input clk,
        input ce,
        input i_rx,
        output [SIZE:0] o_data_byte,
        output o_data_avail
    );

    //STATES
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam GET_BIT = 2'b10;
    localparam STOP = 2'b11;

    logic [1:0] state = IDLE;
    logic [15:0] counter = 16'b0;
    logic [2:0] bit_index = 3'b0;
    logic [SIZE:0] data_byte = 8'b0;
    logic data_available = 1'b0;

    logic rx = 1'b1;
    logic rx_buffer = 1'b1;

    always@ (posedge clk) begin
        rx_buffer <= i_rx;
        rx <= rx_buffer;
    end
    
    always @ (posedge clk) begin
        if (ce) begin
            case (state) 
                IDLE : begin
                    data_available <= 1'b0;
                    counter <= 16'b0;
                    bit_index <= 8'b0;
                    if (rx == 0)
                        state <= START;
                    else 
                        state <= IDLE;
                end
                START : begin
                    if (counter == (CLKS_PER_BIT-1)/2) begin
                        if (rx == 0) begin
                            counter <= 16'b0;
                            state <= GET_BIT;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        counter <= counter + 16'b1;
                    end
                end
                GET_BIT : begin
                    if (counter < CLKS_PER_BIT-1) begin
                        counter <= counter + 16'b1;
                    end else begin
                        counter <= 16'b0;
                        data_byte[bit_index] <= rx;

                        //Is this the end ?
                        if (bit_index < SIZE) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end
                STOP : begin
                    if (counter < CLKS_PER_BIT-1) begin
                        counter <= counter + 16'b1;
                    end else begin
                        data_available <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

`endif
