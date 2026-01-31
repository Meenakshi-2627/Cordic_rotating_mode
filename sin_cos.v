`timescale 1ns / 1ps

module sin_cos (
    input wire clk,
    input wire rst,
    input wire [31:0] freq_control, // Determines frequency (Phase increment)
    output reg signed [15:0] sin_out ,
    output reg signed [15:0] cos_out// 16-bit signed output
);

    // --- 1. Parameter Definitions ---
    // 32-bit Phase Accumulator (0 to 360 degrees mapped to 0 to 2^32)
    reg [31:0] phase_acc;
    
    // CORDIC Pipeline Variables
    // We use 'signed' so Verilog handles negative math correctly
    reg signed [15:0] x_start, y_start;
    reg signed [31:0] z_start;
    
    // Combinational Logic Variables for the Loop
    reg signed [15:0] x, y, x_next, y_next;
    reg signed [31:0] z, z_next;
    
    // Loop variable
    integer i;

    // --- 2. The Lookup Table (LUT) ---
    // Stores atan(2^-i) scaled to 32-bit angle format
    reg [31:0] atan_table [0:15];
    
    initial begin
        atan_table[0]  = 32'h20000000; // 45.000 deg
        atan_table[1]  = 32'h12E4051D; // 26.565 deg
        atan_table[2]  = 32'h09FB385B; // 14.036 deg
        atan_table[3]  = 32'h051111D4; // 7.125 deg
        atan_table[4]  = 32'h028B0D43; // 3.576 deg
        atan_table[5]  = 32'h0145D7E1; // 1.790 deg
        atan_table[6]  = 32'h00A2F983; // 0.895 deg
        atan_table[7]  = 32'h00517CC1; // 0.448 deg
        atan_table[8]  = 32'h0028BE60; // 0.224 deg
        atan_table[9]  = 32'h00145F30; // 0.112 deg
        atan_table[10] = 32'h000A2F98; // 0.056 deg
        atan_table[11] = 32'h000517CC; // 0.028 deg
        atan_table[12] = 32'h00028BE6; // 0.014 deg
        atan_table[13] = 32'h000145F3; // 0.007 deg
        atan_table[14] = 32'h0000A2F9; // 0.003 deg
        atan_table[15] = 32'h0000517C; // 0.001 deg
    end

    // --- 3. Phase Accumulator ---
    always @(posedge clk) begin
        if (rst) begin
            phase_acc <= 32'd0;
        end else begin
            phase_acc <= phase_acc + freq_control;
        end
    end

    // --- 4. Quadrant Mapping (Pre-Rotation) ---
    // Check top 2 bits to see if we are in Quadrant 2 or 3 (90-270 deg)
    always @(posedge clk) begin
        if (rst) begin
             x_start <= 16'sd9949; y_start <= 0; z_start <= 0;
        end else begin
            // If Top bits are 01 or 10, we are in left half plane
            if (phase_acc[31:30] == 2'b01 || phase_acc[31:30] == 2'b10) begin
                x_start <= -16'sd9949; // -0.607 * 2^14
                y_start <= 16'sd0;
                z_start <= phase_acc - 32'h80000000; // Subtract 180 deg
            end else begin
                x_start <= 16'sd9949;  // +0.607 * 2^14
                y_start <= 16'sd0;
                z_start <= phase_acc;
            end
        end
    end

    // --- 5. The CORDIC Algorithm (Unrolled Loop) ---
    always @(*) begin
        // Initialize loop variables
        x = x_start;
        y = y_start;
        z = z_start;

        for (i = 0; i < 16; i = i + 1) begin
            if (z[31] == 1'b0) begin 
                // Z is positive, rotate Clockwise (subtract angle)
                x_next = x - (y >>> i); // Arithmetic shift preserves sign
                y_next = y + (x >>> i);
                z_next = z - atan_table[i];
            end else begin
                // Z is negative, rotate Counter-Clockwise (add angle)
                x_next = x + (y >>> i);
                y_next = y - (x >>> i);
                z_next = z + atan_table[i];
            end
            
            // Update for next iteration
            x = x_next;
            y = y_next;
            z = z_next;
        end
    end

    // --- 6. Output Registration ---
    always @(posedge clk) begin
        if (rst)begin
            sin_out <= 0;
            cos_out <= 16'sd16383;
        end
        else
            sin_out <= y; 
            cos_out <= x;// The Y component holds the Sine value
    end

endmodule
