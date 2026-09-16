###############################################################################
# EDGE Artix-7 FPGA Development Board
# FPGA: XC7A35T-1FTG256
# Top module: top
###############################################################################

###############################################################################
# 50 MHz onboard oscillator
###############################################################################

set_property PACKAGE_PIN N11 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock -name sys_clk -period 20.000 -waveform {0.000 10.000} \
    [get_ports clk]


###############################################################################
# Reset push button
# EDGE Artix-7 push buttons are active-high when pressed
###############################################################################

set_property PACKAGE_PIN K13 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PULLDOWN true [get_ports rst]