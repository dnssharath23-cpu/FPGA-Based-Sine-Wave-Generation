`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.09.2026 21:54:40
// Design Name: 
// Module Name: sine_dds
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


module sine_dds(
    input clk, rst,
    input [31:0] fcw,
    output reg  signed [11:0] sine_out
    );
    reg [31:0] phase_acc;
    reg [11:0] sine_rom [0:1023];
    
    initial begin
    $readmemh("sine_lut.mem",sine_rom);
    end
    
    always @(posedge clk) begin
    if (rst)
       phase_acc <= 32'd0;
    else
       phase_acc <= phase_acc + fcw;
    end
    
    always @(posedge clk)begin
    if(rst)
       sine_out <= 12'd0;
    else
       sine_out <= sine_rom[phase_acc[31:22]]- 12'd2048;
    end
       
endmodule
