# Create clk_wiz
cell xilinx.com:ip:clk_wiz pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 125.0
  CLKOUT2_USED true
  CLKOUT2_REQUESTED_OUT_FREQ 250.0
  CLKOUT2_REQUESTED_PHASE 180
  CLKOUT3_USED true
  CLKOUT3_REQUESTED_OUT_FREQ 250.0
  CLKOUT3_REQUESTED_PHASE 225
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
} {
  M_AXI_GP0_ACLK pll_0/clk_out1
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset rst_0 {} {
  ext_reset_in const_0/dout
}

# ADC

# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc adc_0 {
  ADC_DATA_WIDTH 14
} {
  aclk pll_0/clk_out1
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# DAC

# Create axis_red_pitaya_dac
cell pavel-demin:user:axis_red_pitaya_dac dac_0 {
  DAC_DATA_WIDTH 14
} {
  aclk pll_0/clk_out1
  ddr_clk pll_0/clk_out2
  wrt_clk pll_0/clk_out3
  locked pll_0/locked
  dac_clk dac_clk_o
  dac_rst dac_rst_o
  dac_sel dac_sel_o
  dac_wrt dac_wrt_o
  dac_dat dac_dat_o
}

# GPIO

# Delete input/output port
delete_bd_objs [get_bd_ports exp_p_tri_io]

# Create output port
create_bd_port -dir O -from 7 -to 0 exp_p_tri_io

# CFG

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register cfg_0 {
  CFG_DATA_WIDTH 96
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_0 {
  DIN_WIDTH 96 DIN_FROM 0 DIN_TO 0
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_1 {
  DIN_WIDTH 96 DIN_FROM 1 DIN_TO 1
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_2 {
  DIN_WIDTH 96 DIN_FROM 15 DIN_TO 8
} {
  din cfg_0/cfg_data
  dout exp_p_tri_io
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_3 {
  DIN_WIDTH 96 DIN_FROM 31 DIN_TO 16
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_4 {
  DIN_WIDTH 96 DIN_FROM 63 DIN_TO 32
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_5 {
  DIN_WIDTH 96 DIN_FROM 79 DIN_TO 64
} {
  din cfg_0/cfg_data
}

# DDS

# Create axis_constant
cell pavel-demin:user:axis_constant phase_0 {
  AXIS_TDATA_WIDTH 32
} {
  cfg_data slice_4/dout
  aclk pll_0/clk_out1
}

# Create dds_compiler
cell xilinx.com:ip:dds_compiler dds_0 {
  DDS_CLOCK_RATE 125
  SPURIOUS_FREE_DYNAMIC_RANGE 138
  FREQUENCY_RESOLUTION 0.2
  PHASE_INCREMENT Streaming
  HAS_ARESETN true
  HAS_PHASE_OUT false
  PHASE_WIDTH 30
  OUTPUT_WIDTH 24
  DSP48_USE Minimal
  NEGATIVE_SINE true
} {
  S_AXIS_PHASE phase_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# Create axis_constant
cell pavel-demin:user:axis_constant phase_1 {
  AXIS_TDATA_WIDTH 32
} {
  cfg_data slice_4/dout
  aclk pll_0/clk_out1
}

# Create dds_compiler
cell xilinx.com:ip:dds_compiler dds_1 {
  DDS_CLOCK_RATE 125
  SPURIOUS_FREE_DYNAMIC_RANGE 138
  FREQUENCY_RESOLUTION 0.2
  PHASE_INCREMENT Streaming
  HAS_ARESETN true
  HAS_PHASE_OUT false
  PHASE_WIDTH 30
  OUTPUT_WIDTH 24
  DSP48_USE Minimal
  OUTPUT_SELECTION Sine
} {
  S_AXIS_PHASE phase_1/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# TX

# Create dsp48
cell pavel-demin:user:dsp48 mult_4 {
  A_WIDTH 24
  B_WIDTH 16
  P_WIDTH 14
} {
  A dds_1/m_axis_data_tdata
  B slice_5/dout
  CLK pll_0/clk_out1
}

# Create c_shift_ram
cell xilinx.com:ip:c_shift_ram delay_0 {
  WIDTH.VALUE_SRC USER
  WIDTH 1
  DEPTH 4
} {
  D dds_1/m_axis_data_tvalid
  CLK pll_0/clk_out1
}

# Create axis_zeroer
cell pavel-demin:user:axis_zeroer zeroer_0 {
  AXIS_TDATA_WIDTH 32
} {
  s_axis_tdata mult_4/P
  s_axis_tvalid delay_0/Q
  M_AXIS dac_0/S_AXIS
  aclk pll_0/clk_out1
}

# RX

for {set i 0} {$i <= 1} {incr i} {

  # Create port_slicer
  cell pavel-demin:user:port_slicer dds_slice_$i {
    DIN_WIDTH 48 DIN_FROM [expr 24 * $i + 23] DIN_TO [expr 24 * $i]
  } {
    din dds_0/m_axis_data_tdata
  }

  # Create port_slicer
  cell pavel-demin:user:port_slicer adc_slice_$i {
    DIN_WIDTH 32 DIN_FROM [expr 16 * $i + 13] DIN_TO [expr 16 * $i]
  } {
    din adc_0/m_axis_tdata
  }

}

for {set i 0} {$i <= 3} {incr i} {

  # Create dsp48
  cell pavel-demin:user:dsp48 mult_$i {
    A_WIDTH 24
    B_WIDTH 14
    P_WIDTH 24
  } {
    A dds_slice_[expr $i % 2]/dout
    B adc_slice_[expr $i / 2]/dout
    CLK pll_0/clk_out1
  }

  # Create axis_variable
  cell pavel-demin:user:axis_variable rate_$i {
    AXIS_TDATA_WIDTH 16
  } {
    cfg_data slice_3/dout
    aclk pll_0/clk_out1
    aresetn slice_0/dout
  }

  # Create cic_compiler
  cell xilinx.com:ip:cic_compiler cic_$i {
    INPUT_DATA_WIDTH.VALUE_SRC USER
    FILTER_TYPE Decimation
    NUMBER_OF_STAGES 6
    SAMPLE_RATE_CHANGES Programmable
    MINIMUM_RATE 4
    MAXIMUM_RATE 8192
    FIXED_OR_INITIAL_RATE 4
    INPUT_SAMPLE_FREQUENCY 125
    CLOCK_FREQUENCY 125
    INPUT_DATA_WIDTH 24
    QUANTIZATION Truncation
    OUTPUT_DATA_WIDTH 32
    USE_XTREME_DSP_SLICE false
    HAS_ARESETN true
  } {
    s_axis_data_tdata mult_$i/P
    s_axis_data_tvalid const_0/dout
    S_AXIS_CONFIG rate_$i/M_AXIS
    aclk pll_0/clk_out1
    aresetn slice_0/dout
  }

}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
  NUM_SI 4
} {
  S00_AXIS cic_3/M_AXIS_DATA
  S01_AXIS cic_2/M_AXIS_DATA
  S02_AXIS cic_1/M_AXIS_DATA
  S03_AXIS cic_0/M_AXIS_DATA
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 16
  M_TDATA_NUM_BYTES 4
} {
  S_AXIS comb_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler cic_4 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Fixed
  FIXED_OR_INITIAL_RATE 3125
  INPUT_SAMPLE_FREQUENCY 31.25
  CLOCK_FREQUENCY 125
  NUMBER_OF_CHANNELS 4
  INPUT_DATA_WIDTH 32
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 32
  USE_XTREME_DSP_SLICE false
  HAS_ARESETN true
} {
  S_AXIS_DATA conv_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# Create floating_point
cell xilinx.com:ip:floating_point fp_0 {
  OPERATION_TYPE Fixed_to_float
  A_PRECISION_TYPE.VALUE_SRC USER
  C_A_EXPONENT_WIDTH.VALUE_SRC USER
  C_A_FRACTION_WIDTH.VALUE_SRC USER
  A_PRECISION_TYPE Custom
  C_A_EXPONENT_WIDTH 2
  C_A_FRACTION_WIDTH 30
  RESULT_PRECISION_TYPE Single
  HAS_ARESETN true
} {
  S_AXIS_A cic_4/M_AXIS_DATA
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter conv_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 16
} {
  S_AXIS fp_0/M_AXIS_RESULT
  aclk pll_0/clk_out1
  aresetn slice_0/dout
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 128
  INPUT_DEPTH 256
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 1024
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 11
} {
  clk pll_0/clk_out1
  srst slice_1/dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo fifo_0 {
  S_AXIS_TDATA_WIDTH 128
  M_AXIS_TDATA_WIDTH 32
} {
  S_AXIS conv_1/M_AXIS
  FIFO_READ fifo_generator_0/FIFO_READ
  FIFO_WRITE fifo_generator_0/FIFO_WRITE
  aclk pll_0/clk_out1
}

# Create axi_axis_reader
cell pavel-demin:user:axi_axis_reader reader_0 {
  AXI_DATA_WIDTH 32
} {
  S_AXIS fifo_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# STS

# Create dna_reader
cell pavel-demin:user:dna_reader dna_0 {} {
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create xlconcat
cell xilinx.com:ip:xlconcat concat_3 {
  NUM_PORTS 3
  IN0_WIDTH 32
  IN1_WIDTH 64
  IN2_WIDTH 16
} {
  In0 const_0/dout
  In1 dna_0/dna_data
  In2 fifo_generator_0/rd_data_count
}

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register sts_0 {
  STS_DATA_WIDTH 128
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data concat_3/dout
}

addr 0x40000000 4K sts_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40001000 4K cfg_0/S_AXI /ps_0/M_AXI_GP0

addr 0x40002000 4K reader_0/S_AXI /ps_0/M_AXI_GP0
