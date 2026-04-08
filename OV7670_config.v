`timescale 1ns / 1ps

module OV7670_config
#(
    parameter CLK_FREQ = 25000000
)
(
    input  wire       clk,
    input  wire       SCCB_interface_ready,
    input  wire [15:0] rom_data,
    input  wire       start,
    output reg  [7:0] rom_addr,
    output reg        done,
    output reg  [7:0] SCCB_interface_addr,
    output reg  [7:0] SCCB_interface_data,
    output reg        SCCB_interface_start
);

    localparam ST_IDLE             = 0;
    localparam ST_PROCESS_ROM_WORD = 1;
    localparam ST_WAIT             = 2;
    localparam ST_FINISHED         = 3;

    reg [2:0]  state = ST_IDLE;
    reg [2:0]  next_state_after_wait = ST_IDLE;
    reg [31:0] wait_counter = 0;

    initial begin
        rom_addr = 0;
        done = 0;
        SCCB_interface_addr = 0;
        SCCB_interface_data = 0;
        SCCB_interface_start = 0;
    end

    always @(posedge clk) begin
        case (state)

            ST_IDLE: begin
                rom_addr <= 0;
                SCCB_interface_start <= 0;

                if (start) begin
                    done <= 0;
                    state <= ST_PROCESS_ROM_WORD;
                end
            end

            ST_PROCESS_ROM_WORD: begin
                SCCB_interface_start <= 0;

                case (rom_data)
                    16'hFFFF: begin
                        state <= ST_FINISHED;
                    end

                    16'hFFF0: begin
                        rom_addr <= rom_addr + 1;
                        wait_counter <= (CLK_FREQ / 100);
                        next_state_after_wait <= ST_PROCESS_ROM_WORD;
                        state <= ST_WAIT;
                    end

                    default: begin
                        if (SCCB_interface_ready) begin
                            SCCB_interface_addr <= rom_data[15:8];
                            SCCB_interface_data <= rom_data[7:0];
                            SCCB_interface_start <= 1;
                            rom_addr <= rom_addr + 1;
                            wait_counter <= 0;
                            next_state_after_wait <= ST_PROCESS_ROM_WORD;
                            state <= ST_WAIT;
                        end
                    end
                endcase
            end

            ST_WAIT: begin
                SCCB_interface_start <= 0;

                if (wait_counter == 0) begin
                    state <= next_state_after_wait;
                end
                else begin
                    wait_counter <= wait_counter - 1;
                end
            end

            ST_FINISHED: begin
                done <= 1;
                SCCB_interface_start <= 0;
                state <= ST_IDLE;
            end

            default: begin
                state <= ST_IDLE;
            end

        endcase
    end

endmodule