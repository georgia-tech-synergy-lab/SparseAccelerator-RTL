
#Note. Go through these lines below and search online for what they mean.
#L I N E     B Y     L I N E.
#Yes its boring, but you'll only have to do this once if you do it right.



#=============================================================================#
#                                Configuration                                #
#=============================================================================#

# Get configuration settings
source configuration.tcl 

#Find out what the "file" lead-in is doing here...  
file mkdir ./$results
file mkdir ./$reports

#=============================================================================#
#                           Read technology library                           #
#=============================================================================#
source -echo -verbose ./library.tcl

#=============================================================================#
#                               Read design RTL                               #
#=============================================================================#
source -echo -verbose ./read.tcl
#ungroup sm0/s*
#=============================================================================#
#                           Set design constraints                            #
#=============================================================================#
source -echo -verbose ./constraints.tcl

#=============================================================================#
#              Set operating conditions & wire-load models                    #
#=============================================================================#

# Set operating conditions
set_operating_conditions -max $LIB_WC_OPCON -max_library $LIB_WC_NAME \
                         -min $LIB_BC_OPCON -min_library $LIB_BC_NAME

#=============================================================================#
#                                Synthesize                                   #
#=============================================================================#

# Prevent assignment statements in the **Verilog netlist.**
set_fix_multiple_port_nets -all -buffer_constants

# Run topdown synthesis
current_design $TOPLEVEL

# Set the compilation options
if {$DC_FLATTEN} {
   set_flatten true -effort $DC_FLATTEN_EFFORT
}
if {$DC_STRUCTURE} {
   set_structure true -timing $DC_STRUCTURE_TIMING -boolean $DC_STRUCTURE_LOGIC
}
if {$DC_PREFER_RUNTIME} {
   compile_prefer_runtime
}
set COMPILE_ARGS [list]
if {$DC_KEEP_HIER} {
   lappend COMPILE_ARGS "-no_autoungroup"
}
if {$DC_REG_RETIME} {
   set_optimize_registers -async_transform $DC_REG_RETIME_XFORM \
                          -sync_transform  $DC_REG_RETIME_XFORM
   lappend COMPILE_ARGS "-retime"
}
if {$DC_BOUNDARY_OPTIMIZATION eq 0} {
    lappend COMPILE_ARGS "-no_boundary_optimization"
}
if {$DC_SEQ_OUTPUT_INVERSION eq 0} {
    lappend COMPILE_ARGS "-no_seq_output_inversion"
}
if {$DC_EXACT_MAP} {
    lappend COMPILE_ARGS "-exact_map"
}

#=============================================================================#
#                            Synthesis                                        #
#=============================================================================#

#   Check for design errors
check_design -summary
check_design > "./$reports/check_design.rpt"

# Compile, first pass
eval compile_ultra $COMPILE_ARGS


# Prepare to optionally compile second pass for incremental compile or clock gating
set INCR_COMPILE_ARGS [list]
if {$DC_COMPILE_ADDITIONAL} {
     lappend INCR_COMPILE_ARGS "-incremental"
    }
    
if {$DC_CLK_GATING} {

lappend INCR_COMPILE_ARGS "-gate_clock"
lappend INCR_COMPILE_ARGS "-no_autoungroup"

set_clock_gating_style \
        -sequential_cell latch \
        -control_point before \
        -control_signal scan_enable \
        -minimum_bitwidth 1 \
        -max_fanout 64 \
        -positive_edge_logic {integrated}

#You may want only certain registers of modules to be clock gated. List them here
#Alternatively, you may want to -exclude   instances or -include instances, or even -force_include them instead ...
# set_clock_gating_objects -exclude_instances [get_designs *]

}

if {$DC_COMPILE_ADDITIONAL || $DC_CLK_GATING} {    
    eval compile_ultra $INCR_COMPILE_ARGS
}

check_design

if {$DC_CLK_GATING} {
# clock gating report
    report_clock_gating -style > "reports/cg.rpt"
    report_clock_gating_check -significant_digits 3 >> "reports/cg.rpt"
    report_clock_gating -structure >> "reports/cg.rpt"
}


# Perform any custom hold fixing. This is almost never done in the synthesis phase
# unless of course, you know you have lots of regular, known shift register structures
# in which case you can proceed to run a limited hold-fix effort
#source hold_fixing.tcl

