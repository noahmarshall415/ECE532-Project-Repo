`timescale 1ns / 1ps

module top_vga_colorbars(
    input  wire       clk_100mhz,
    input  wire       rst_n,

    output wire       vga_hsync,
    output wire       vga_vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue
);

    // Pixel clock (25MHz) from Clocking Wizard
    wire clk_pix;
    wire locked;

    clk_wiz_0 u_clk (
        .clk_in1 (clk_100mhz),
        .resetn  (rst_n),
        .clk_out1(clk_pix),
        .locked  (locked)
    );

    // Active-low reset for VGA domain
    wire vga_rst_n = rst_n & locked;

    // VGA driver <-> BRAM signals
    wire        vga_blank;
    wire [11:0] rgb12;

    wire [16:0] fb_rd_addr;
    wire        fb_rd_en;
    wire [11:0] fb_rd_data;

    vga_driver_nexys4 u_vga (
        .sclk      (clk_pix),
        .s_rst_n   (vga_rst_n),
        .vga_hsync (vga_hsync),
        .vga_vsync (vga_vsync),
        .vga_blank (vga_blank),
        .vga_rgb   (rgb12),

        .fb_rd_addr(fb_rd_addr),
        .fb_rd_en  (fb_rd_en),
        .fb_rd_data(fb_rd_data)
    );

    // Note: current mapping is [11:8]=Blue, [7:4]=Green, [3:0]=Red
    assign vgaBlue  = vga_blank ? 4'h0 : rgb12[11:8];
    assign vgaGreen = vga_blank ? 4'h0 : rgb12[7:4];
    assign vgaRed   = vga_blank ? 4'h0 : rgb12[3:0];
    
    
// BRAM self-test fill (SLOW, visible proof)
localparam integer FB_DEPTH = 76800;

reg        filling;
reg [16:0] wr_addr;

// Slow down writes to SEE the image being written into BRAM.
// One write pulse every 1024 pixel clocks (~40us at 25MHz).
reg [9:0] slow_cnt;
wire      slow_ce = (slow_cnt == 10'd0);

// 12-bit test pattern (matches B/G/R nibble mapping)
wire [11:0] wr_data = {wr_addr[11:8], wr_addr[7:4], wr_addr[3:0]};

always @(posedge clk_pix or negedge vga_rst_n) begin
    if (!vga_rst_n) begin
        filling  <= 1'b1;
        wr_addr  <= 17'd0;
        slow_cnt <= 10'd0;
    end else begin
        slow_cnt <= slow_cnt + 10'd1;

        if (filling && slow_ce) begin
            if (wr_addr == FB_DEPTH-1) begin
                filling <= 1'b0;      // done, stop writing forever
            end else begin
                wr_addr <= wr_addr + 17'd1;
            end
        end
    end
end

wire       fb_wr_en = filling & slow_ce;
wire [0:0] fb_wea   = fb_wr_en;  // IP expects [0:0]
wire       fb_ena   = fb_wr_en;     



    // framebuf BRAM (Block Memory Generator IP)
    // Port A = write (self-test fill here)
    // Port B = read  (VGA)
    framebuf u_fb (
        // Port A (write)
        .clka (clk_pix),
        .ena  (fb_ena),
        .wea  (fb_wea),
        .addra(wr_addr),
        .dina (wr_data),

        // Port B (read)
        .clkb (clk_pix),
        .enb  (fb_rd_en),
        .addrb(fb_rd_addr),
        .doutb(fb_rd_data)
    );

endmodule