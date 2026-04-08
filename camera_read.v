`timescale 1ns / 1ps
`default_nettype none

module camera_read(
    input  wire        p_clock,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  p_data,
    input  wire        start,  // pulse: begin streaming
    input  wire        stop,  // pulse: end streaming after current frame
    output reg  [15:0] pixel_data  = 16'd0,
    output reg         pixel_valid = 1'b0,
    output reg         frame_done  = 1'b0,
    output reg         streaming   = 1'b0  // high while live-stream is active
);

    localparam [2:0]
        IDLE             = 3'd0,
        WAIT_FRAME_END   = 3'd1,
        WAIT_FRAME_START = 3'd2,
        ROW_CAPTURE      = 3'd3;

    reg [2:0] FSM_state  = IDLE;
    reg       pixel_half = 1'b0;
    reg       stop_pend  = 1'b0;  // stop requested, honour after this frame

    // vsync synchroniser / edge detector
    reg vsync_d1 = 1'b0, vsync_d2 = 1'b0;
    always @(posedge p_clock) begin
        vsync_d1 <= vsync;
        vsync_d2 <= vsync_d1;
    end
    wire vsync_rise = (~vsync_d2) & vsync_d1;  // blanking starts
    wire vsync_fall =   vsync_d2  & (~vsync_d1);  // active frame starts

    // main FSM
    always @(posedge p_clock) begin
        pixel_valid <= 1'b0;
        frame_done  <= 1'b0;

        case (FSM_state)

            // Wait for start pulse
            IDLE: begin
                pixel_half <= 1'b0;
                stop_pend  <= 1'b0;
                streaming  <= 1'b0;
                if (start) begin
                    streaming <= 1'b1;
                    FSM_state <= vsync ? WAIT_FRAME_START : WAIT_FRAME_END;
                end
            end

            // Flush the frame already in progress
            WAIT_FRAME_END: begin
                pixel_half <= 1'b0;
                if (stop) stop_pend <= 1'b1;  // latch stop request
                if (vsync_rise)
                    FSM_state <= WAIT_FRAME_START;
            end

            // Align to the next clean frame start
            WAIT_FRAME_START: begin
                pixel_half <= 1'b0;
                if (stop) stop_pend <= 1'b1;
                if (vsync_fall)
                    FSM_state <= ROW_CAPTURE;
            end

            // Capture pixels until end-of-frame
            ROW_CAPTURE: begin
                if (stop) stop_pend <= 1'b1;  // latch mid-frame stop

                if (vsync_rise) begin
                    // Frame boundary
                    frame_done <= 1'b1;
                    pixel_half <= 1'b0;

                    if (stop_pend || stop) begin
                        // honour pending stop - finish cleanly after this frame
                        streaming  <= 1'b0;
                        stop_pend  <= 1'b0;
                        FSM_state  <= IDLE;
                    end else begin
                        // live-stream: immediately queue the next frame
                        FSM_state  <= WAIT_FRAME_START;
                    end
                end
                else if (href) begin
                    if (!pixel_half) begin
                        pixel_data[15:8] <= p_data;
                        pixel_half       <= 1'b1;
                    end else begin
                        pixel_data[7:0] <= p_data;
                        pixel_valid     <= 1'b1;
                        pixel_half      <= 1'b0;
                    end
                end
                else begin
                    pixel_half <= 1'b0;  // inter-row blanking: reset byte lane
                end
            end

            default: begin
                FSM_state  <= IDLE;
                pixel_half <= 1'b0;
                streaming  <= 1'b0;
                stop_pend  <= 1'b0;
            end

        endcase
    end

endmodule