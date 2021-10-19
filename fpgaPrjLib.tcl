proc sendMessage { vendor severity id msg } {

    if { $vendor == "xilinx" } {

        if { $severity == "Error" } {
            set severity "Error"
        } elseif { $severity == "Critical Warning"} {
            set severity "Critical Warning"
        } elseif { $severity == "Warning"} {
            set severity "Warning"
        } elseif { $severity == "Info" } {
            set severity "Info"
        } elseif { $severity == "Status" } {
            set severity "Status"
        } else {
            common::send_msg_id "BS-000" "Error" "This is a problem with the error handling itself in the 'Build Script'. Maybe its a spelling error."
        }

        common::send_msg_id $id $severity $msg

    } elseif { $vendor == "intel" } {

        if { $severity == "Error" } {
            set severity "Error"
        } elseif { $severity == "Critical Warning"} {
            set severity "Critical Warning"
        } elseif { $severity == "Warning"} {
            set severity "Warning"
        } elseif { $severity == "Info" } {
            set severity "Info"
        } elseif { $severity == "Status" } {
            set severity "Status"
        } else {
            common::send_msg_id "BS-000" "Error" "This is a problem with the error handling itself in the 'Build Script'. Maybe its a spelling error."
        }

        misc::post_message -type $severity "[$id] $msg"
    } elseif { $vendor == "none" } {

        if { $severity == "Error" } {
            set severity "Error"
        } elseif { $severity == "Critical Warning"} {
            set severity "Critical Warning"
        } elseif { $severity == "Warning"} {
            set severity "Warning"
        } elseif { $severity == "Info" } {
            set severity "Info"
        } elseif { $severity == "Status" } {
            set severity "Status"
        } else {
            common::send_msg_id "BS-000" "Error" "This is a problem with the error handling itself in the 'Build Script'. Maybe its a spelling error."
        }

        error "" "\[BS-Error\] Error" 1
    }

    return 0
}


proc readJSON { relModulePath } {

    global srcDir
    global workDir

    puts $srcDir/$relModulePath/cfg/projectConfig.json

    if { [file exists "$srcDir/$relModulePath/cfg/projectConfig.json"] == 1} {
        set fp [open "$srcDir/$relModulePath/cfg/projectConfig.json" r]
        set fileContent [read $fp]
        close $fp

        set prjConfig [::json::json2dict $fileContent]
    } else {
        error "" "\[BS-Error\] No project configuration file found." 1
        set prjConfig 1
    }

    return $prjConfig
}

proc checkProjectConfig { prjCfg } {
    return 0
}

proc addVivadoBD { prjCfg } {
    global srcDir
    global workDir

    sendMessage "xilinx" "Info" "Build_Script-0100" "Block designs will be added to the project."

    set bdDict [dict get [dict get [dict get [dict get $prjCfg projectConfig] xilinx] IPIntegrator] blockDesignFiles]

    foreach {key} [dict get $bdDict designs] {

        set bdScriptPath [dict get $key path]
        set bdName [dict get $key designName]

        if { [file exists $srcDir/$bdScriptPath] == 1 } {

            sendMessage "xilinx" "Info" "Build_Script-0101" "Generating block design '$bdName' from '$srcDir/$bdScriptPath' TCL script."
            source $srcDir/$bdScriptPath

            validate_bd_design

            set bdPath [file dirname [get_property NAME [get_files $bdName.bd]]]
            make_wrapper -files [get_files $bdName.bd] -top
            add_files -norecurse $bdPath/hdl/${bdName}_wrapper.vhd

            close_bd_design [get_bd_designs $bdName]

            sendMessage "xilinx" "Info" "Build_Script-0102" "Added block design '$bdName' with wrapper to project."

        } else {
            sendMessage "xilinx" "Error" "Build_Script-0103" "BD tcl script '$srcDir/$bdScriptPath' does not exist!"
        }
    }

}

