
# ============================================================
# AXI4 CROSSBAR - ZEDBOARD CONSTRAINT FILE
# Target: Zynq-7000 XC7Z020CLG484-1
# Clock: 100 MHz
# UART: 115200 baud, JA1 Pmod
# LEDs: LD0-LD3
# ============================================================

# ------------------------------------------------------------
# 1. SYSTEM CLOCK - 100 MHz
# ------------------------------------------------------------

set_property PACKAGE_PIN Y9 [get_ports GCLK]
set_property IOSTANDARD LVCMOS33 [get_ports GCLK]

create_clock -period 10.000 -name sys_clk [get_ports GCLK]


# ------------------------------------------------------------
# 2. UART TRANSMITTER - Pmod JA1
# ------------------------------------------------------------

set_property PACKAGE_PIN Y11 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]


# ------------------------------------------------------------
# 3. USER LEDS - ZEDBOARD
# ------------------------------------------------------------

# LED0 - Master 0 transaction completion
set_property PACKAGE_PIN T22 [get_ports {LED[0]}]

# LED1 - Master 1 transaction completion
set_property PACKAGE_PIN T21 [get_ports {LED[1]}]

# LED2 - AXI error indication
set_property PACKAGE_PIN U22 [get_ports {LED[3]}]

# LED3 - Demo active indication
set_property PACKAGE_PIN U21 [get_ports {LED[2]}]


# ------------------------------------------------------------
# 4. LED I/O STANDARD
# ------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]


# ============================================================
# END OF CONSTRAINT FILE
# ============================================================
