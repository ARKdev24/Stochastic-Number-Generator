

`timescale 1ns / 1ps

// ============================================================================
// STAGE 1: Chaos Calculator Layer (DSP48 Fully Pipelined)
// ============================================================================
// ============================================================================
// STAGE 1: Chaos Calculator Layer (DSP48 Fully Pipelined)
// ============================================================================
module stage1_chaos (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] chaotic_seed,   
    output reg  [31:0] stage1_pipe_reg
);

    // 1. (1.0 - X) in Q2.30
    wire [31:0] one_minus_x = 32'h4000_0000 - stage1_pipe_reg;
    
    // 2. Pure combinational wire (No intermediate flip-flops inferred)
    (* use_dsp = "yes" *) wire [63:0] raw_mult = stage1_pipe_reg * one_minus_x;
    
    // 3. Slice extraction
    wire [31:0] x_calc = raw_mult[59:28];

    // 4. Single synchronous register for the entire module
    always @(posedge clk) begin
        if (reset) begin
            if ((chaotic_seed & 32'h3FFF_FFFF) == 32'd0)
                stage1_pipe_reg <= 32'h15A0_B000;
            else
                stage1_pipe_reg <= (chaotic_seed & 32'h3FFF_FFFF);
        end else begin
            stage1_pipe_reg <= (x_calc == 32'd0) ? 32'h15A0_B000 : x_calc; 
        end
    end

endmodule

// ============================================================================
// STAGE 2: Quantization & Range Scaling Layer
// ============================================================================
module stage2_quantizer (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] chaos_in,
    output reg  [31:0] stage2_quantized_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage2_quantized_out <= 32'd0;
        end else begin
            // Shift Q2.30 fractional bits left by 2 so active chaotic bits reach Bit 31
            stage2_quantized_out <= (chaos_in << 2);
        end
    end
endmodule

// ============================================================================
// STAGE 3: Independent Parallel Sobol Engine
// ============================================================================
module stage3_sobol (
    input  wire        clk,
    input  wire        reset,
    output reg  [31:0] sobol_out
);
    reg [31:0] counter;
    reg [4:0]  trailing_zero_index;
    
    reg [31:0] V [0:31];
    initial begin
        V[0]  = 32'h8000_0000; V[1]  = 32'hC000_0000; V[2]  = 32'hE000_0000; V[3]  = 32'hF000_0000;
        V[4]  = 32'hF800_0000; V[5]  = 32'hFC00_0000; V[6]  = 32'hFE00_0000; V[7]  = 32'hFF00_0000;
        V[8]  = 32'hFF80_0000; V[9]  = 32'hFFC0_0000; V[10] = 32'hFFE0_0000; V[11] = 32'hFFF0_0000;
        V[12] = 32'hFFF8_0000; V[13] = 32'hFFFC_0000; V[14] = 32'hFFFE_0000; V[15] = 32'hFFFF_0000;
        V[16] = 32'hFFFF_8000; V[17] = 32'hFFFF_C000; V[18] = 32'hFFFF_E000; V[19] = 32'hFFFF_F000;
        V[20] = 32'hFFFF_F800; V[21] = 32'hFFFF_FC00; V[22] = 32'hFFFF_FE00; V[23] = 32'hFFFF_FF00;
        V[24] = 32'hFFFF_FF80; V[25] = 32'hFFFF_FFC0; V[26] = 32'hFFFF_FFE0; V[27] = 32'hFFFF_FFF0;
        V[28] = 32'hFFFF_FFF8; V[29] = 32'hFFFF_FFFC; V[30] = 32'hFFFF_FFFE; V[31] = 32'hFFFF_FFFF;
    end

    always @(*) begin
        if      (counter[0]  == 1'b0) trailing_zero_index = 5'd0;
        else if (counter[1]  == 1'b0) trailing_zero_index = 5'd1;
        else if (counter[2]  == 1'b0) trailing_zero_index = 5'd2;
        else if (counter[3]  == 1'b0) trailing_zero_index = 5'd3;
        else if (counter[4]  == 1'b0) trailing_zero_index = 5'd4;
        else if (counter[5]  == 1'b0) trailing_zero_index = 5'd5;
        else if (counter[6]  == 1'b0) trailing_zero_index = 5'd6;
        else if (counter[7]  == 1'b0) trailing_zero_index = 5'd7;
        else if (counter[8]  == 1'b0) trailing_zero_index = 5'd8;
        else if (counter[9]  == 1'b0) trailing_zero_index = 5'd9;
        else if (counter[10] == 1'b0) trailing_zero_index = 5'd10;
        else if (counter[11] == 1'b0) trailing_zero_index = 5'd11;
        else if (counter[12] == 1'b0) trailing_zero_index = 5'd12;
        else if (counter[13] == 1'b0) trailing_zero_index = 5'd13;
        else if (counter[14] == 1'b0) trailing_zero_index = 5'd14;
        else if (counter[15] == 1'b0) trailing_zero_index = 5'd15;
        else if (counter[16] == 1'b0) trailing_zero_index = 5'd16;
        else if (counter[17] == 1'b0) trailing_zero_index = 5'd17;
        else if (counter[18] == 1'b0) trailing_zero_index = 5'd18;
        else if (counter[19] == 1'b0) trailing_zero_index = 5'd19;
        else if (counter[20] == 1'b0) trailing_zero_index = 5'd20;
        else if (counter[21] == 1'b0) trailing_zero_index = 5'd21;
        else if (counter[22] == 1'b0) trailing_zero_index = 5'd22;
        else if (counter[23] == 1'b0) trailing_zero_index = 5'd23;
        else if (counter[24] == 1'b0) trailing_zero_index = 5'd24;
        else if (counter[25] == 1'b0) trailing_zero_index = 5'd25;
        else if (counter[26] == 1'b0) trailing_zero_index = 5'd26;
        else if (counter[27] == 1'b0) trailing_zero_index = 5'd27;
        else if (counter[28] == 1'b0) trailing_zero_index = 5'd28;
        else if (counter[29] == 1'b0) trailing_zero_index = 5'd29;
        else if (counter[30] == 1'b0) trailing_zero_index = 5'd30;
        else                          trailing_zero_index = 5'd31;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter   <= 32'd0;
            sobol_out <= 32'd0;
        end else begin
            counter   <= counter + 32'd1;
            sobol_out <= sobol_out ^ V[trailing_zero_index];
        end
    end
endmodule

// ============================================================================
// STAGE 4: Hybrid Mixer Layer (Bit-Interleaved Decorrelation)
// ============================================================================
module stage4_mixer (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] chaos_in,
    input  wire [31:0] sobol_in,
    output reg  [31:0] hybrid_out
);

    // ------------------------------------------------------------------------
    // 1. SOBOL BIT-REVERSAL:
    // Maps fast-toggling low-order bits to MSBs to prevent slow periodic drifts.
    // ------------------------------------------------------------------------
    wire [31:0] sobol_rev;

    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin : bit_rev_sobol
            assign sobol_rev[j] = sobol_in[31 - j];
        end
    endgenerate

    // ------------------------------------------------------------------------
    // 2. CHAOS BIT-INTERLEAVING:
    // Spreads chaotic dynamic range across alternating bit positions.
    // ------------------------------------------------------------------------
    wire [31:0] chaos_interleaved;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : interleave_bits
            assign chaos_interleaved[2*i]     = chaos_in[i];       // LSBs on even bits
            assign chaos_interleaved[2*i+1]   = chaos_in[31-i];    // MSBs on odd bits
        end
    endgenerate

    // ------------------------------------------------------------------------
    // 3. HYBRID MIXING: Interleaved Chaos ^ Reversed Sobol
    // ------------------------------------------------------------------------
    wire [31:0] mixed_vector = chaos_interleaved ^ sobol_rev;

    // ------------------------------------------------------------------------
    // 4. SYNCHRONOUS REGISTER
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            hybrid_out <= 32'd0;
        end else begin
            hybrid_out <= mixed_vector;
        end
    end
endmodule
// ============================================================================
// TOP-LEVEL PIPELINE WRAPPER (Updated with Exposed Debug Ports)
// ============================================================================
module top_pipeline (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] chaotic_seed,
    input  wire [31:0] target_threshold,
    output wire [31:0] chaos_out,          // Exposed Chaos Engine Output
    output wire [31:0] sobol_out,          // Exposed Sobol Generator Output
    output wire [31:0] final_hybrid_out,
    output wire        bitstream_out
);

    wire [31:0] w_stage1_to_stage2;
    wire [31:0] w_stage2_to_stage4;
    wire [31:0] w_stage3_to_stage4;

    // Stage 1: Chaos Engine
    stage1_chaos u_stage1 (
        .clk            (clk),
        .reset          (reset),
        .chaotic_seed   (chaotic_seed),
        .stage1_pipe_reg(w_stage1_to_stage2)
    );

    // Stage 2: Quantizer Resynchronizer & Range Scaler
    stage2_quantizer u_stage2 (
        .clk                 (clk),
        .reset               (reset),
        .chaos_in            (w_stage1_to_stage2),
        .stage2_quantized_out(w_stage2_to_stage4)
    );

    // Stage 3: Sobol Generator
    stage3_sobol u_stage3 (
        .clk       (clk),
        .reset     (reset),
        .sobol_out (w_stage3_to_stage4)
    );

    // Stage 4: Hybrid Mixer
    stage4_mixer u_stage4 (
        .clk        (clk),
        .reset      (reset),
        .chaos_in   (w_stage2_to_stage4),
        .sobol_in   (w_stage3_to_stage4),
        .hybrid_out (final_hybrid_out)
    );
    
    // Pass internal stage outputs to top-level debug ports
    assign chaos_out = w_stage2_to_stage4;
    assign sobol_out = w_stage3_to_stage4;

    // Output Digital Comparator Gate
    assign bitstream_out = (final_hybrid_out < target_threshold) ? 1'b1 : 1'b0;

endmodule
