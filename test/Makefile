# Hasemi-Sevina-49 cocotb testbench
SIM ?= icarus
FST ?= -fst
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = project.v spi_slave.v mmio_bridge.v register_bank.v sensor_validator.v risk_engine.v risk_fsm.v event_logger.v \
	cpu/tinyqv/tinyqv.v cpu/tinyqv/cpu.v cpu/tinyqv/core.v cpu/tinyqv/decode.v \
	cpu/tinyqv/alu.v cpu/tinyqv/register.v cpu/tinyqv/counter.v \
	cpu/tinyqv/mem_ctrl.v cpu/tinyqv/qspi_ctrl.v

ifneq ($(GATES),yes)
SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
else
SIM_BUILD = sim_build/gl
COMPILE_ARGS += -DGL_TEST -DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
endif

COMPILE_ARGS += -I$(SRC_DIR)
COMPILE_ARGS += -DSIM
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim
