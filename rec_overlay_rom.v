`timescale 1ns / 1ps
// rec_overlay_rom.v
// Recording-indicator overlay ROM  –  80 x 60 pixels = 4 800 entries
// Pixel format  [12]     = alpha  (1 = opaque, 0 = transparent)
//               [11:8]   = Blue  (4-bit)
//               [7:4]    = Green (4-bit)
//               [3:0]    = Red   (4-bit)
// Matches top.v:  vgaBlue=rgb12[11:8], vgaGreen=rgb12[7:4], vgaRed=rgb12[3:0]
//
// Displayed when streaming = 1  (video ON),
// positioned at bottom-right corner: x in [560..639], y in [420..479]
module rec_overlay_rom (
    input  wire        clk,
    input  wire [12:0] addr,   // 0 .. 4799
    output reg  [12:0] dout
);
    (* rom_style = "block" *)
    reg [12:0] rom [0:4799];

    initial $readmemh("rec_overlay.mem", rom);

    always @(posedge clk)
        dout <= rom[addr];
endmodule
