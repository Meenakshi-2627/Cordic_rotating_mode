`timescale 1ns / 1ps

module sin_cos_tb();

    // 1. Declare signals to connect to the DUT (Device Under Test)
    reg clk;
    reg rst;
    reg [31:0] freq_control;
    wire signed [15:0] sin_out;
    wire signed [15:0] cos_out;

    // 2. Instantiate the Unit Under Test (UUT)
    sin_cos uut (
        .clk(clk), 
        .rst(rst), 
        .freq_control(freq_control), 
        .sin_out(sin_out),
        .cos_out(cos_out)
    );

    // 3. Clock Generation (100 MHz clock -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle every 5ns
    end

    // 4. Test Stimulus
    initial begin
        // --- Initialize Inputs ---
        rst = 1;
        freq_control = 0;

        // --- Reset Pulse ---
        #100;
        rst = 0;
        
        // --- Set Frequency ---
        // We want a wave that is fast enough to see in simulation.
        // Formula: F_out = (F_clk * freq_control) / 2^32
        // Let's target a sine wave period of roughly 200 clock cycles.
        // freq_control = 2^32 / 200 approx 21,474,836
        freq_control = 32'd21474836; 

        // --- Run Simulation ---
        // Run long enough for 3 full cycles to be safe
        // 200 clocks per cycle * 3 cycles * 10ns = 6000ns
        #6000;
        
        // --- Change Frequency (Optional Test) ---
        // Let's make it 2x faster
        freq_control = 32'd42949672; 
        #3000;

        $finish; // End simulation
    end

endmodule
