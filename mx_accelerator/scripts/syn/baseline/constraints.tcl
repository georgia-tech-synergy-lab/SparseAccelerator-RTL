##############################################################################
#                                                                            #
#       SETTING CONSTRINTS AND DEFINING CLOCKS                              #
#                                                                            #
##############################################################################
# Get configuration settings
source configuration.tcl

#Units are in ns.
set CLOCK_PERIOD 2.3; #  100MHz

#Create a clock that will establish the context needed for timing.
#All timing  constraints are provided relative to a clock.Your 
#design will typically have a clock but even if you were building
#a purely combinational module, you'd still need to define a clock just
#so that you could give timing constraints to the tool. If you have 
#an actual clock in your design though, you MUST specify it's port name.

create_clock -name "clk"    \
    -period   "$CLOCK_PERIOD"                        \
    -waveform "0 [expr $CLOCK_PERIOD*0.5]"             \
    [get_ports i_clk]

#Your synthesis tool will automatically buffer nets if it sees
#that they are driving a large capacitance. E.g. clocks, reset pins
#Some nets need buffer trees and clock trees. However, these trees
#only make sense in the context of physical design where placement
#and wire capacitances are needed to make these decisions.
#That information is only available in APR - synthesis stays out of it
#To prevent synthesis from interefering in nets that will be taken care 
#of in APR, you just set them to "ideal". There are multiple ways to 
#specify the clocks/nets you want. E.g. 
# set_ideal_network all_clocks. 
# Also, all inputs and outputs will have the same net name as their pin
# so you don't have to [get_nets -of_objects [get_ports i_rst]]. 
set_ideal_network [get_nets -of_objects [get_ports i_clk]] 
set_ideal_network [get_nets -of_objects [get_ports i_async_rst]]

#set_dont_touch_network [get_nets [list phi phi_bar update capture reset]] 
# set_ideal_network [get_nets [list phi phi_bar update capture reset]] -no_propagate

##############################################################################
#                                                                            #
#                          CREATE PATH GROUPS                                #
#                                                                            #
##############################################################################
#These will be handy later when looking at timing paths.
#The first sets all paths going to outputs as REGOUT paths
#The second groups all paths coming into the design. Notice that
#the clock was removed from the input list because the clock pin is the
#yardstick used for timing. All nets (except clk of course) are timed to
#the clock.
#The third groups is all direct input to output paths (no registers in the
#middle. Those are called feedthroughs.
group_path -name REGOUT      -to   [all_outputs]
group_path -name REGIN       -from [remove_from_collection [all_inputs] [get_ports {i_clk}]]
group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] [get_ports  {i_clk}]] -to [all_outputs]


##############################################################################
#                                                                            #
#             TIMING DERATE AND RECONVERGENCE PESSIMISM REMOVAL		         #
#                                                                            #
##############################################################################
# Set setup/hold derating factors. 20%. 
# -clk ensures application of derate only to clk paths. 
# This will be applied to both setup and hold paths (see definition of set_timing_derate)
# If you want the part to really not end up faster than you built it for, will likely have to relax cycle time.
set_timing_derate -early 0.8
set_timing_derate -late  1.2  

#Avoid tracking entire early and late paths altogether. 
#That is excessive. Remoe that pessimism.
set timing_remove_clock_reconvergence_pessimism true



##############################################################################
#                                                                            #
#                          BOUNDARY TIMINGS                                  #
#                                                                            #
##############################################################################

#==========================#
#          GLOBAL          #
#==========================#
#Set critical range sets the range (in ns) within the critical path delay for which the tool will perform timing optimization. By default, critical range is set to 0.0. In other words, the tool will actually only try to fix all critical paths *with negative slack* that are of delay T_critical and (T_critical - critical_range). For example, if your worst negative slack (WNS) is 3ns, and your critical range is 2, only paths that are of negative slack of 1-3ns will be fixed. Paths at 0.99ns of slack will not be touched. If meeting timing targets is a major priority, you need to set a critical range that is greater than the WNS in your design. This does NOT mean that the design will not try to achieve positive timing slack if you have a design with multiple paths that fail timing and that are not within the critical range. Synthesis simply reserves costly optimizations for paths within the critical_range of the critical path 
set_critical_range 0.05 $current_design

#==========================#
#          CLOCK           #
#==========================#
set_clock_uncertainty -setup $SETUP_SKEW clk
set_clock_uncertainty -hold $HOLD_SKEW clk
set_clock_gating_check -setup $GATER_SETUP -hold $GATER_HOLD clk
set_clock_transition $CLK_TRANSITION_LIMIT [get_clocks]
set_fix_hold [get_clocks]

#Yes, you actually have to tell the tool to prioritize hold violation issues at all cost.
set_cost_priority {min_delay max_transition max_delay max_fanout max_capacitance}
#set_min_delay 0.1 -from [get_cell rk0/random_key_reg*]

#==========================#
#      OUTPUT PORTS        #
#==========================#
set_max_transition $SIGNAL_TRANSITION_LIMIT [get_designs $DESIGN]
set_max_fanout 6 $DESIGN

#==========================#
#      OUTPUT PORTS        #
#==========================#
# Review what set_output_delay does
# Find out what set_load does
set_output_delay $OUTPUT_DELAY -clock clk [all_outputs]
set_load [load_of tcbn65gplustc/INVD8/I] [all_outputs]

#=========================#
#       INPUT PORTS       #
#=========================#
#Review what set_input_delay means.
#Find out what set_driving_cell does
set_input_delay $INPUT_DELAY -clock clk [remove_from_collection [all_inputs] [get_ports {i_clk}]]
set_driving_cell -lib_cell INVD1 [get_ports [all_inputs]]

#=========================#
# SET_DONT_USE DIRECTIVES #
#=========================#
#This file has commented set_dont_use statements for your reference.
source set_dont_use.tcl

#===============#
# FALSE PATHS   #
#===============#
# The following signals are internaly synchronized to
# the clock domain and can be set as false path.
# In general BE V.E.R.Y CAREFUL when you use false paths
# You're effectively telling the tool that you don't care about potential hold or setup violations 
# pertaining to that path. This is a very nice way of getting an output that meets timing and even 
# __simulates__ correctly, but will fail in silicon.

#Some examples below
#set_false_path -through [get_pins trng_ns_0/reset_*]
#set_false_path -to clk_pad_out
# set_false_path -from nmi
