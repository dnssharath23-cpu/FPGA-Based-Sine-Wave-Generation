`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg rst;

    wire [11:0] sine1;
    wire [11:0] sine2;
    wire [23:0] product;

    // =========================================================
    // DUT
    // =========================================================

    top uut (

        .clk      (clk),
        .rst      (rst),
        .sine1 (sine1),
        .sine2 (sine2),
        .product(product)

    );


    // =========================================================
    // 100 MHz clock
    // Period = 10 ns
    // =========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // =========================================================
    // RESET
    // =========================================================

    initial begin

        rst = 1'b1;

        #100;

        rst = 1'b0;

        // Run simulation
        #5000;

        $finish;

    end

endmodule