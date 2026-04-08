`timescale 1ns / 1ps
module pixel_capture (
    input  wire        p_clock,
    input  wire        p_rst_n,
    input  wire        soft_rst,    // high while btnC active (= ~start_flag)
    input  wire [15:0] pixel_data,
    input  wire        pixel_valid,
    input  wire        frame_done,
    output wire [18:0] buf_addr,
    output wire [11:0] buf_din,
    output wire        buf_we
);
    localparam [18:0] LIVE_BASE = 19'd0;
    localparam [18:0] SNAP_BASE = 19'd307200;
    localparam integer CAM_W = 640, CAM_H = 480;
    localparam integer OVL_W = 80,  OVL_H = 60;

    reg        snap_done   = 1'b0;
    reg        pending_rst = 1'b0;  // wait for frame boundary before clearing
    reg [9:0]  px_count    = 10'd0;
    reg [9:0]  py_count    = 10'd0;
    reg [18:0] live_addr   = 19'd0;
    reg [12:0] snap_addr   = 13'd0;

    assign buf_din = { pixel_data[11:8],  // rgb12[11:8] vgaBlue  
                   pixel_data[15:12],  // rgb12[7:4] vgaGreen 
                   pixel_data[3:0] };  // rgb12[3:0] vgaRed

    wire snap_pixel = (px_count[2:0] == 3'd0) && (py_count[2:0] == 3'd0);

    // Never write while soft_rst is high (camera_read is winding down)
    assign buf_we   = pixel_valid && !soft_rst &&
                      (!snap_done ? snap_pixel : 1'b1);
    assign buf_addr = !snap_done ? (SNAP_BASE + {6'd0, snap_addr})
                                 : (LIVE_BASE + live_addr);

    always @(posedge p_clock or negedge p_rst_n) begin
        if (!p_rst_n) begin
            snap_done   <= 1'b0;
            pending_rst <= 1'b0;
            px_count    <= 10'd0;
            py_count    <= 10'd0;
            live_addr   <= 19'd0;
            snap_addr   <= 13'd0;

        // btnC pressed while streaming: ARM the deferred reset.
        end else if (soft_rst && snap_done && !pending_rst) begin
            pending_rst <= 1'b1;

        end else if (frame_done) begin
            if (pending_rst) begin
                // Clean frame boundary (now safe to reset snapshot state)
                snap_done   <= 1'b0;
                snap_addr   <= 13'd0;
                pending_rst <= 1'b0;
            end else begin
                // Normal end-of-frame: lock snapshot, reset live pointer
                snap_done   <= 1'b1;
            end
            live_addr <= 19'd0;
            px_count  <= 10'd0;
            py_count  <= 10'd0;

        end else if (pixel_valid && !soft_rst) begin
            if (px_count == (CAM_W - 1)) begin
                px_count <= 10'd0;
                py_count <= py_count + 10'd1;
            end else begin
                px_count <= px_count + 10'd1;
            end

            if (!snap_done) begin
                if (snap_pixel) snap_addr <= snap_addr + 13'd1;
            end else begin
                live_addr <= live_addr + 19'd1;
            end
        end
    end
endmodule