#=============================================================================#
#                            Reports generation                               #
#=============================================================================#
# You're almost there. Deceptively though, this is the tallest hill you need to cross. 
# Take the time to look through all the reports to understand them.
# Then open the log and review warnings and errors. grep (and especially egrep) will be 
# handy for this. 
# What is the difference between the fullpath and the regular reports
report_constraints -all_violators -verbose > "./$reports/constraints.rpt"
report_timing -path end -derate  -delay max -max_paths 200 -nworst 2 > "./$reports/timing.max.rpt"
report_timing -path full -derate -delay max -max_paths 5   -nworst 2 > "./$reports/timing.max.fullpath.rpt"
report_timing -path end  -derate -delay min -max_paths 200 -nworst 2 > "./$reports/timing.min.rpt"
report_timing -path full -derate -delay min -max_paths 5   -nworst 2 > "./$reports/timing.min.fullpath.rpt"
report_area -physical -hier -nosplit   > "./$reports/area.rpt"
report_power -hier -nosplit            > "./$reports/power.hier.rpt"
report_power -verbose -nosplit         > "./$reports/power.rpt"
report_congestion                      > "./$reports/congestion.rpt"
report_qor                             > "./$reports/qor.rpt"

# Add NAND2 size equivalent report to the area report file
current_design $TOPLEVEL
if {[info exists NAND2_NAME]} {
    set nand2_area [get_attribute [get_lib_cell $LIB_WC_NAME/$NAND2_NAME] area]
    redirect -variable area {report_area}
    regexp {Total cell area:\s+([^\n]+)\n} $area whole_match area
    set nand2_eq [expr $area/$nand2_area]
    set fp [open "./$reports/area.rpt" a]
    puts $fp ""
    puts $fp "NAND2 equivalent cell area: $nand2_eq"
    close $fp
    puts ""
    puts "      ======================================================="
    puts "     |                       AREA SUMMARY                    "
    puts "     |-------------------------------------------------------"
    puts "     |"
    puts "     |    $NAND2_NAME cell gate area: $nand2_area"
    puts "     |"
    puts "     |    Total Area                : $area"
    puts "     |    NAND2 equivalent cell area: $nand2_eq"
    puts "     |"
    puts "      ======================================================="
    puts ""
}

#=============================================================================#
#          Export gate level netlist, final DDC file and Test protocol          #
#=============================================================================#
current_design $TOPLEVEL


#Defining name rule. Avoiding bit blasting (A naming scheme where the buses are broken up and named as individual wires. 
#Case insensitive naming will be CRITICAL later on when you eventually go through synthesis, APR and then run LVS through Calibre
#You may recall that spice and Calibre are case insensitive in nature. Therefore, if you have 2 nets in a design named n90 and N90,
#They are different in verilog simulation and as far as SAPR is concerned. however, when you run LVS on them the LVS tool views the
#cdl file with n90 and N900 as the same net and considers them shorted in schematic. They are of course different wire connections in 
#layout so the layout is actually fine. Still LVS determines that n90 and n900 are shorted in the schematic but not in layout ==> LVS failure.
#Avoid this by telling the tool that you don't care about case. That way all nets have different names regardless of case.
#Next apply name change to all elements in the hierarchy
define_name_rules verilog  -add_dummy_nets  -case_insensitive
change_name -rules verilog -hierarchy

write -hierarchy -format verilog -output "./$results/$TOPLEVEL.syn.v"
write -hierarchy -format ddc     -output "./$results/$TOPLEVEL.ddc"

#The sdc, or the Standard Design Constraints summarize all the constraints you have put on the design into a single file.
#This file will be fed to the APR tool so you don't have to go create every single constraint all over again.
#The SDF is the standard delay format. Open the file and look at it. It encapsulates delays for every cell in the design
#based on the drive strength, fanout (loading) and even estimated wire load. When you include the sdf file, you are able to
#simulate your netlist with estimates of each gate delay in your design. The SDF will also include setup and hold checks for each flip flop in your design.
#When you run a verilog simulation of your synthesized netlist WITH sdf, you'll see that signals are delayed, and if you fail timing, you'll get errors reported
#on stdout, as well as in the waveform viewer!
# === dump other design files (sdc, db, sdf)
write_sdc                               "./$results/$TOPLEVEL.sdc"
write -h $TOPLEVEL -output              "./$results/$TOPLEVEL.db"
write_sdf -context verilog -version 1.0 "./$results/$TOPLEVEL.sdf"


#This last command is VERY USEFUL. It contains a summary of all the messages (errors/warnings/information) that you encountered in your design.
#All errors are problematic. Some warnings are problematic. You have to inspect them and clean them up before you can declare you have built a clean flow.
if {[check_error -verbose] != 0} { echo "There was an error somewhere!" }
print_message_info

exit