proc addVHDLFiles { prjCfg } {
    global srcDir
    global workDir

    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set vhdlStandard [dict get [dict get [dict get $prjCfg projectConfig] general] vhdlStandard]
    set VHDLFilesList [dict get [dict get $prjCfg hdl] vhdl]

    if { $vendor == "xilinx" } {
        if { $vhdlStandard == "2008" } {
            set vhdlStandard "vhdl2008"
        }
    }

    if { $vendor == "xilinx" } {
        sendMessage $vendor "Info" "Build_Script-0200" "VHDL files will be added to project."

        foreach {key} $VHDLFilesList {

            set path [dict get $key path]
            set lib [dict get $key library]

            if { [file exists $srcDir/$path] == 1 } {

                read_vhdl -library $lib -$vhdlStandard $srcDir/$path
                sendMessage $vendor "Info" "Build_Script-0201" "Added '$srcDir/$path' to library '$lib'." 

            } else {
                sendMessage $vendor "Warning" "Build_Script-0202" "VHDL Source file '$srcDir/$path' does not exist!"
            }
        }

    } elseif { $vendor == "intel" } {
        post_message -type info "\[Build_Script-0200\] VHDL files will be added to project."

        foreach {key} $VHDLFilesList {

            set path [dict get $key path]
            set lib [dict get $key library]

            if { [file exists $srcDir/$path] == 1 } {
                
                set_global_assignment -name VHDL_FILE $srcDir/$path -library $lib
                post_message -type info "\[Build_Script-0201\] Added '$srcDir/$path' to library '$lib'."

            } else {
                post_message -type warning "\[Build_Script-0202\] VHDL Source file '$srcDir/$path' does not exist!"
            }
        }

    } else {
        error "" "\[Build_Script-0204\] Specified vendor '$vendor' is not known!" 1
    }

}

proc addSVFiles { prjCfg } {
    global srcDir
    global workDir

    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set svStandard [dict get [dict get [dict get $prjCfg projectConfig] general] svStandard]
    set svFilesList [dict get [dict get $prjCfg hdl] sv]

    sendMessage $vendor "Error" "Build_Script-0300" "Systemverilog is not yet supported."
    sendMessage $vendor "Info" "Build_Script-0301" "Systemverilog files will be added to project."

    if { $vendor == "xilinx" } {
        if { $svStandard == "2008" } {
            set svStandard "sv2008"
        }
    }

    if { $vendor == "xilinx" } {

        foreach {key} $svFilesList {

            set path [dict get $key path]
            set lib [dict get $key library]

            if { [file exists $srcDir/$path] == 1 } {

                read_verilog -library $lib -sv -$svStandard $srcDir/$path
                sendMessage $vendor "Info" "Build_Script-0302" "Added '$srcDir/$path' to library '$lib'."

            } else {
                sendMessage $vendor "Warning" "Build_Script-0303" "SystemVerilog Source file '$srcDir/$path' does not exist!"
            }
        }

    } elseif { $vendor == "intel" } {

        foreach {key} $svFilesList {

            set path [dict get $key path]
            set lib [dict get $key library]

            if { [file exists $srcDir/$path] == 1 } {
                
                set_global_assignment -name SYSTEMVERILOG_FILE $srcDir/$path -library $lib
                sendMessage $vendor "Info" "Build_Script-0302" "Added '$srcDir/$path' to library '$lib'."

            } else {
                sendMessage $vendor "Warning" "Build_Script-0303" "SystemVerilog Source file '$srcDir/$path' does not exist!"
            }
        }

    } else {
        sendMessage $vendor "Error" "Build_Script-0304" "Specified vendor '$vendor' is not known!"
    }

}

proc addConstraintFiles { prjCfg } {
    global srcDir
    global workDir

    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set constraintsDict [dict get $prjCfg constraints]

    if { $vendor == "xilinx"} {
        sendMessage $vendor "Info" "Build_Script-0400" "Constraints files will be added to project"

        foreach {key} [dict get $constraintsDict xilinx] {
            if { [file exists $srcDir/$key] == 1 } {
                read_xdc $srcDir/$key
                sendMessage $vendor "Info" "Build_Script-0401" "Added '$srcDir/$key' to project"
            } else {
                sendMessage $vendor "Warning" "Build_Script-0402" "File '$srcDir/$key' does not exist!"
            }
        }

    } elseif { $vendor == "intel" } {
        post_message -type info "\[Build_Script-0400\] Constraints files will be added to project"
        
        foreach {key} [dict get $constraintsDict intel] {
                
            set constrType [file extension $key]

            if { [file exists $srcDir/$key] == 1 } {
                
                if { $constrType == ".sdc"} {
                    set_global_assignment -name SDC_FILE $srcDir/$key
                    post_message -type info "\[Build_Script-0401\] Added SCD file '$srcDir/$key' to project"
                } elseif { $constrType == ".qsf" } {
                    #set_global_assignment -name QSF_FILE $srcDir/$key
                    source $srcDir/$key
                    post_message -type info "\[Build_Script-0401\] Added QSF file '$srcDir/$key' to project"
                } else {
                    post_message -type warning "\[Build_Script-0501\] File extension of '$key' does not match the expected type!"
                }
                
            } else {
                post_message -type warning "\[Build_Script-0402\] File '$srcDir/$key' does not exist!"
            }
        }
    } else {
        error "" "\[Build_Script-0404\] Specified vendor '$vendor' is not known!" 1
    }

}

