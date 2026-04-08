`timescale 1ns / 1ps

module audio_alarm_pattern(
    input  wire CLK100MHZ,
    input  wire alarm_en,   // later connect this to your trigger
    output wire AUD_PWM,
    output wire AUD_SD
);

    // Enable audio output
    assign AUD_SD = 1'b1;

    // ----------------------------
    // 1) Alarm gating: 0.5s ON / 0.5s OFF
    //    100MHz * 0.5s = 50,000,000 cycles
    // ----------------------------
    reg [25:0] gate_cnt = 26'd0;      // enough for 50,000,000
    reg        gate_on  = 1'b0;

    always @(posedge CLK100MHZ) begin
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

    // ----------------------------
    // 2) Tone generator: 1kHz beep
    //    half period = 50,000 cycles
    // ----------------------------
    reg [15:0] tone_cnt = 16'd0;
    reg        tone_sq  = 1'b0;

    always @(posedge CLK100MHZ) begin
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

    // Open-drain AUD_PWM: drive low for 0, high-Z for 1
    assign AUD_PWM = (tone_sq) ? 1'bz : 1'b0;

endmodule
