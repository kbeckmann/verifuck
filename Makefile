PROJECT=verifuck
SRC= \
	baudgen.v \
	blockram.v \
	proc.v \
	rom.v \
	uart_tx.v \
	verifuck.v \

ADDITIONAL_DEPS= \
	test_prog.mem \
	test_ram.mem \

BINARY=$(PROJECT).bin
BINARY_SRC=$(SRC) top.v

SIM_BINARY=$(PROJECT)_tb.out
SIM_SRC=$(SRC) verifuck_tb.v
SIM_VCD=$(PROJECT)_tb.vcd

all:build

$(PROJECT).blif:$(BINARY_SRC) $(ADDITIONAL_DEPS)
	yosys -p "synth_ice40 -blif $(PROJECT).blif" $(BINARY_SRC)

$(PROJECT).txt:$(PROJECT).blif
	arachne-pnr -d 1k -p $(PROJECT).pcf $(PROJECT).blif -o $(PROJECT).txt
	icetime -p $(PROJECT).pcf -d lp1k $(PROJECT).txt

$(BINARY):$(PROJECT).txt
	icepack $(PROJECT).txt $(BINARY)

build:$(BINARY)

flash:$(BINARY)
	iceprog $(BINARY)

flash_program:$(BF_PROGRAM)
	iceprog -o 64k $(BF_PROGRAM)

$(SIM_BINARY):$(SIM_SRC) $(ADDITIONAL_DEPS)
	iverilog -o $(SIM_BINARY) $(SIM_SRC)

sim:$(SIM_BINARY)
	./$(SIM_BINARY)

show:$(SIM_BINARY)
	gtkwave $(PROJECT).gtkw

clean:
	rm -fr $(BINARY) $(PROJECT).blif $(PROJECT).txt $(SIM_BINARY) $(SIM_VCD) dump.vcd
