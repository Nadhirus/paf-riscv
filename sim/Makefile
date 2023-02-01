.PHONY : clean all simu compile

TB = DE1_SoC_tb

sim:
	vsim $(TB)

compile:
	vlog +acc +define+SIMULATION $(TB).sv ../rtl/*.sv

work:
	vlib work

clean : 
	rm -rf work *~
	rm -f transcript vsim.wlf
