# Clock
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_100]
create_clock -period 10.000 -name clk_100 [get_ports clk_100]

# OV7670 pixel clock (~24 MHz)
create_clock -period 41.667 -name cam_pclk [get_ports ov7670_pclk]

# cam_pclk and PLL outputs are fully asynchronous
set_clock_groups -asynchronous \
    -group [get_clocks cam_pclk] \
    -group [get_clocks -include_generated_clocks \
                [get_clocks -of_objects [get_ports clk_100]]]

# config_done crosses from clk_24 to clk_100 via 2-stage synchroniser
# Tell Vivado not to time this path
set_false_path -from [get_clocks clk_out2_clk_wiz_0] -to [get_clocks clk_100]
set_false_path -from [get_clocks clk_100] -to [get_clocks clk_out2_clk_wiz_0]


# Reset and buttons
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports rst_n]


# OV7670 control and SCCB
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports ov7670_sioc]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports ov7670_siod]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports ov7670_xclk]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports ov7670_pwdn]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports ov7670_reset]

set_property PULLUP true [get_ports ov7670_sioc]
set_property PULLUP true [get_ports ov7670_siod]


# OV7670 pixel interface
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports ov7670_vsync]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports ov7670_href]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports ov7670_pclk]

#set_property PULLDOWN true [get_ports ov7670_vsync]
#set_property PULLDOWN true [get_ports ov7670_href]

set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[0]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[1]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[2]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[3]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[4]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[5]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[6]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {ov7670_data[7]}]

# VGA sync
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports vga_hsync]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports vga_vsync]


# VGA red
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVCMOS33} [get_ports {vgaRed[3]}]
set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS33} [get_ports {vgaRed[2]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {vgaRed[1]}]
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS33} [get_ports {vgaRed[0]}]


# VGA green
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS33} [get_ports {vgaGreen[3]}]
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports {vgaGreen[2]}]
set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports {vgaGreen[1]}]
set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS33} [get_ports {vgaGreen[0]}]


# VGA blue
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {vgaBlue[3]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {vgaBlue[2]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {vgaBlue[1]}]
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {vgaBlue[0]}]

set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[0] }];
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[1] }];
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[2] }];
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[3] }];
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[4] }];
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[5] }];
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[6] }];
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[7] }];
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[8] }];
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[9] }];
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[10] }];
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[11] }];
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[12] }];
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[13] }];
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[14] }];
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { bd_leds[15] }];

#set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { LED16_B }]; #IO_L5P_T0_D06_14 Sch=led16_b
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { bd_GREEN_LED }]; #IO_L10P_T1_D14_14 Sch=led16_g
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { bd_RED_LED }]; #IO_L11P_T1_SRCC_14 Sch=led16_r

##PWM Audio Amplifier

set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { bd_AUD_PWM }]
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports { bd_AUD_SD }]

## USB-UART (Nexys4 DDR)
## USB?UART (via FTDI)
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports usb_uart_rxd] ; # UART_TXD_IN
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports usb_uart_txd] ; # UART_RXD_OUT


set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { usb_uart_rxd }]; #IO_L7P_T1_AD6P_35 Sch=uart_txd_in
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { usb_uart_txd }]; #IO_L11N_T1_SRCC_35 