proc addVendorIP { prjCfg } {
    global srcDir
    global workDir

    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set ipDict [dict get $prjCfg ip]
    set vivadoVersion [dict get [dict get [dict get $prjCfg projectConfig] xilinx] vivadoVersion]
    set fpgaPart [dict get [dict get [dict get $prjCfg projectConfig] xilinx] fpgaPart]
    set quartusVersion [dict get [dict get [dict get $prjCfg projectConfig] intel] quartusVersion]
    set familyName [dict get [dict get [dict get $prjCfg projectConfig] intel] familyName]
    set deviceName [dict get [dict get [dict get $prjCfg projectConfig] intel] deviceName]


    if { $vendor == "xilinx" } {
        sendMessage $vendor "Info" "Build_Script-0500" "IP files will be added to project."

        set ipList [dict get $ipDict xilinx]

        foreach {key} $ipList {

            set ipPath [dict get $key path]
            set ipName [dict get $key name]

            if { [file exists $srcDir/$ipPath/$vivadoVersion/$fpgaPart/$ipName] == 1 } { 

                read_ip $srcDir/$ipPath/$vivadoVersion/$fpgaPart/$ipName
                sendMessage $vendor "Info" "Build_Script-0501" "Added '$srcDir/$ipPath/$vivadoVersion/$fpgaPart/$ipName' to project."

            } else {
                sendMessage $vendor "Warning" "Build_Script-0502" "IP file '$srcDir/$ipPath/$vivadoVersion/$fpgaPart/$ipName' was not found!"
            }

        }

    } elseif { $vendor == "intel" } {
        post_message -type info "\[Build_Script-0500\] IP files will be added to project."

        set ipList [dict get $ipDict intel]

        foreach {key} $ipList {

            set ipPath [dict get $key path]
            set ipName [dict get $key name]
            set ipType [file extension $ipName]

            if { [file exists $srcDir/$ipPath/$quartusVersion/$deviceName/$ipName] == 1 } { 
            #if { [ file exists $srcDir/$ipPath/$ipName] == 1 }  {}
                if { $ipType == ".qsys"} {
                    set_global_assignment -name QSYS_FILE $srcDir/$ipPath/$quartusVersion/$deviceName/$ipName
                    post_message -type info "\[Build_Script-0502\] Added '$srcDir/$ipPath/$quartusVersion/$deviceName/$ipName' to project."
                } elseif { $ipType == ".qip" } {
                    set_global_assignment -name QIP_FILE $srcDir/$ipPath/$quartusVersion/$deviceName/$ipName
                    post_message -type info "\[Build_Script-0502\] Added '$srcDir/$ipPath/$quartusVersion/$deviceName/$ipName' to project."
                } else {
                    post_message -type warning "\[Build_Script-0501\] File extension of '$ipName' does not match the expected type!"
                }

                
            } else {
                post_message -type warning "\[Build_Script-0503\] IP file '$srcDir/$ipPath/$quartusVersion/$deviceName/$ipName' was not found!"
            }

        }

    } else {
        sendMessage $vendor "Error" "Build_Script-0504" "Specified vendor '$vendor' is not known"
    }

    if { [dict get $ipDict 3rdParty] == "" } {
        puts "\[Build_Script-0505\] No 3rdParty IP found in configuration."
    } else {
        puts "\[Build_Script-0506\] 3rdParty IP found in configuration."
        error "" "\[Build_Script-0507\] Build_Script-0507" "3rdParty' is not supported at the moment!" 1
    }
}

