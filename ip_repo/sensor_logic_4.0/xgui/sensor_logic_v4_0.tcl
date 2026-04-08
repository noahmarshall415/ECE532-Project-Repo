# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  ipgui::add_param $IPINST -name "THRESHOLD"
  ipgui::add_param $IPINST -name "DIST_REG_ADDR"

}

proc update_PARAM_VALUE.DIST_REG_ADDR { PARAM_VALUE.DIST_REG_ADDR } {
	# Procedure called to update DIST_REG_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIST_REG_ADDR { PARAM_VALUE.DIST_REG_ADDR } {
	# Procedure called to validate DIST_REG_ADDR
	return true
}

proc update_PARAM_VALUE.THRESHOLD { PARAM_VALUE.THRESHOLD } {
	# Procedure called to update THRESHOLD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.THRESHOLD { PARAM_VALUE.THRESHOLD } {
	# Procedure called to validate THRESHOLD
	return true
}


proc update_MODELPARAM_VALUE.C_M00_AXI_START_DATA_VALUE { MODELPARAM_VALUE.C_M00_AXI_START_DATA_VALUE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M00_AXI_START_DATA_VALUE". Setting updated value from the model parameter.
set_property value 0xAA000000 ${MODELPARAM_VALUE.C_M00_AXI_START_DATA_VALUE}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_TARGET_SLAVE_BASE_ADDR { MODELPARAM_VALUE.C_M00_AXI_TARGET_SLAVE_BASE_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M00_AXI_TARGET_SLAVE_BASE_ADDR". Setting updated value from the model parameter.
set_property value 0x40000000 ${MODELPARAM_VALUE.C_M00_AXI_TARGET_SLAVE_BASE_ADDR}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_M00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M00_AXI_ADDR_WIDTH". Setting updated value from the model parameter.
set_property value 32 ${MODELPARAM_VALUE.C_M00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_M00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M00_AXI_DATA_WIDTH". Setting updated value from the model parameter.
set_property value 32 ${MODELPARAM_VALUE.C_M00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXI_TRANSACTIONS_NUM { MODELPARAM_VALUE.C_M00_AXI_TRANSACTIONS_NUM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_M00_AXI_TRANSACTIONS_NUM". Setting updated value from the model parameter.
set_property value 4 ${MODELPARAM_VALUE.C_M00_AXI_TRANSACTIONS_NUM}
}

proc update_MODELPARAM_VALUE.THRESHOLD { MODELPARAM_VALUE.THRESHOLD PARAM_VALUE.THRESHOLD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.THRESHOLD}] ${MODELPARAM_VALUE.THRESHOLD}
}

proc update_MODELPARAM_VALUE.DIST_REG_ADDR { MODELPARAM_VALUE.DIST_REG_ADDR PARAM_VALUE.DIST_REG_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIST_REG_ADDR}] ${MODELPARAM_VALUE.DIST_REG_ADDR}
}

