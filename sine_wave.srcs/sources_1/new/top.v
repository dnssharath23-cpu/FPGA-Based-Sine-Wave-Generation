`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.09.2026 23:27:36
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clk,rst,
    output signed [23:0] product,
    output signed [11:0] sine1,
    output signed [11:0] sine2
    );
    
    wire [31:0] fcw1 = 32'd42949673;
    wire [31:0] fcw2 = 32'd128849019;
    
    sine_dds dds1(clk,rst,fcw1,sine1);
    sine_dds dds2(clk,rst,fcw2,sine2);
    

assign product = sine1 * sine2;
    
endmodule
