`timescale 1ns / 1ps
`default_nettype wire

module top (
    input  wire        clk_100,
    input  wire        rst_n,

    output wire        ov7670_sioc,
    inout  wire        ov7670_siod,
    input  wire        ov7670_vsync,
    input  wire        ov7670_href,
    input  wire        ov7670_pclk,
    input  wire [7:0]  ov7670_data,
    output wire        ov7670_xclk,
    output wire        ov7670_pwdn,
    output wire        ov7670_reset,

    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    // BD outputs
    output wire        bd_AUD_PWM,
    output wire        bd_AUD_SD,
    output wire [0:0]  bd_GREEN_LED,
    output wire        bd_RED_LED,

    // BD JC pins
    inout  wire        bd_jc_pin1,
    inout  wire        bd_jc_pin2,
    inout  wire        bd_jc_pin3,
    inout  wire        bd_jc_pin4,
    inout  wire        bd_jc_pin7,
    inout  wire        bd_jc_pin8,
    inout  wire        bd_jc_pin9,
    inout  wire        bd_jc_pin10,

    // BD LEDs
    output wire [15:0] bd_leds,
    input  wire        usb_uart_rxd,
    output wire        usb_uart_txd

);

    reg bd_rst_sync1 = 0, bd_rst_sync2 = 0;
    
    always @(posedge clk_100 or negedge rst_n) begin
        if (!rst_n) begin
            bd_rst_sync1 <= 0;
            bd_rst_sync2 <= 0;
        end else begin
            bd_rst_sync1 <= 1;
            bd_rst_sync2 <= bd_rst_sync1;
        end
    end

    wire bd_reset_n = bd_rst_sync2;
    
    wire clk_100_buf;
    
    BUFG u_bufg_sysclk (
        .I(clk_100),
        .O(clk_100_buf)
    );

    // BD control signals
    wire        bd_start;
    wire        bd_stop;
design_1_wrapper u_bd (
    .GREEN_LED (bd_GREEN_LED),
    .RED_LED   (bd_RED_LED),
    .jc_pin1_io (bd_jc_pin1),
    .jc_pin2_io (bd_jc_pin2),
    .jc_pin3_io (bd_jc_pin3),
    .jc_pin4_io (bd_jc_pin4),
    .jc_pin7_io (bd_jc_pin7),
    .jc_pin8_io (bd_jc_pin8),
    .jc_pin9_io (bd_jc_pin9),
    .jc_pin10_io(bd_jc_pin10),

    .leds      (bd_leds),

    .reset(bd_reset_n),
    .sys_clock(clk_100_buf),

    .start     (bd_start),   // replaces btnU
    .stop      (bd_stop),     // replaces btnC
    .usb_uart_rxd(usb_uart_rxd),
    .usb_uart_txd(usb_uart_txd)
);

// Audio Alarm

reg alarm_en = 1'b0;

// 3-cycle buffer and pulse generator for bd_stop

reg stop_q1 = 1'b0;
reg stop_q2 = 1'b0;
reg stop_q3 = 1'b0;

always @(posedge clk_100) begin
    stop_q1 <= bd_stop;
    stop_q2 <= stop_q1;
    stop_q3 <= stop_q2;
end

wire bd_stop_3cyc_level = stop_q1 & stop_q2 & stop_q3;

// Rising-edge detector on the qualified level
reg bd_stop_3cyc_d = 1'b0;
always @(posedge clk_100) begin
    bd_stop_3cyc_d <= bd_stop_3cyc_level;
end
wire bd_stop_pulse = bd_stop_3cyc_level & ~bd_stop_3cyc_d;

// 3-cycle buffer and pulse generator for bd_start

reg start_q1 = 1'b0;
reg start_q2 = 1'b0;
reg start_q3 = 1'b0;

always @(posedge clk_100) begin
    start_q1 <= bd_start;
    start_q2 <= start_q1;
    start_q3 <= start_q2;
end

wire bd_start_3cyc_level = start_q1 & start_q2 & start_q3;

