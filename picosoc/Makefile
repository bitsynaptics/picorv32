
CROSS=riscv32-unknown-elf-
CFLAGS=

# ---- iCE40 icePie Board ----

icepiesim: icePie_tb.vvp icePie_fw.hex
	vvp -N $< +firmware=icePie_fw.hex

icepiesynsim: icePie_syn_tb.vvp icePie_fw.hex
	vvp -N $< +firmware=icePie_fw.hex

icePie.json: icePie.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v ../picorv32.v
	yosys -ql icePie.log -p 'synth_ice40 -dsp -top icePie -json icePie.json' $^

icePie_tb.vvp: icePie_tb.v icePie.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v ../picorv32.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS

icePie_syn_tb.vvp: icePie_tb.v icePie_syn.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS

icePie_syn.v: icePie.json
	yosys -p 'read_json icePie.json; write_verilog icePie_syn.v'

icePie.asc: icePie.pcf icePie.json
	nextpnr-ice40 --freq 13 --up5k --package sg48 --asc icePie.asc --pcf icePie.pcf --json icePie.json

icePie.bin: icePie.asc
	icetime -d up5k -c 12 -mtr icePie.rpt icePie.asc
	icepack icePie.asc icePie.bin

icepieprog: icePie.bin icePie_fw.bin
	iceprog icePie.bin
	iceprog -o 1M icePie_fw.bin

icepieprog_fw: icePie_fw.bin
	iceprog -o 1M icePie_fw.bin

icePie_sections.lds: sections.lds
	$(CROSS)cpp -P -DICEPIE -o $@ $^

icePie_fw.elf: icePie_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DICEPIE -mabi=ilp32 -march=rv32ic -Wl,-Bstatic,-T,icePie_sections.lds,--strip-debug -ffreestanding -nostdlib -o icePie_fw.elf start.s firmware.c

icePie_fw.hex: icePie_fw.elf
	$(CROSS)objcopy -O verilog icePie_fw.elf icePie_fw.hex

icePie_fw.bin: icePie_fw.elf
	$(CROSS)objcopy -O binary icePie_fw.elf icePie_fw.bin

# ---- Testbench for SPI Flash Model ----

spiflash_tb: spiflash_tb.vvp icePie_fw.hex
	vvp -N $< +firmware=icePie_fw.hex

spiflash_tb.vvp: spiflash.v spiflash_tb.v
	iverilog -s testbench -o $@ $^

# ---- ASIC Synthesis Tests ----

cmos.log: spimemio.v simpleuart.v picosoc.v ../picorv32.v
	yosys -l cmos.log -p 'synth -top picosoc; abc -g cmos2; opt -fast; stat' $^

# ---- Clean ----

clean:
	rm -f testbench.vvp testbench.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f icePie_fw.elf icePie_fw.hex icePie_fw.bin
	rm -f icePie.json icePie.log icePie.asc icePie.rpt icePie.bin
	rm -f icePie_syn.v icePie_syn_tb.vvp icePie_tb.vvp

.PHONY: spiflash_tb clean
.PHONY: icepieprog icepieprog_fw icepiesim icepiesynsim
