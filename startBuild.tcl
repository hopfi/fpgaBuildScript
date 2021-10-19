# Start of script

# The following settings are necessary:
# Environment Variable SRC_DIR : must be pointing to the root path where the source files are located
# Environment Variable WORK_DIR : must be pointing to the desired location for your working directory
# Environment Variable Path must include the Xilinx Install Directory, if Tool ist invoked from batch mode
#
puts "##################################################################"
puts "#          Setting up Vivado Environment for Simulation          #"
puts "##################################################################"

global env

#vivado -source $env:SRC_DIR/fpgaBuildScripts/startBuild.tcl -tclargs vhdl/weatherstation
#vivado -source %SRC_DIR%/fpgaBuildScripts/startBuild.tcl -tclargs vhdl/generic/simple_ethernet
#vivado -source %SRC_DIR%/fpgaBuildScripts/buildProject.tcl -tclargs vhdl/spu/top_module
#vivado -source %SRC_DIR%/fpgaBuildScripts/startBuild.tcl -tclargs vhdl\weatherstation\top_module
#quartus_sh -t %SRC_DIR%/fpgaBuildScripts/startBuild.tcl vhdl/weatherstation/top_module
#quartus_sh -t %SRC_DIR%/fpgaBuildScripts/buildProject.tcl vhdl/spu/top_module
#quartus_sh -t $env:SRC_DIR\fpgaBuildScripts\startBuild.tcl vhdl/weatherstation

set relModulePath [lindex $argv 0]
puts $relModulePath

## Check Directories
if {[info exists env(SRC_DIR)]} {
    puts "\[BS-Info\] The SRC_DIR path environment variable is $env(SRC_DIR) "
    set srcDir $env(SRC_DIR)
} else { 
    error "" "\[BS-Error\] No SRC_DIR path environment variable exists " 1
}

if {[info exists env(WORK_DIR)]} {
    puts "\[BS-Info\] The WORK_DIR path environment variable is $env(WORK_DIR) "
    set workDir $env(WORK_DIR)
} else { 
    error "" "\[BS-Error\] No WORK_DIR path environment variable exists " 2
}

## Add required packages
package require json
source $srcDir/fpgaBuildScripts/fpgaPrjLib.tcl

## Start project generation process
set prjCfg [readJSON $relModulePath]
#checkConfig $prjCfg


## Extract information to decide which flow should be chosen
set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]

if { $vendor == "xilinx" } {
    sendMessage $vendor "Info" "Build_Script-0001" "Workflow for Vendor Xilinx is set."

    ## Check for correct Vivado version
    set actualVivadoVersion [expr ([version -short])]
    set expectedVivadoVersion [dict get [dict get [dict get $prjCfg projectConfig] xilinx] vivadoVersion]

    if { $expectedVivadoVersion != $actualVivadoVersion } {
        sendMessage $vendor "Error" "Build_Script-0801" "Wrong Vivado version! Current Vivado verison $actualVivadoVersion does not match with build script version $expectedVivadoVersion"
    } else {
        createVivadoProject $relModulePath $prjCfg
    }

} elseif { $vendor == "intel" } {

    post_message -type info "\[Build_Script-0002\] Workflow for Vendor Intel is set."

    ## Check for correct Quartus version
    #set actualQuartusVersion [expr ([version -short])]
    #set expectedQuartusVersion [dict get [dict get [dict get $prjCfg projectConfig] intel] quartusVersion]

    #if { $expectedQuartusVersion != $actualQuartusVersion } {
    #    sendMessage $vendor "Error" "Build_Script-0802" "Wrong Quartus version! Current Quartus verison $actualQuartusVersion does not match with build script version $expectedQuartusVersion"
    #} else {
        createQuartusProject $relModulePath $prjCfg
    #}

} else {
    sendMessage $vendor "Error" "Build_Script-0804" "Choose valid vendor workflow!"
}