// Rising-edge detector on the qualified level
reg bd_start_3cyc_d = 1'b0;
always @(posedge clk_100) begin
    bd_start_3cyc_d <= bd_start_3cyc_level;
end

wire bd_start_pulse = bd_start_3cyc_level & ~bd_start_3cyc_d;

always @(posedge clk_100) begin
    if(bd_stop_pulse)
        alarm_en <= 1'b0;
    else if (bd_start_pulse)
        alarm_en <= 1'b1;
end


// 0.5s gate (50,000,000 cycles @ 100 MHz)
reg [25:0] gate_cnt = 26'd0;
reg        gate_on  = 1'b0;

always @(posedge clk_100) begin
    if (!alarm_en) begin
        gate_cnt <= 26'd0;
        gate_on  <= 1'b0;
    end else begin
        if (gate_cnt == 26'd49_999_999) begin
            gate_cnt <= 26'd0;
            gate_on  <= ~gate_on;
        end else begin
            gate_cnt <= gate_cnt + 26'd1;
        end
    end
end

// 1 kHz tone (toggle every 50,000 cycles)
reg [15:0] tone_cnt = 16'd0;
reg        tone_sq  = 1'b0;

always @(posedge clk_100) begin
    if (!alarm_en || !gate_on) begin
        tone_cnt <= 16'd0;
        tone_sq  <= 1'b0;
    end else begin
        if (tone_cnt == 16'd49_999) begin
            tone_cnt <= 16'd0;
            tone_sq  <= ~tone_sq;
        end else begin
            tone_cnt <= tone_cnt + 16'd1;
        end
    end
end

// Enable amplifier whenever alarm is active
assign bd_AUD_SD = alarm_en;

// Open-drain PWM output: 0 = drive low, 1 = high-Z
assign bd_AUD_PWM = (tone_sq) ? 1'bz : 1'b0;
    // Clocking
    wire clk_25, clk_24, locked;

    clk_wiz_0 u_clk (
        .clk_in1  (clk_100),
        .resetn   (rst_n),
        .clk_out1 (clk_25),
        .clk_out2 (clk_24),
        .locked   (locked)
    );

    wire sys_rst_n = rst_n & locked;

    assign ov7670_reset = sys_rst_n;
    assign ov7670_pwdn  = 1'b0;
    assign ov7670_xclk  = clk_24;


    // pclk-domain reset synchroniser
    reg pclk_rst_sync1 = 1'b0, pclk_rst_sync2 = 1'b0;

    always @(posedge ov7670_pclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pclk_rst_sync1 <= 1'b0;
            pclk_rst_sync2 <= 1'b0;
        end else begin
            pclk_rst_sync1 <= 1'b1;
            pclk_rst_sync2 <= pclk_rst_sync1;
        end
    end

    wire p_rst_n = pclk_rst_sync2;


    // Camera configuration (runs once after board reset)
    reg start_poweron = 1'b0, start_sent = 1'b0;

    always @(posedge clk_24 or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            start_poweron <= 1'b0;
            start_sent    <= 1'b0;
        end else if (!start_sent) begin
            start_poweron <= 1'b1;
            start_sent    <= 1'b1;
        end else begin
            start_poweron <= 1'b0;
        end
    end

    wire config_done;

    camera_configure #(.CLK_FREQ(24_000_000)) u_cam_config (
        .clk   (clk_24),
        .start (start_poweron),
        .sioc  (ov7670_sioc),
        .siod  (ov7670_siod),
        .done  (config_done)
    );

    // Synchronise config_done --> clk_100
    reg config_done_s1 = 1'b0, config_done_s2 = 1'b0;

    always @(posedge clk_100 or negedge rst_n) begin
        if (!rst_n) begin
            config_done_s1 <= 1'b0;
            config_done_s2 <= 1'b0;
        end else begin
            config_done_s1 <= config_done;
            config_done_s2 <= config_done_s1;
        end
    end

    wire config_done_100 = config_done_s2;


    // start_flag: set by btnU, cleared by btnC
    reg start_flag = 1'b0;

    always @(posedge clk_100 or negedge sys_rst_n) begin
        if (!sys_rst_n)
            start_flag <= 1'b0;
        else if (bd_stop_pulse)
            start_flag <= 1'b0;
        else if (config_done_100 && bd_start_pulse)
            start_flag <= 1'b1;
    end


    // Cross start_flag --> pclk (ONE synchroniser, declared once)
    reg start_s1 = 1'b0, start_s2 = 1'b0, start_s3 = 1'b0;

    always @(posedge ov7670_pclk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            start_s1 <= 1'b0;
            start_s2 <= 1'b0;
            start_s3 <= 1'b0;
        end else begin
            start_s1 <= start_flag;
            start_s2 <= start_s1;
            start_s3 <= start_s2;
        end
    end

    // Rising edge of start_flag --> one-shot start pulse for camera_read FSM
    wire start_pulse_pclk = start_s2 & ~start_s3;

    // Level signal: HIGH when not streaming (used for stop + soft_rst)
    wire stop_level = ~start_s2;



    // Camera read
    wire [15:0] pixel_data;
    wire        pixel_valid;
    wire        frame_done;
    wire        cam_streaming;

    camera_read u_cam_read (
        .p_clock    (ov7670_pclk),
        .vsync      (ov7670_vsync),
        .href       (ov7670_href),
        .p_data     (ov7670_data),
        .start      (start_pulse_pclk),
        .stop       (stop_level),
        .pixel_data (pixel_data),
        .pixel_valid(pixel_valid),
        .frame_done (frame_done),
        .streaming  (cam_streaming)
    );


    // Pixel capture
    wire [18:0] bram_addr;
    wire [11:0] bram_din;
    wire        bram_we;

    pixel_capture u_pix_cap (
        .p_clock    (ov7670_pclk),
        .p_rst_n    (p_rst_n),
        .soft_rst   (stop_level),
        .pixel_data (pixel_data),
        .pixel_valid(pixel_valid),
        .frame_done (frame_done),
        .buf_addr   (bram_addr),
        .buf_din    (bram_din),
        .buf_we     (bram_we)
    );

    // Synchronise cam_streaming --> clk_25 for VGA
    reg streaming_vga_s1 = 1'b0, streaming_vga_s2 = 1'b0;

    always @(posedge clk_25 or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            streaming_vga_s1 <= 1'b0;
            streaming_vga_s2 <= 1'b0;
        end else begin
            streaming_vga_s1 <= cam_streaming;
            streaming_vga_s2 <= streaming_vga_s1;
        end
    end


    // VGA
    wire [18:0] fb_rd_addr;
    wire        fb_rd_en;
    wire [11:0] fb_rd_data;
    wire        vga_blank;
    wire [11:0] rgb12;

    vga_driver_nexys4 u_vga (
        .sclk      (clk_25),
        .s_rst_n   (sys_rst_n),
        .streaming (streaming_vga_s2),
        .vga_hsync (vga_hsync),
        .vga_vsync (vga_vsync),
        .vga_blank (vga_blank),
        .vga_rgb   (rgb12),
        .fb_rd_addr(fb_rd_addr),
        .fb_rd_en  (fb_rd_en),
        .fb_rd_data(fb_rd_data)
    );

    assign vgaBlue  = vga_blank ? 4'h0 : rgb12[11:8];
    assign vgaGreen = vga_blank ? 4'h0 : rgb12[7:4];
    assign vgaRed   = vga_blank ? 4'h0 : rgb12[3:0];


    // Frame buffer BRAM
    frame_buffer_ram #(
        .ADDR_WIDTH(19),
        .DATA_WIDTH(12),
        .DEPTH     (312000)
    ) u_frame_buf (
        .clk_w  (ov7670_pclk),
        .we     (bram_we),
        .addr_w (bram_addr),
        .din    (bram_din),
        .clk_r  (clk_25),
        .addr_r (fb_rd_addr),
        .dout   (fb_rd_data)
    );


endmodule