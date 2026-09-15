create_clock -period 15.000 -name sys_clk -waveform {0.000 7.500} [get_ports clk]

# Input Delays
set_input_delay -clock sys_clk -max 1.500 [get_ports target_threshold[*]]
set_input_delay -clock sys_clk -min 0.200 [get_ports target_threshold[*]]

set_input_delay -clock sys_clk -max 1.500 [get_ports chaotic_seed[*]]
set_input_delay -clock sys_clk -min 0.200 [get_ports chaotic_seed[*]]

# Output Delays
set_output_delay -clock sys_clk -max 1.500 [get_ports bitstream_out]
set_output_delay -clock sys_clk -min 0.200 [get_ports bitstream_out]

set_output_delay -clock sys_clk -max 1.500 [get_ports chaos_out[*]]
set_output_delay -clock sys_clk -min 0.200 [get_ports chaos_out[*]]

set_output_delay -clock sys_clk -max 1.500 [get_ports sobol_out[*]]
set_output_delay -clock sys_clk -min 0.200 [get_ports sobol_out[*]]

set_output_delay -clock sys_clk -max 1.500 [get_ports final_hybrid_out[*]]
set_output_delay -clock sys_clk -min 0.200 [get_ports final_hybrid_out[*]]

# False Paths
set_false_path -from [get_ports reset]
