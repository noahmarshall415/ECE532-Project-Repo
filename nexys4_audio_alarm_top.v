`timescale 1ns / 1ps

// Nexys4 DDR Audio Alarm Demo
// - SW0=1: alarm enabled -> 0.5s ON / 0.5s OFF 1kHz beep
// - SW0=0: silent
// - LED0 lights when alarm enabled
// - AUD_PWM is OPEN-DRAIN: drive 0 or Z (do NOT drive 1)

module nexys4_audio_alarm_top(
    input  wire CLK100MHZ,
    input  wire SW0,
    output wire LED0,
    output wire AUD_PWM,
    output wire AUD_SD
);

    // Enable audio amplifier
    assign AUD_SD = 1'b1;

    // LED indicates enable
    assign LED0 = SW0;

    // ----------------------------
    // 0.5s gate: ON/OFF
    // 100MHz * 0.5s = 50,000,000 cycles
    // ----------------------------
    reg [25:0] gate_cnt = 26'd0;
    reg        gate_on  = 1'b0;

    always @(posedge CLK100MHZ) begin
        if (!SW0) begin
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

    // ----------------------------
    // 1kHz tone square wave
    // half period = 100MHz / (2*1kHz) = 50,000 cycles
    // ----------------------------
    reg [15:0] tone_cnt = 16'd0;
    reg        tone_sq  = 1'b0;

    always @(posedge CLK100MHZ) begin
        if (!SW0 || !gate_on) begin
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

    // ----------------------------
    // OPEN-DRAIN AUD_PWM:
    // tone_sq=0 -> drive low
    // tone_sq=1 -> high-Z
    // ----------------------------
    assign AUD_PWM = (tone_sq) ? 1'bz : 1'b0;

endmodule
