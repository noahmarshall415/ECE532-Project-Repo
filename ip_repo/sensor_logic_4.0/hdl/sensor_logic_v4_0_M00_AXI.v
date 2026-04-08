`timescale 1 ns / 1 ps

module sensor_logic_v4_0_M00_AXI #
(
    parameter C_M_START_DATA_VALUE        = 32'hAA000000,
    parameter C_M_TARGET_SLAVE_BASE_ADDR  = 32'h40000000,
    parameter integer C_M_AXI_ADDR_WIDTH  = 32,
    parameter integer C_M_AXI_DATA_WIDTH  = 32,
    parameter integer C_M_TRANSACTIONS_NUM = 4,

    // Threshold in inches
    parameter integer THRESHOLD = 10
)
(
    // AXI clock/reset
    input  wire M_AXI_ACLK,
    input  wire M_AXI_ARESETN,

    // AXI WRITE ADDRESS (unused)
    output wire [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
    output wire [2:0]                    M_AXI_AWPROT,
    output wire                          M_AXI_AWVALID,
    input  wire                          M_AXI_AWREADY,

    // AXI WRITE DATA (unused)
    output wire [C_M_AXI_DATA_WIDTH-1:0]   M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output wire                            M_AXI_WVALID,
    input  wire                            M_AXI_WREADY,

    // AXI WRITE RESPONSE (unused)
    input  wire [1:0]                    M_AXI_BRESP,
    input  wire                          M_AXI_BVALID,
    output wire                          M_AXI_BREADY,

    // AXI READ ADDRESS
    output reg  [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output reg                           M_AXI_ARVALID,
    input  wire                          M_AXI_ARREADY,

    // AXI READ DATA
    input  wire [C_M_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input  wire [1:0]                    M_AXI_RRESP,
    input  wire                          M_AXI_RVALID,
    output reg                           M_AXI_RREADY,

    // LED output (16 bits)
    output reg [15:0] LED_OUT,
    output reg AUDIO_OUT
);

    // Tie off unused channels
    assign M_AXI_AWADDR  = 0;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_AWVALID = 0;

    assign M_AXI_WDATA   = 0;
    assign M_AXI_WSTRB   = 0;
    assign M_AXI_WVALID  = 0;

    assign M_AXI_BREADY  = 1;

    // AXI READ FSM
    localparam IDLE    = 2'b00;
    localparam SEND_AR = 2'b01;
    localparam WAIT_R  = 2'b10;

    reg [1:0]  state;
    reg [31:0] raw_cycles;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN)
            state <= IDLE;
        else begin
            case (state)
                IDLE:    state <= SEND_AR;
                SEND_AR: if (M_AXI_ARREADY) state <= WAIT_R;
                WAIT_R:  if (M_AXI_RVALID)  state <= IDLE;
            endcase
        end
    end

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            M_AXI_ARADDR  <= 0;
            M_AXI_ARVALID <= 0;
            M_AXI_RREADY  <= 0;
        end else begin
            M_AXI_ARADDR  <= C_M_TARGET_SLAVE_BASE_ADDR + 4;
            M_AXI_ARVALID <= (state == SEND_AR);
            M_AXI_RREADY  <= (state == WAIT_R);
        end
    end

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN)
            raw_cycles <= 0;
        else if (state == WAIT_R && M_AXI_RVALID)
            raw_cycles <= M_AXI_RDATA;
    end

    // Cycles->Inches conversion
    reg [31:0] dist_s1, dist_s2;
    reg [31:0] distance_inches;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            dist_s1         <= 0;
            dist_s2         <= 0;
            distance_inches <= 0;
        end else if (state == WAIT_R && M_AXI_RVALID) begin
            dist_s1         <= raw_cycles >> 14;
            dist_s2         <= raw_cycles >> 17;
            distance_inches <= dist_s1 + dist_s2;
        end
    end

    // 4-sample moving average filter
    reg [31:0] avg0, avg1, avg2, avg3;
    reg [31:0] avg_sum;
    reg [31:0] distance_filtered;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            avg0 <= 0; avg1 <= 0; avg2 <= 0; avg3 <= 0;
            avg_sum <= 0;
            distance_filtered <= 0;
        end else if (state == WAIT_R && M_AXI_RVALID) begin
            avg3 <= avg2;
            avg2 <= avg1;
            avg1 <= avg0;
            avg0 <= distance_inches;

            avg_sum <= avg0 + avg1 + avg2 + avg3;
            distance_filtered <= avg_sum >> 2;   // divide by 4
        end
    end

    // LED fill-level computation
    localparam integer MAX_DIST = THRESHOLD * 2;

    reg [31:0] diff;
    reg [31:0] scaled;
    reg [4:0]  fill_level_raw;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            diff           <= 0;
            scaled         <= 0;
            fill_level_raw <= 0;
        end else if (state == WAIT_R && M_AXI_RVALID) begin
            if (distance_filtered >= MAX_DIST)
                diff <= 0;
            else
                diff <= MAX_DIST - distance_filtered;

            scaled <= diff * 16;
            fill_level_raw <= scaled / THRESHOLD;
        end
    end

    // Hysteresis smoothing for LED bar
    reg [4:0] fill_level_stable;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN)
            fill_level_stable <= 0;
        else if (state == WAIT_R && M_AXI_RVALID) begin
            if (fill_level_raw > fill_level_stable + 1)
                fill_level_stable <= fill_level_stable + 1;
            else if (fill_level_raw < fill_level_stable - 1)
                fill_level_stable <= fill_level_stable - 1;
        end
    end

    // LED + Audio output (update only on new measurement)
    reg [15:0] led_mask_s1;

    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            led_mask_s1 <= 16'b0;
            LED_OUT     <= 16'b0;
            AUDIO_OUT   <= 1'b0;
        end else if (state == WAIT_R && M_AXI_RVALID) begin
            if (fill_level_stable == 0)
                led_mask_s1 <= 16'b0;
            else
                led_mask_s1 <= (16'b1 << fill_level_stable) - 1;

            LED_OUT   <= led_mask_s1;
            AUDIO_OUT <= (distance_filtered < THRESHOLD);
        end
    end

endmodule