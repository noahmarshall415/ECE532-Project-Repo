`timescale 1ns / 1ps
// vga_driver_nexys4.v 
//
// Overlay summary
// 1. TOP-LEFT  snapshot  (existing):
//      80x60 px   |  x: 0..79,   y: 0..59
//      Shown always when streaming=1 (live snapshot in BRAM)
//
// 2. BOTTOM-RIGHT  recording indicator  (new, rec_overlay_rom):
//      80x60 px   |  x: 560..639, y: 420..479
//      Shown when streaming=1, alpha-keyed PNG
//
// 3. CENTER  camera-off icon  (new, off_overlay_rom):
//      160x120 px |  x: 240..399, y: 180..299
//      Shown when streaming=0, alpha-keyed PNG

module vga_driver_nexys4 (
    input  wire        sclk,
    input  wire        s_rst_n,
    input  wire        streaming,   // high once camera is running
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire        vga_blank,
    output reg  [11:0] vga_rgb,
    output reg  [18:0] fb_rd_addr,  // 19-bit for 312 000-entry BRAM
    output reg         fb_rd_en,
    input  wire [11:0] fb_rd_data
);


    // VGA 640x480 @ 60 Hz timing

    localparam integer H_VISIBLE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48;
    localparam integer V_VISIBLE = 480, V_FRONT = 10, V_SYNC = 2,  V_BACK = 33;
    localparam integer H_TOTAL = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;
    localparam integer V_TOTAL = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;


    // Overlay geometry constants
    // Existing snapshot (top-left, in main BRAM)
    localparam [18:0] SNAP_BASE = 19'd307200;
    localparam integer OVL_W    = 80, OVL_H = 60;

    // NEW: Recording indicator (bottom-right corner)
    localparam integer REC_W  = 80,  REC_H  = 60;
    localparam integer REC_X0 = 560, REC_Y0 = 420;   // top-left corner on screen

    // NEW: Camera-off icon (centered, 80x60 to save BRAM)
    localparam integer OFF_W  = 80,  OFF_H  = 60;
    localparam integer OFF_X0 = 280, OFF_Y0 = 210;   // top-left corner on screen

    // Timing counters
    reg [9:0] cnt_h, cnt_v;

    always @(posedge sclk or negedge s_rst_n) begin
        if (!s_rst_n) cnt_h <= 10'd0;
        else if (cnt_h == H_TOTAL - 1) cnt_h <= 10'd0;
        else cnt_h <= cnt_h + 10'd1;
    end

    always @(posedge sclk or negedge s_rst_n) begin
        if (!s_rst_n) cnt_v <= 10'd0;
        else if (cnt_h == H_TOTAL - 1) begin
            if (cnt_v == V_TOTAL - 1) cnt_v <= 10'd0;
            else cnt_v <= cnt_v + 10'd1;
        end
    end

    assign vga_hsync = (cnt_h < H_SYNC) ? 1'b0 : 1'b1;
    assign vga_vsync = (cnt_v < V_SYNC) ? 1'b0 : 1'b1;

    wire video_on =
        (cnt_h >= H_SYNC + H_BACK) && (cnt_h < H_SYNC + H_BACK + H_VISIBLE) &&
        (cnt_v >= V_SYNC + V_BACK) && (cnt_v < V_SYNC + V_BACK + V_VISIBLE);

    assign vga_blank = ~video_on;

    // Current display pixel (0-origin)
    wire [9:0] x = cnt_h - (H_SYNC + H_BACK);   // 0..639
    wire [9:0] y = cnt_v - (V_SYNC + V_BACK);   // 0..479

    // Pre-fetch window: issue BRAM/ROM read 1 cycle
    // before the pixel is displayed.
    wire fetch_en =
        (cnt_h >= (H_SYNC + H_BACK - 1)) &&
        (cnt_h <  (H_SYNC + H_BACK + H_VISIBLE - 1)) &&
        (cnt_v >= (V_SYNC + V_BACK)) &&
        (cnt_v <  (V_SYNC + V_BACK + V_VISIBLE));

    // Pixel coordinates being *fetched* (1 cycle ahead of display)
    wire [9:0] xf = (cnt_h == (H_SYNC + H_BACK - 1)) ? 10'd0 : x + 10'd1;
    wire [9:0] yf = y;

    // Overlay 0 (existing): top-left snapshot in BRAM
    wire in_ovl_fetch = (xf < OVL_W) && (yf < OVL_H);

    // snap addr = yf*80+xf = (yf<<6)+(yf<<4)+xf
    wire [18:0] snap_addr_f = SNAP_BASE
                            + ({9'd0, yf} << 6)
                            + ({9'd0, yf} << 4)
                            + {9'd0, xf};

    // live addr = yf*640+xf = (yf<<9)+(yf<<7)+xf
    wire [18:0] live_addr_f = ({9'd0, yf} << 9)
                            + ({9'd0, yf} << 7)
                            + {9'd0, xf};

    wire [18:0] addr_fetch = in_ovl_fetch ? snap_addr_f : live_addr_f;

    // Overlay 1 (NEW): Recording indicator - bottom-right
    //   Region: x in [REC_X0 .. REC_X0+REC_W-1]
    //           y in [REC_Y0 .. REC_Y0+REC_H-1]
    //   Shown when streaming=1
    //   ROM: rec_overlay_rom  (80x60=4800, 13-bit {alpha,B,G,R})
    //   Address: local_y*80 + local_x  = (ly<<6)+(ly<<4)+lx
    wire in_rec_fetch =
        (xf >= REC_X0) && (xf < REC_X0 + REC_W) &&
        (yf >= REC_Y0) && (yf < REC_Y0 + REC_H);

    wire [5:0] rec_ly = yf[5:0] - REC_Y0[5:0];   // 0..59
    wire [6:0] rec_lx = xf[6:0] - REC_X0[6:0];   // 0..79

    // rec_ly*80 + rec_lx = (rec_ly<<6)+(rec_ly<<4)+rec_lx  (all 13-bit)
    wire [12:0] rec_addr_f =
        {1'b0,  rec_ly, 6'b0} +   // rec_ly * 64
        {3'b0,  rec_ly, 4'b0} +   // rec_ly * 16
        {6'b0,  rec_lx};          // rec_lx

    // Feed ROM: valid address when in-region and fetching, else 0
    wire [12:0] rec_rom_addr = (fetch_en && in_rec_fetch) ? rec_addr_f : 13'd0;

    wire [12:0] rec_rom_dout;

    rec_overlay_rom u_rec_rom (
        .clk  (sclk),
        .addr (rec_rom_addr),
        .dout (rec_rom_dout)
    );
    
    // Overlay 2 (NEW): Camera-off icon - centered
    //   Region: x in [OFF_X0 .. OFF_X0+OFF_W-1]
    //           y in [OFF_Y0 .. OFF_Y0+OFF_H-1]
    //   Shown when streaming=0
    //   ROM: off_overlay_rom  (160x120=19200, 13-bit {alpha,B,G,R})
    //   Address: local_y*160 + local_x = (ly<<7)+(ly<<5)+lx

    wire in_off_fetch =
        (xf >= OFF_X0) && (xf < OFF_X0 + OFF_W) &&
        (yf >= OFF_Y0) && (yf < OFF_Y0 + OFF_H);

    wire [5:0] off_ly = yf[5:0] - OFF_Y0[5:0];   // 0..59
    wire [6:0] off_lx = xf[6:0] - OFF_X0[6:0];   // 0..79

    // off_ly*80 + off_lx = (off_ly<<6)+(off_ly<<4)+off_lx  (12-bit max)
    wire [12:0] off_addr_f =
        {1'b0, off_ly, 6'b0} +   // off_ly * 64
        {3'b0, off_ly, 4'b0} +   // off_ly * 16
        {6'b0, off_lx};          // off_lx

    // Feed ROM: valid address when in-region and fetching, else 0
    wire [12:0] off_rom_addr = (fetch_en && in_off_fetch) ? off_addr_f : 13'd0;

    wire [12:0] off_rom_dout;

    off_overlay_rom u_off_rom (
        .clk  (sclk),
        .addr (off_rom_addr),      // 13-bit (80x60 = 4800 entries)
        .dout (off_rom_dout)
    );


    // Pipeline stage: delay flags by 1 cycle to align
    // with BRAM / ROM registered outputs

    reg video_on_d1;
    reg in_ovl_d1;   // snapshot border (existing)
    reg in_rec_d1;   // recording overlay active  (gated: streaming must be 1)
    reg in_off_d1;   // camera-off overlay active (gated: streaming must be 0)

    always @(posedge sclk or negedge s_rst_n) begin
        if (!s_rst_n) begin
            fb_rd_en    <= 1'b0;
            fb_rd_addr  <= 19'd0;
            video_on_d1 <= 1'b0;
            in_ovl_d1   <= 1'b0;
            in_rec_d1   <= 1'b0;
            in_off_d1   <= 1'b0;
            vga_rgb     <= 12'h000;
        end else begin
            // Main BRAM read request 
            fb_rd_en   <= fetch_en;
            fb_rd_addr <= addr_fetch;

            //  Pipeline delay flags 
            video_on_d1 <= video_on;
            in_ovl_d1   <= fetch_en && in_ovl_fetch;

            // Recording overlay: only active when streaming
            in_rec_d1 <= fetch_en && in_rec_fetch && streaming;

            // Camera-off overlay: only active when NOT streaming
            in_off_d1 <= fetch_en && in_off_fetch && !streaming;

            // pixel output MUX 
            if (video_on_d1) begin

                if (!streaming) begin
                    //  Video OFF 
                    // Show camera-off icon in center; grey elsewhere
                    if (in_off_d1 && off_rom_dout[12])
                        // Opaque pixel from camera-off PNG
                        vga_rgb <= off_rom_dout[11:0];
                    else
                        // Dark-grey background (same as before)
                        vga_rgb <= 12'h111;

                end else begin
                    //  Video ON 
                    // Priority (highest first):
                    //   1. Recording indicator (bottom-right, opaque pixels only)
                    //   2. Snapshot border (1-px white outline on top-left overlay)
                    //   3. Frame-buffer data (live video or snapshot)

                    if (in_rec_d1 && rec_rom_dout[12])
                        // Opaque pixel from recording-indicator PNG
                        vga_rgb <= rec_rom_dout[11:0];
                    else if (in_ovl_d1 && (x == OVL_W || y == OVL_H))
                        // 1-px white border on right/bottom edge of snapshot
                        vga_rgb <= 12'hFFF;
                    else
                        // Live video or snapshot pixel from BRAM
                        vga_rgb <= fb_rd_data;
                end

            end else begin
                vga_rgb <= 12'h000;
            end
        end
    end

endmodule
