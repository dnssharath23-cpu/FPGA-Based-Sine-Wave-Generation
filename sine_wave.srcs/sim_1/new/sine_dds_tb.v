`timescale 1ns / 1ps

module sine_dds_tb;

    reg clk;
    reg rst;
    reg [31:0] fcw;
    wire [11:0] sine_out;


    // =========================================================
    // DUT
    // =========================================================

    sine_dds uut (

        .clk      (clk),
        .rst      (rst),
        .fcw(fcw),
        .sine_out (sine_out)

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
        fcw = 32'd42949673;
        // Run simulation
        #5000;

        $finish;

    end

endmodule