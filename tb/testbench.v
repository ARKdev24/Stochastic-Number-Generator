`timescale 1ns / 1ps

module tb_top_pipeline;

    parameter CAPTURE_BITS = 64;

    // Testbench Signals
    reg         tb_clk;
    reg         tb_reset;
    reg  [31:0] tb_chaotic_seed;      
    reg  [31:0] tb_target_threshold; 
    
    wire [31:0] tb_chaos_out;         // Captured Chaos Stream
    wire [31:0] tb_sobol_out;         // Captured Sobol Stream
    wire [31:0] tb_final_hybrid_out;  // XOR Hybrid Stream
    wire        tb_bitstream;        

    integer file_handler;
    integer cycle_count = 0;
    integer bit_count   = 0;

    // Instantiate Unit Under Test (UUT)
    top_pipeline uut (
        .clk(tb_clk),
        .reset(tb_reset),
        .chaotic_seed(tb_chaotic_seed),      
        .target_threshold(tb_target_threshold), 
        .chaos_out(tb_chaos_out),             // Connected Debug Port
        .sobol_out(tb_sobol_out),             // Connected Debug Port
        .final_hybrid_out(tb_final_hybrid_out),
        .bitstream_out(tb_bitstream)            
    );

    // Clock Generator (66.6 MHz)
    always #7.5 tb_clk = ~tb_clk;

    initial begin
        tb_clk   = 0;
        tb_reset = 1;
        
        tb_chaotic_seed = $urandom();
        if (tb_chaotic_seed == 32'd0) begin
            tb_chaotic_seed = 32'hA5A5A5A5;
        end

        tb_target_threshold = 32'h8000_0000; 
        file_handler = $fopen("bitstream_64n2.txt", "w");

        #30;
        tb_reset = 0;

        #150010;
        $fclose(file_handler);
        $finish;
    end

    // BITSTREAM RECORDER
    always @(posedge tb_clk) begin
        if (!tb_reset) begin
            cycle_count <= cycle_count + 1;
            
            if (cycle_count >= 4 && bit_count < CAPTURE_BITS) begin  // Changed from >= 2 to >= 4
                $fwrite(file_handler, "%b\n", tb_bitstream);
                bit_count <= bit_count + 1;
                
                if (bit_count + 1 == CAPTURE_BITS) begin
                    $fclose(file_handler);
                    $finish;
                end
            end
        end
    end

endmodule
