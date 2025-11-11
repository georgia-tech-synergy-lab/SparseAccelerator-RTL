SHELL := /bin/bash
TOPLEVEL=fp32_adder_tb
SRC_VERILOG=../../accelerator


.DEFAULT_GOAL := vcs

# Move all the verilog files from the source directory over to this simulation directory
link_src:
	find $(SRC_VERILOG) -name '${TOPLEVEL}.include' -exec ln -s -f {} ';'
	xargs -a ${TOPLEVEL}.include -I filename echo filename | awk '{print substr($$0,3)}' | xargs -I {} find ../../accelerator -name {} | xargs -I {} ln -s -f {}

vcs: link_src
	vcs -f $(TOPLEVEL).include +v2k -R +lint=all -sverilog -full64 \
		-timescale=1ns/10ps -debug_acc+pp+dmptf -debug_region+cell+encrypt \
		-debug_access -l $(TOPLEVEL).log +vpdfile+./$(TOPLEVEL).vpd


wipe:
	rm -rf $(TOPLEVEL).include
	rm -rf alib-52
	rm -rf $(TOPLEVEL)
	rm -rf simv.daidir
	rm -rf DVEfiles
	rm -rf *.log
	rm -rf *.vpd
	rm -rf ucli.key
	rm -rf default.svf
	rm -rf simv
	rm -rf *.sv *.v *.svh
	rm -rf csrc
	rm -rf src
	rm -rf *.py
	rm -rf *.include

clean:
	rm -rf DVEfiles
	rm -rf *.log
	rm -rf *.vpd
	rm -rf ucli.key
	rm -rf alib-52
	rm -rf $(TOPLEVEL)
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf simv
