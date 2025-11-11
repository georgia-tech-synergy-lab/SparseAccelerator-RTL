
##############################################################################
#                                                                            #
#                            SPECIFY LIBRARIES                               #
#                                                                            #
##############################################################################
#This file contains commands that specifies the libraries and paths that synthesis needs defined
#in order to build and link your design. Variables here are defined previously in the configuration.tcl
#file, so we source that file first...
# Get configuration settings
source configuration.tcl 

# Notice that some variables are set using "set" and others are set using "set_app_var".
# set_app_var is used to set variables that are *directly* referenced by the tool. The others are 
# variables you set for convenience or programming.

# Set library search path
set_app_var search_path [concat $search_path $ADDITIONAL_SEARCH_PATHS]

# Set the target libraries
set_app_var target_library "$TARGET_LIBS $ADDITIONAL_TARGET_LIBS"

# Set symbol library, link path, and link libs. As I mentioned, it makes sense for your link library
# to have the TARGET_LIB and the ADDITIONAL_TARGET_LIBS provided to it.
set_app_var link_path [list "*" $TARGET_LIBS]
set_app_var link_library "* $TARGET_LIBS $SYNOPSYS_SYNTHETIC_LIB"

# Note: Unlike python, spaces before and after braces matter in tcl :)
# This conditional below adds the ADDITIONAL_TARGET_LIBS if they are defined.
if {[llength $ADDITIONAL_TARGET_LIBS] > 0} {
   set_app_var target_library "$target_library $ADDITIONAL_TARGET_LIBS"
   set_app_var link_path "$link_path $ADDITIONAL_TARGET_LIBS"
   set_app_var link_library "$link_library $ADDITIONAL_TARGET_LIBS"
}

set_app_var symbol_library $SYMBOL_LIB

# Create a MW design lib and attach the reference lib and techfiles
# if {[file isdirectory $DESIGN_MW_LIB_NAME]} {
   # file delete -force $DESIGN_MW_LIB_NAME
#}

extend_mw_layers
set ref_libs "$MW_REFERENCE_LIBS $MW_ADDITIONAL_REFERENCE_LIBS"

exec rm -rf $DESIGN_MW_LIB_NAME
create_mw_lib $DESIGN_MW_LIB_NAME \
   -technology $MW_TECHFILE_PATH/$MW_TECHFILE \
   -mw_reference_library $ref_libs 

#create_mw_lib $DESIGN_MW_LIB_NAME \
#   -technology $MW_TECHFILE_PATH/$MW_TECHFILE \
#   -mw_reference_library [list $MW_REFERENCE_LIBS ] 


open_mw_lib $DESIGN_MW_LIB_NAME

# Set up tlu_plus files (for virtual route and post route extraction)
set_tlu_plus_files \
  -max_tluplus $MW_TLUPLUS_PATH/$MAX_TLUPLUS_FILE \
  -min_tluplus $MW_TLUPLUS_PATH/$MIN_TLUPLUS_FILE \
  -tech2itf_map $MW_TLUPLUS_PATH/$TECH2ITF_MAP_FILE


