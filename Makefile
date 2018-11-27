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

$(PROJECT).json:$(BINARY_SRC) $(ADDITIONAL_DEPS)
	yosys -p 'synth_ecp5 -json $@ -top top' $(BINARY_SRC)

$(PROJECT).txt:$(PROJECT).json
	nextpnr-ecp5 --85k --lpf $(PROJECT).lpf --json $(PROJECT).json

$(PROJECT).bit: $(PROJECT)_out.config
	ecppack $< $@

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

# formal verification:
formal: formal_blockram formal_proc

formal_blockram: blockram.check
blockram.check: blockram.smt2
	@rm -f $@
	yosys-smtbmc --presat    -s yices -t 15 --dump-vcd blockram.vcd blockram.smt2
	yosys-smtbmc --presat -g -s yices -t 15 --dump-vcd blockram.vcd blockram.smt2
	yosys-smtbmc          -i -s yices -t 15 --dump-vcd blockram.vcd blockram.smt2
	touch $@

formal_proc: proc.check
proc.check: proc.smt2
	@rm -f $@
	yosys-smtbmc             -s yices -t 100 --dump-vcd proc.vcd proc.smt2
	yosys-smtbmc --presat -g -s yices -t 100 --dump-vcd proc.vcd proc.smt2
	yosys-smtbmc          -i -s yices -t 100 --dump-vcd proc.vcd proc.smt2
	touch $@

blockram.smt2: blockram.v
	yosys -ql blockram.yslog -p 'read_verilog -formal blockram.v; prep -top blockram -nordff; write_smt2 -wires blockram.smt2'

proc.smt2: proc.v
	yosys -ql proc.yslog -p 'read_verilog -formal proc.v; prep -top proc -nordff; write_smt2 -wires proc.smt2'

clean:
	rm -f \
	$(BINARY) $(PROJECT).blif $(PROJECT).json $(PROJECT).txt $(SIM_BINARY) $(SIM_VCD) \
	blockram.vcd blockram.smt2 blockram.yslog \
	proc.vcd proc.smt2 proc.yslog \

