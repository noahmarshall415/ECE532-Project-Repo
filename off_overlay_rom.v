`timescale 1ns / 1ps

// off_overlay_rom.v
// Camera-off overlay ROM  -  80 x 60 pixels = 4 800 entries
// (Reduced from 160x120 to save 5 RAMB36 and fix BRAM overflow)
//
// Pixel format  [12]     = alpha  (1 = opaque, 0 = transparent)
//               [11:8]   = Blue  (4-bit)
//               [7:4]    = Green (4-bit)
//               [3:0]    = Red   (4-bit)
// Matches top.v: vgaBlue=rgb12[11:8], vgaGreen=rgb12[7:4], vgaRed=rgb12[3:0]
//
// Displayed when streaming = 0  (video OFF),
// centered on 640x480 screen: x in [280..359], y in [210..269]

module off_overlay_rom (
    input  wire        clk,
    input  wire [12:0] addr,   // 0 .. 4799
    output reg  [12:0] dout
);
    (* rom_style = "block" *)
    reg [12:0] rom [0:4799];

    initial $readmemh("off_overlay.mem", rom);

    always @(posedge clk)
        dout <= rom[addr];
endmodule