proc createVivadoProject { relModulePath prjCfg } {
    global srcDir
    global workDir

    ## General settings
    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set projectName [dict get [dict get [dict get $prjCfg projectConfig] general] projectName]
    set swProjectName [dict get [dict get [dict get $prjCfg projectConfig] general] swProjectName]
    set topLevelName [dict get [dict get [dict get $prjCfg projectConfig] general] topLevelName]
    set testbenchName [dict get [dict get [dict get $prjCfg projectConfig] general] testbenchName]
    set runImpl [dict get [dict get [dict get $prjCfg projectConfig] general] runImpl]

    ## Vivado specific settings
    set fpgaPart [dict get [dict get [dict get $prjCfg projectConfig] xilinx] fpgaPart]
    set vivadoVersion [dict get [dict get [dict get $prjCfg projectConfig] xilinx] vivadoVersion]
    set implStrat [dict get [dict get [dict get $prjCfg projectConfig] xilinx] implStrat]
    set IPPackager [dict get [dict get [dict get $prjCfg projectConfig] xilinx] IPPackager]
    set configFile [dict get $IPPackager configFile]
    set genereateIP [dict get $IPPackager genereateIP]
    set synthCheck [dict get $IPPackager synthCheck]

    # Create the temporary folder in WORK_DIR
    file mkdir $workDir/Vivado/$relModulePath/$swProjectName

    # create a project at the location of the workDir, -force: overwrite existing project
    create_project $swProjectName $workDir/Vivado/$relModulePath/$swProjectName -part $fpgaPart -force
    config_webtalk -user off

    # Some usefull settings
    set_property target_language VHDL [current_project]
    set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

    # Disable automatic hierarchy update by vivado - we tell vivado which is the toplevel module! All/None
    set_property source_mgmt_mode All [current_project]

    # Add source files
    addVHDLFiles $prjCfg
    addConstraintFiles $prjCfg
    addVendorIP $prjCfg

    # Create Block Design
    addVivadoBD $prjCfg

    # Set toplevel entity for synthesis and simulation
    set_property top $topLevelName [current_fileset]
    set_property top $testbenchName [get_filesets sim_1]

    # Configure synthesis settings
    set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

    update_compile_order -fileset sources_1

    # Decide if project is a module project or project project
    if { $runImpl == true } {

        # Automatically run all necessary process steps for bitstream generation if enabled
        sendMessage $vendor "Info" "Build_Script-0600" "Synthesising design and generating bitstream ..."

        # Add project specific information to generics
        addVersionInfo $prjCfg

        if { $implStrat == "" } {
            sendMessage $vendor "Info" "Build_Script-0601" "Running default implementation strategy."

            #launch_runs synth_1 -jobs 4
            #wait_on_run synth_1
            #launch_runs impl_1
            #wait_on_run impl_1
            #launch_runs impl_1 -to_step write_bitstream -jobs 4
            #wait_on_run impl_1

            launch_runs impl_1 -to_step write_bitstream -jobs 4
            wait_on_run impl_1


        } else {
            if { [file exists "$srcDir/$implStrat"] == 1} {
                source $srcDir/$implStrat
            } else {
                sendMessage $vendor "Error" "Build_Script-0602" "TCL script '$srcDir/$implStrat' with implementation run not found."
            }
        }

        set actualImplStatus [get_property STATUS [get_runs impl_1]]
        set expectedImplStatus "write_bitstream Complete!"
        if { $actualImplStatus == $expectedImplStatus } {
            
            sendMessage $vendor "Info" "Build_Script-0603" "Done generating bitstream!"
            open_run impl_1

            sendMessage $vendor "Info" "Build_Script-0604" "Writing reports ..."
            file copy -force $workDir/Vivado/$projectName/$swProjectName/${swProjectName}.runs/synth_1/${topLevelName}.vds    $srcDir/projects/$projectName/bitstream/synth_report.txt
            report_timing_summary -file $srcDir/projects/$projectName/bitstream/timing_report.txt
            report_utilization -file $srcDir/projects/$projectName/bitstream/utilization_report.txt
            file copy -force $workDir/Vivado/$projectName/$swProjectName/${swProjectName}.runs/impl_1/${topLevelName}.vdi    $srcDir/projects/${projectName}/bitstream/impl_report.txt
            file copy -force $workDir/Vivado/$projectName/$swProjectName/${swProjectName}.runs/impl_1/${topLevelName}_io_placed.rpt    $srcDir/projects/${projectName}/bitstream/io_report.txt
            
            sendMessage $vendor "Info" "Build_Script-0604" "Writing output files ..."
            writeOutputFiles $relModulePath $prjCfg
            
            close_design
            sendMessage $vendor "Info" "Build_Script-0607" "Automatic implementation run done."

        } else {
            sendMessage $vendor "Error" "Build_Script-0608" "An error occured during bitstream generation. Check log for details."
        }

    } else {

        # Package Project
        if { $genereateIP == true } {

            if { $synthCheck == true } {
                sendMessage $vendor "Info" "Build_Script-0609" "Synthesize design to check for errors ..."
                reset_run synth_1
                launch_runs synth_1 -jobs 4
                wait_on_run synth_1
                sendMessage $vendor "Info" "Build_Script-0610" "Synthesis done! Now package project and create IP ..."
            } else {
                sendMessage $vendor "Info" "Build_Script-0611" "Package project to IP ..."
            }

            if { [file exists "$srcDir/$IPPackageConfigPath"] == 1} {
                source $srcDir/$IPPackageConfigPath
            } else {
                sendMessage $vendor "Error" "Build_Script-0612" "File packageCustomIP.tcl not found."
            }

            sendMessage $vendor "Info" "Build_Script-0613" " IP core created!"
        }

    }
    sendMessage $vendor "Info" "Build_Script-0600" "Build script finished."
    #close_project
    #exit

    return 0
}

