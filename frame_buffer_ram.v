`timescale 1ns / 1ps

module frame_buffer_ram #(
    parameter ADDR_WIDTH = 19,
    parameter DATA_WIDTH = 12,
    parameter DEPTH      = 307200  // exact depth for 640 * 480
)(
    input  wire                  clk_w,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr_w,
    input  wire [DATA_WIDTH-1:0] din,
    input  wire                  clk_r,
    input  wire [ADDR_WIDTH-1:0] addr_r,
    output reg  [DATA_WIDTH-1:0] dout
);
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];  // 307,200

    always @(posedge clk_w)
        if (we) mem[addr_w] <= din;

    always @(posedge clk_r)
        dout <= mem[addr_r];

endmodule