`timescale 1ns/1ps

module tb_register_file;

    // --------------------------------------------------
    // Clock
    // --------------------------------------------------

    logic clk;

    // --------------------------------------------------
    // Read ports
    // --------------------------------------------------

    logic [4:0]  read_addr1;
    logic [4:0]  read_addr2;

    logic [31:0] read_data1;
    logic [31:0] read_data2;

    // --------------------------------------------------
    // Write port
    // --------------------------------------------------

    logic        write_enable;
    logic [4:0]  write_addr;
    logic [31:0] write_data;

    // --------------------------------------------------
    // Register File DUT
    // --------------------------------------------------

    register_file dut (
        .clk          (clk),

        .read_addr1   (read_addr1),
        .read_addr2   (read_addr2),
        .read_data1   (read_data1),
        .read_data2   (read_data2),

        .write_enable (write_enable),
        .write_addr   (write_addr),
        .write_data   (write_data)
    );

    // --------------------------------------------------
    // Clock generation
    // --------------------------------------------------

    always #5 clk = ~clk;

    // --------------------------------------------------
    // Test
    // --------------------------------------------------

    initial begin

        // Initial values
        clk          = 1'b0;

        read_addr1   = 5'd0;
        read_addr2   = 5'd0;

        write_enable = 1'b0;
        write_addr   = 5'd0;
        write_data   = 32'd0;

        #10;

        // --------------------------------------------------
        // TEST 1: Write R1 = 100
        // --------------------------------------------------

        write_enable = 1'b1;
        write_addr   = 5'd1;
        write_data   = 32'd100;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        read_addr1 = 5'd1;

        #1;

        if (read_data1 !== 32'd100)
            $display("ERROR: R1 write/read failed. Expected 100, got %d",
                     read_data1);
        else
            $display("PASS: R1 = 100");


        // --------------------------------------------------
        // TEST 2: Write R2 = 200
        // --------------------------------------------------

        write_enable = 1'b1;
        write_addr   = 5'd2;
        write_data   = 32'd200;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        read_addr2 = 5'd2;

        #1;

        if (read_data2 !== 32'd200)
            $display("ERROR: R2 write/read failed. Expected 200, got %d",
                     read_data2);
        else
            $display("PASS: R2 = 200");


        // --------------------------------------------------
        // TEST 3: Simultaneous read of R1 and R2
        // --------------------------------------------------

        read_addr1 = 5'd1;
        read_addr2 = 5'd2;

        #1;

        if ((read_data1 !== 32'd100) ||
            (read_data2 !== 32'd200))
            $display("ERROR: Dual read failed. R1 = %d, R2 = %d",
                     read_data1, read_data2);
        else
            $display("PASS: Dual read R1 = 100, R2 = 200");


        // --------------------------------------------------
        // TEST 4: Write R3 = 55
        // --------------------------------------------------

        write_enable = 1'b1;
        write_addr   = 5'd3;
        write_data   = 32'd55;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        read_addr1 = 5'd3;

        #1;

        if (read_data1 !== 32'd55)
            $display("ERROR: R3 write/read failed. Expected 55, got %d",
                     read_data1);
        else
            $display("PASS: R3 = 55");


        // --------------------------------------------------
        // TEST 5: R0 must always read zero
        // --------------------------------------------------

        read_addr1 = 5'd0;
        read_addr2 = 5'd0;

        #1;

        if ((read_data1 !== 32'd0) ||
            (read_data2 !== 32'd0))
            $display("ERROR: R0 read failed. R0 values = %d, %d",
                     read_data1, read_data2);
        else
            $display("PASS: R0 reads as zero");


        // --------------------------------------------------
        // TEST 6: Attempt to write R0
        // --------------------------------------------------

        write_enable = 1'b1;
        write_addr   = 5'd0;
        write_data   = 32'd999;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        read_addr1 = 5'd0;

        #1;

        if (read_data1 !== 32'd0)
            $display("ERROR: R0 write protection failed. Got %d",
                     read_data1);
        else
            $display("PASS: R0 write ignored");


        // --------------------------------------------------
        // TEST 7: Verify previous registers are preserved
        // --------------------------------------------------

        read_addr1 = 5'd1;
        read_addr2 = 5'd3;

        #1;

        if ((read_data1 !== 32'd100) ||
            (read_data2 !== 32'd55))
            $display("ERROR: Register values were not preserved. R1 = %d, R3 = %d",
                     read_data1, read_data2);
        else
            $display("PASS: Register values preserved");


        // --------------------------------------------------
        // Test complete
        // --------------------------------------------------

        $display("--------------------------------");
        $display("REGISTER FILE TESTBENCH COMPLETE");
        $display("--------------------------------");

        $finish;

    end

endmodule