proc createQuartusProject { relModulePath prjCfg } {
    global srcDir
    global workDir

    ## General settings
    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set projectName [dict get [dict get [dict get $prjCfg projectConfig] general] projectName]
    set swProjectName [dict get [dict get [dict get $prjCfg projectConfig] general] swProjectName]
    set topLevelName [dict get [dict get [dict get $prjCfg projectConfig] general] topLevelName]
    set testbenchName [dict get [dict get [dict get $prjCfg projectConfig] general] testbenchName]
    set runImpl [dict get [dict get [dict get $prjCfg projectConfig] general] runImpl]

    ## Add Quartus code

    ## Quartus specific settings
    set familyName [dict get [dict get [dict get $prjCfg projectConfig] intel] familyName]
    set deviceName [dict get [dict get [dict get $prjCfg projectConfig] intel] deviceName]
    set quartusVersion [dict get [dict get [dict get $prjCfg projectConfig] intel] quartusVersion]
    set implStrat [dict get [dict get [dict get $prjCfg projectConfig] intel] implStrat]
    # TODO: Implement Intel IP Packager
    set genereateIP [dict get [dict get [dict get $prjCfg projectConfig] intel] genereateIP]
    set synthCheck [dict get [dict get [dict get $prjCfg projectConfig] intel] synthCheck]

    # Create the temporary folder in WORK_DIR
    file mkdir $workDir/Intel/$relModulePath/$swProjectName

    ## Create new project
    project_new $workDir/Intel/$relModulePath/$swProjectName -overwrite
    export_assignments 
    set_global_assignment -name PROJECT_OUTPUT_DIRECTORY $workDir/Intel/$relModulePath/$swProjectName
    set_global_assignment -name family $familyName
    set_global_assignment -name device $deviceName

    # Some usefull settings
    set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008

    ## Add source files
    addVHDLFiles $prjCfg
    addConstraintFiles $prjCfg
    addVendorIP $prjCfg

    # Create Block Design
    #addVivadoBD $prjCfg

    # Set toplevel entity for synthesis and simulation
    set_global_assignment -name TOP_LEVEL_ENTITY $topLevelName
    #set_property top $testbenchName [get_filesets sim_1]

    # Configure synthesis settings
    #set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

    #update_compile_order -fileset sources_1

    # Decide if project is a module project or project project
    if { $runImpl == true } {

        # Automatically run all necessary process steps for bitstream generation if enabled
        sendMessage $vendor "Info" "Build_Script-0600" "Synthesising design and generating bitstream ..."

        # Add project specific information to generics
        addVersionInfo $prjCfg

        if { $implStrat == "" } {
            sendMessage $vendor "Info" "Build_Script-0601" "Running default implementation strategy."

            #launch_runs synth_1 -jobs 4
            #wait_on_run synth_1
            #launch_runs impl_1
            #wait_on_run impl_1
            #launch_runs impl_1 -to_step write_bitstream -jobs 4
            #wait_on_run impl_1

            launch_runs impl_1 -to_step write_bitstream -jobs 4
            wait_on_run impl_1


        } else {
            if { [file exists "$srcDir/$implStrat"] == 1} {
                source $srcDir/$implStrat
            } else {
                sendMessage $vendor "Error" "Build_Script-0602" "TCL script '$srcDir/$implStrat' with implementation run not found."
            }
        }

        set actualImplStatus [get_property STATUS [get_runs impl_1]]
        set expectedImplStatus "write_bitstream Complete!"
        if { $actualImplStatus == $expectedImplStatus } {
            
            sendMessage $vendor "Info" "Build_Script-0603" "Done generating bitstream!"
            sendMessage $vendor "Info" "Build_Script-0604" "Writing reports ..."
            open_run impl_1
            report_timing_summary -file $srcDir/projects/$projectName/bitstream/timing_report.txt
            report_utilization -file $srcDir/projects/$projectName/bitstream/utilization_report.txt
            close_design
            sendMessage $vendor "Info" "Build_Script-0605" "Done writing reports!"

            # Copy generated Bitstream files to projects/$projectName/Bitstream/ folder and rename them to $(outFiles).*
            sendMessage $vendor "Info" "Build_Script-0606" "Moving output files to bitstream folder."
            writeOutputFiles $relModulePath $prjCfg

            sendMessage $vendor "" "Build_Script-0607" "Automatic implementation run done."

        } else {
            sendMessage $vendor "Error" "Build_Script-0608" "An error occured during bitstream generation. Check log for details."
        }

    } else {

        # Package Project
        if { $genereateIP == true } {

            if { $synthCheck == true } {
                sendMessage $vendor "Info" "Build_Script-0609" "Synthesize design to check for errors ..."
                reset_run synth_1
                launch_runs synth_1 -jobs 4
                wait_on_run synth_1
                sendMessage $vendor "Info" "Build_Script-0610" "Synthesis done! Now package project and create IP ..."
            } else {
                sendMessage $vendor "Info" "Build_Script-0611" "Package project to IP ..."
            }

            if { [file exists "$srcDir/$IPPackageConfigPath"] == 1} {
                source $srcDir/$IPPackageConfigPath
            } else {
                sendMessage $vendor "Error" "Build_Script-0612" "File packageCustomIP.tcl not found."
            }

            sendMessage $vendor "Info" "Build_Script-0613" " IP core created!"
        }

    }
    post_message -type info "\[Build_Script-0600\] Build script finished."
    #project_close




#    Example Tcl Script
#    ----------------------
#    #--------------------------------------------------------------#
#    # 
#    # The following Tcl script instructs the Quartus Prime 
#    # software to create a project (or open it if it already 
#    # exists), make global assignments for family and device, 
#    # and include timing and location settings.
#    #
#    # There are two ways to compile a project after making 
#    # assignments. The first method, and the easiest, is 
#    # to use the ::quartus::flow package and call the Tcl 
#    # command "execute_flow -compile".
#    # 
#    # The second method is to call the Tcl command 
#    # "export_assignments" to write assignment changes to the 
#    # Quartus Prime Settings File (.qsf) before compiling the 
#    # design. Calling "export_assignments" beforehand is 
#    # necessary so that the command-line executables detect 
#    # the assignment changes.
#    # 
#    # After compilation, with either method, the script then 
#    # instructs the Quartus Prime software to write the project 
#    # databases and to compile using the command-line executables. 
#    # The script obtains the fmax result from the report database. 
#    # Finally, the script closes the project.
#    # 
#    #--------------------------------------------------------------#
#    #------ Get Slack from the Report File ------#
#    proc get_slack_from_report {} {
#        global project_name
#        load_report $project_name
#        set panel "Timing Analyzer||Setup Summary"
#        set panel_id [get_report_panel_id $panel]
#        set slack [get_report_panel_data -col_name Slack -row 1 -id $panel_id]
#        unload_report $project_name
#        return $slack
#    }
#    proc report_slack {} {
#        set setup_slack [get_slack_from_report]
#        set seed [get_global_assignment -name SEED]
#        puts ""
#        puts "-----------------------------------------------------"
#        puts "Setup Slack for Seed $seed: $setup_slack"
#        puts "-----------------------------------------------------"
#    }
#    #------ Set the project name to chiptrip ------#
#    set project_name chiptrip 
#    #------ Create or open project ------#
#    if [project_exists $project_name] {
#    #------ Project already exists -- open project -------#
#        project_open $project_name -force
#    } else {
#    #------ Project does not exist -- create new project ------#
#        project_new $project_name
#    }
#    #------ Make global assignments ------#
#    set_global_assignment -name family STRATIX
#    set_global_assignment -name device EP1S10F484C5
#    set_global_assignment -name SEED 1
#    #------ Compile using ::quartus::flow ------#
#    execute_flow -compile
#    #------ Report Slack from report ------#
#    report_slack
#    # -----------------------------------------------------------
#    # An alternative method is presented in the following script
#    # -----------------------------------------------------------
#    set_global_assignment -name SEED 2
#    #------ Manually recompile and perform timing analysis again using qexec ------#
#    # Write these assignments to the
#    # Quartus Prime Settings File (.qsf) so that
#    # the Quartus Prime command-line executables
#    # can use these assignments during compilation
#    export_assignments
#    # Compile the project and
#    # exit using "qexit" if there is an error
#    if [catch {qexec "[file join $::quartus(binpath) quartus_fit] $project_name"} result] {
#        qexit -error
#    }
#    if [catch {qexec "[file join $::quartus(binpath) quartus_sta] $project_name"} result] {
#        qexit -error
#    }
#    #------ Report Slack from report ------#
#    report_slack
#    #------ Close Project ------#
#    project_close
#
#
#
#    # das zum Ausführen in die Console
#    # Äquivalent zu vivado -source build_script.tcl -tclargs=pfad zu modul cfg
#    #quartus_sh -t <script file> [<script args>]

    return 0
}

