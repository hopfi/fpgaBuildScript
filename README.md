# fpgaBuildScript
The TCL script lets the user (re)create Vivado or Quartus projects without GUI. All configuration data (settings, files, ...) are stored in a JSON cfg file. Since all files are text based it is easy to work with VC Systems. 

Projects can be recreated with the command line. For this one environment variable called "SRC_DIR" has to be created. 
SRC_DIR specifies the top folder where all files (fpgaBuildScript, VHDL Module, ...) are stored. "MODULE_FOLDER_PATH" is relative to SRC_DIR and points to a module folder inside SRC_DIR.
The build script assumes a cfg folder with the JSON configuration file inside the MODULE_FOLDER_PATH.

Following commands for Vivado and Quartus have to be executed.
<pre><code>vivado -source $env:SRC_DIR/fpgaBuildScripts/startBuild.tcl -tclargs MODULE_FOLDER_PATH
</code></pre>

<pre><code>quartus_sh -t $env:SRC_DIR/fpgaBuildScripts/startBuild.tcl MODULE_FOLDER_PATH
</code></pre>


For Vivado the Blockdesign and IP Configurator are supported. 
