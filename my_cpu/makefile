.DELETE_ON_ERROR:

#Sources
SRC=src/*.sv
TESTBENCH=test_bench/*.sv

#Build
BUILD_DIR=build

BUILD_TOP=$(BUILD_DIR)/top.json
BUILD_ASC=$(BUILD_DIR)/top.asc

BUILD_PRG=out.bin
BUILD_PCF=icestick.pcf


#Simulation
SIM_OUT=sim


build : 
		@mkdir build
		@yosys -p "read_verilog -sv $(SRC); synth_ice40 -top core -json $(BUILD_TOP)"
		@nextpnr-ice40	--freq 12 --hx1k --package tq144 --json $(BUILD_TOP) --pcf $(BUILD_PCF) --asc $(BUILD_ASC)
		@icepack	$(BUILD_ASC) $(BUILD_PRG)
		@echo "Done."

burn :
		sudo	openFPGALoader --board ice40_generic $(BUILD_PRG)

sim : 
		@iverilog -Wall -g2012 $(SRC) $(TESTBENCH) -o $(SIM_OUT)
		@echo ""
		@vvp $(SIM_OUT)


clean :
		@rm -rf $(BUILD_DIR)
		@rm -rf $(SIM_OUT)
		@rm -rf *.vcd
		@rm -rf *.bin
		@echo "Done."