proc writeOutputFiles { relModulePath prjCfg } {
    
    global srcDir
    global workDir

    set vendor [dict get [dict get [dict get $prjCfg projectConfig] general] vendor]
    set projectName [dict get [dict get [dict get $prjCfg projectConfig] general] projectName]
    set outputFileName [dict get [dict get [dict get $prjCfg projectConfig] general] outputFileName]

    set vivadoVersion [dict get [dict get [dict get $prjCfg projectConfig] xilinx] vivadoVersion]


    if { $vendor == "xilinx" } {

        set version [split $swVersion "."]
        set verYear [lindex $version 0]
        set verIncrement [lindex $version 1]

        sendMessage $vendor "Info" "Build_Script-0700" "Writing bitstream and debug probes files."
        write_bitstream -force -bin_file $srcDir/projects/$projectName/bitstream/$outputFileName.bit
        write_debug_probes -force $srcDir/projects/$projectName/bitstream/$outputFileName.ltx

        if { $verYear > 2019 } {
            sendMessage $vendor "Info" "Build_Script-0701" "Vitis software version detected. Writing 'Xilinx Support Archive (.xsa)' file."
            write_hw_platform -fixed -include_bit -force -file $srcDir/projects/$projectName/bitstream/$outputFileName.xsa
        } elseif { $verYear == 2019 } {
            if { $verIncrement == 2 } {
                sendMessage $vendor "Info" "Build_Script-0702" "Vitis software version detected. Writing 'Xilinx Support Archive (.xsa)' files."
                write_hw_platform -fixed -include_bit -force -file $srcDir/projects/$projectName/bitstream/$outputFileName.xsa
            } else {
                sendMessage $vendor "Info" "Build_Script-0703" "SDK software version detected. Writing 'Hardware Description File (.hdf)' file."
                write_hwdef -force $srcDir/projects/$projectName/bitstream/$outputFileName.hdf
            }
        } else {
            sendMessage $vendor "Info" "Build_Script-0704" "SDK software version detected. Writing 'Hardware Description File (.hdf)' file."
            write_hwdef -force $srcDir/projects/$projectName/bitstream/$outputFileName.hdf
        }
    } elseif { $vendor == "intel" } {
        error "" "\[BS-Error\] Not yet supported!" 1
    }

    return 0
}

