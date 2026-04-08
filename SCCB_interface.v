`timescale 1ns / 1ps

module SCCB_interface
#(
    parameter CLK_FREQ = 25000000,
    parameter SCCB_FREQ = 100000
)
(
    input wire clk,
    input wire start,
    input wire [7:0] address,
    input wire [7:0] data,
    output reg ready,
    output reg SIOC_oe,
    output reg SIOD_oe
);

    localparam CAMERA_ADDR = 8'h42;

    localparam ST_IDLE            = 0;
    localparam ST_START           = 1;
    localparam ST_LOAD_BYTE       = 2;
    localparam ST_BIT_PHASE_1     = 3;
    localparam ST_BIT_PHASE_2     = 4;
    localparam ST_BIT_PHASE_3     = 5;
    localparam ST_BIT_PHASE_4     = 6;
    localparam ST_STOP_PHASE_1    = 7;
    localparam ST_STOP_PHASE_2    = 8;
    localparam ST_STOP_PHASE_3    = 9;
    localparam ST_STOP_PHASE_4    = 10;
    localparam ST_DONE            = 11;
    localparam ST_WAIT            = 12;

    initial begin
        SIOC_oe = 0;
        SIOD_oe = 0;
        ready = 1;
    end

    reg [3:0] state = 0;
    reg [3:0] next_state_after_wait = 0;
    reg [31:0] wait_counter = 0;

    reg [7:0] reg_addr_latched;
    reg [7:0] reg_data_latched;
    reg [1:0] byte_phase = 0;
    reg [7:0] shift_byte = 0;
    reg [3:0] bit_count = 0;

    always @(posedge clk) begin
        case (state)

            ST_IDLE: begin
                bit_count <= 0;
                byte_phase <= 0;
                if (start) begin
                    state <= ST_START;
                    reg_addr_latched <= address;
                    reg_data_latched <= data;
                    ready <= 0;
                end
                else begin
                    ready <= 1;
                end
            end

            ST_START: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_LOAD_BYTE;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOC_oe <= 0;
                SIOD_oe <= 1;
            end

            ST_LOAD_BYTE: begin
                state <= (byte_phase == 3) ? ST_STOP_PHASE_1 : ST_BIT_PHASE_1;
                byte_phase <= byte_phase + 1;
                bit_count <= 0;
                case (byte_phase)
                    0: shift_byte <= CAMERA_ADDR;
                    1: shift_byte <= reg_addr_latched;
                    2: shift_byte <= reg_data_latched;
                    default: shift_byte <= reg_data_latched;
                endcase
            end

            ST_BIT_PHASE_1: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_BIT_PHASE_2;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOC_oe <= 1;
            end

            ST_BIT_PHASE_2: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_BIT_PHASE_3;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOD_oe <= (bit_count == 8) ? 0 : ~shift_byte[7];
            end

            ST_BIT_PHASE_3: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_BIT_PHASE_4;
                wait_counter <= (CLK_FREQ / (2 * SCCB_FREQ));
                SIOC_oe <= 0;
            end

            ST_BIT_PHASE_4: begin
                state <= (bit_count == 8) ? ST_LOAD_BYTE : ST_BIT_PHASE_1;
                shift_byte <= shift_byte << 1;
                bit_count <= bit_count + 1;
            end

            ST_STOP_PHASE_1: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_STOP_PHASE_2;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOC_oe <= 1;
            end

            ST_STOP_PHASE_2: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_STOP_PHASE_3;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOD_oe <= 1;
            end

            ST_STOP_PHASE_3: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_STOP_PHASE_4;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOC_oe <= 0;
            end

            ST_STOP_PHASE_4: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_DONE;
                wait_counter <= (CLK_FREQ / (4 * SCCB_FREQ));
                SIOD_oe <= 0;
            end

            ST_DONE: begin
                state <= ST_WAIT;
                next_state_after_wait <= ST_IDLE;
                wait_counter <= (2 * CLK_FREQ / SCCB_FREQ);
                byte_phase <= 0;
            end

            ST_WAIT: begin
                state <= (wait_counter == 0) ? next_state_after_wait : ST_WAIT;
                wait_counter <= (wait_counter == 0) ? 0 : wait_counter - 1;
            end
        endcase
    end

endmodule