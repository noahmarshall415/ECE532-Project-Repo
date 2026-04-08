module button_pulse(
    input  wire clk,
    input  wire btn_raw,  // raw input from board button
    output wire pulse  // single-cycle pulse output
);

    // Debouncer
    // counts how long button is stable before accepting the change
    reg [19:0] debounce_cnt = 0;
    reg btn_stable = 0;

    always @(posedge clk) begin
        if (btn_raw !== btn_stable) begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt == 20'hFFFFF) begin  // ~10ms at 100MHz
                btn_stable   <= btn_raw;
                debounce_cnt <= 0;
            end
        end else begin
            debounce_cnt <= 0;
        end
    end

    // Edge detector
    // generates a 1-cycle pulse on the rising edge of btn_stable
    reg btn_prev = 0;

    always @(posedge clk) begin
        btn_prev <= btn_stable;
    end

    assign pulse = (btn_stable && !btn_prev);  // high for exactly 1 clock cycle

endmodule