proc addVersionInfo { prjCfg } {
    
    global srcDir
    global workDir

    set projectName [dict get [dict get [dict get $prjCfg projectConfig] general] projectName]

    #set MAJOR 1;    #  8-bit -> 0 -  255,  �nderung im FPGA f�hren zu Inkompatibilit�t im Interface mit der Firmware
    #set MINOR 0;    # 12-bit -> 0 - 4095, �nderungen (Features) im FPGA die zu keinen Inkompatibilit�ten im Interface mit der Firmware f�hren
    #set PATCH 6;    # 12-bit -> 0 - 4095, kleinere �nderungen die das Interface nicht betreffen
    set major [dict get [dict get $prjCfg versionInfo] major]
    set minor [dict get [dict get $prjCfg versionInfo] minor]
    set patch [dict get [dict get $prjCfg versionInfo] patch]
    set userData [dict get [dict get $prjCfg versionInfo] userdata]

    if { $major == "" } {
        sendMessage $vendor "Warning" "Build_Script-0800" "Major number is empty. Setting to '0'."
        set major 0
    }
    if { $minor == "" } {
        sendMessage $vendor "Warning" "Build_Script-0801" "Minor number is empty. Setting to '0'."
        set minor 0
    }
    if { $patch == "" } {
        sendMessage $vendor "Warning" "Build_Script-0802" "Patch number is empty. Setting to '0'"
        set patch 0
    }

    # Create variable with hex formated MAJOR, MINOR and PATCH
    set majorMinorPatch [expr [expr $major << 24] | [expr $minor << 12] | [expr $patch]]
    set majorMinorPatch_hex [format %x $majorMinorPatch]

    # Read Environment variable and convert to ASCII format
    set buildHost "$::tcl_platform(user)@$::env(COMPUTERNAME)> $userData"
    set buildHostReverse [string reverse $buildHost]
    set buildHostBuffer [binary format a* $buildHostReverse]
    binary scan  $buildHostBuffer  H*  buildHost_hex

    # Get highest SVN Revision number and save in variable
    set svn_hash [exec svn info -r HEAD $srcDir]
    set svn_hash_lines [split $svn_hash "\n"]
    set svn_version "0"
    foreach line $svn_hash_lines {
        if [regexp {Last Changed Rev: } $line ] {
            set svn_version [ lindex [split $line] 3 ]
        }
    }

    set vcsSrcRevision $svn_version
    set vcsSrcRevision_hex [format %x $svn_version]

    # Parse variables to top module generics
    set_property generic "G_INFO_VCS_SRC_REVISION=32'h$vcsSrcRevision_hex G_INFO_MAJOR_MINOR_PATCH=32'h$majorMinorPatch_hex G_INFO_BUILD_HOST=288'h$buildHost_hex" [current_fileset]

    sendMessage $vendor "Info" "Build_Script-0803" "Generics where set to:\nmajor.minor.patch: $major.$minor.$patch\nvcs-src-revision: $vcsSrcRevision\nbuild-host: $buildHost"

    # Create JSON file with version description
    # Open version_info.json for writing
    if { [file exists "$srcDir/projects/$projectName/bitstream/"] == 1} {
        set versionFile [open "$srcDir/projects/$projectName/bitstream/fpga.json" w]

        # Generate JSON structure
        puts $versionFile "{"
        puts $versionFile "    \"component-name\": \"FPGA-Bitstream\","
        puts $versionFile "    \"version-major\": $major,"
        puts $versionFile "    \"version-minor\": $minor,"
        puts $versionFile "    \"version-patch\": $patch,"
        puts $versionFile "    \"svn-rev-src\": \"$vcsSrcRevision\","
        puts $versionFile "    \"build-host\": \"$buildHost\""
        puts $versionFile "}"

        close $versionFile
    } else {
        sendMessage $vendor "Error" "Build_Script-0804" "Project folder does not exist."
    }
    sendMessage $vendor "Info" "Build_Script-0805" "JSON file with version description created."

    return 0
}


## Commandos to add ELF
#add_files -norecurse C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf
#set_property used_in_simulation 0 [get_files C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf]
#
#add_files -fileset sim_1 -norecurse C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf
#
#set_property SCOPED_TO_REF design_2 [get_files -all -of_objects [get_fileset sources_1] {C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf}]
#set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sources_1] {C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf}]
#
#set_property SCOPED_TO_REF design_2 [get_files -all -of_objects [get_fileset sim_1] {C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf}]
#set_property SCOPED_TO_CELLS { microblaze_0 } [get_files -all -of_objects [get_fileset sim_1] {C:/fpga_work/Vitis/TEST/test_prj/helloworld/Debug/helloworld.elf}]
