`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2026 01:55:14 PM
// Design Name: 
// Module Name: posedge
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


module pos(
    input clk,
    input sig,
    output pulse
    );
    
    reg   delay;                          
    always @ (posedge clk) begin
        delay <= sig;
    end

    assign pulse = sig & ~delay;
    
endmodule
