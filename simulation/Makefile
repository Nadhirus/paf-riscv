.PHONY : clean all simu compile

TB = DE1_SoC_tb

simu:
	vsim $(TB)

compile:
	vlog +acc +define+SIMULATION $(TB).sv ../src_pipeline/*.sv

work:
	vlib work

# nettoyage 
clean : 
	rm -rf work *~
	rm -f transcript vsim.wlf
