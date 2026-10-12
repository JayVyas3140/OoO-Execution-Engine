`timescale 1ns/1ps

module tb_reorder_buffer;

    logic clk;
    logic reset;

    // --------------------------------------------------
    // ALLOCATION
    // --------------------------------------------------

    logic        allocate_enable;
    logic [4:0]  allocate_dest;

    logic        allocate_valid;
    logic [2:0]  allocate_tag;

    // --------------------------------------------------
    // RESULT / CDB
    // --------------------------------------------------

    logic        result_enable;
    logic [2:0]  result_tag;
    logic [31:0] result_value;

    // --------------------------------------------------
    // COMMIT
    // --------------------------------------------------

    logic        commit_enable;
    logic [4:0]  commit_dest;
    logic [31:0] commit_value;
    logic [2:0]  commit_tag;

    // --------------------------------------------------
    // STATUS
    // --------------------------------------------------

    logic full;
    logic empty;


    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    reorder_buffer dut (
        .clk              (clk),
        .reset            (reset),

        .allocate_enable  (allocate_enable),
        .allocate_dest    (allocate_dest),
        .allocate_valid   (allocate_valid),
        .allocate_tag     (allocate_tag),

        .result_enable    (result_enable),
        .result_tag       (result_tag),
        .result_value     (result_value),

        .commit_enable    (commit_enable),
        .commit_dest      (commit_dest),
        .commit_value     (commit_value),
        .commit_tag       (commit_tag),

        .full             (full),
        .empty            (empty)
    );


    // --------------------------------------------------
    // CLOCK
    // --------------------------------------------------

    always #5 clk = ~clk;


    // --------------------------------------------------
    // TEST SEQUENCE
    // --------------------------------------------------

    initial begin

        // ==================================================
        // INITIALIZATION
        // ==================================================

        clk = 1'b0;
        reset = 1'b1;

        allocate_enable = 1'b0;
        allocate_dest   = 5'd0;

        result_enable   = 1'b0;
        result_tag      = 3'b000;
        result_value    = 32'd0;


        // ==================================================
        // TEST 1: RESET
        // ==================================================

        #10;

        reset = 1'b0;

        #1;

        if ((empty !== 1'b1) ||
            (full  !== 1'b0))

            $display("ERROR: ROB reset failed");

        else

            $display("PASS: ROB reset");


        // ==================================================
        // TEST 2: FIRST ALLOCATION
        // ==================================================

        allocate_enable = 1'b1;
        allocate_dest   = 5'd1;

        #1;

        if ((allocate_valid !== 1'b1) ||
            (allocate_tag   !== 3'b000))

            $display("ERROR: First allocation failed");

        else

            $display("PASS: First allocation received ROB tag 0");


        @(posedge clk);
        #1;

        allocate_enable = 1'b0;

        if (empty !== 1'b0)

            $display("ERROR: ROB remained empty after allocation");

        else

            $display("PASS: ROB no longer empty");


        // ==================================================
        // TEST 3: RESULT WRITEBACK
        // ==================================================

        result_enable = 1'b1;
        result_tag    = 3'b000;
        result_value  = 32'd123;

        @(posedge clk);
        #1;

        result_enable = 1'b0;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b000) ||
            (commit_dest   !== 5'd1) ||
            (commit_value  !== 32'd123))

            $display("ERROR: ROB result/writeback failed");

        else

            $display("PASS: Result written to ROB and oldest entry became ready");


        // ==================================================
        // TEST 4: COMMIT
        // ==================================================

        @(posedge clk);
        #1;

        if (empty !== 1'b1)

            $display("ERROR: ROB did not become empty after commit");

        else

            $display("PASS: ROB committed oldest entry");


        // ==================================================
        // TEST 5: TWO INSTRUCTIONS
        //
        // R2 -> ROB 1
        // R3 -> ROB 2
        //
        // ROB 2 finishes first.
        // ROB 1 must still commit first.
        // ==================================================

        // --------------------------------------------------
        // Allocate R2 -> ROB 1
        // --------------------------------------------------

        allocate_enable = 1'b1;
        allocate_dest   = 5'd2;

        #1;

        if (allocate_tag !== 3'b001)

            $display("ERROR: Second allocation did not receive tag 1");

        else

            $display("PASS: Second allocation received ROB tag 1");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Allocate R3 -> ROB 2
        // --------------------------------------------------

        allocate_dest = 5'd3;

        #1;

        if (allocate_tag !== 3'b010)

            $display("ERROR: Third allocation did not receive tag 2");

        else

            $display("PASS: Third allocation received ROB tag 2");

        @(posedge clk);
        #1;

        allocate_enable = 1'b0;


        // --------------------------------------------------
        // Complete younger ROB 2 first
        // --------------------------------------------------

        result_enable = 1'b1;
        result_tag    = 3'b010;
        result_value  = 32'd300;

        @(posedge clk);
        #1;

        result_enable = 1'b0;

        if (commit_enable !== 1'b0)

            $display("ERROR: Younger instruction committed out of order");

        else

            $display("PASS: Younger result waits for older ROB entry");


        // --------------------------------------------------
        // Complete older ROB 1
        // --------------------------------------------------

        result_enable = 1'b1;
        result_tag    = 3'b001;
        result_value  = 32'd200;

        @(posedge clk);
        #1;

        result_enable = 1'b0;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b001) ||
            (commit_dest   !== 5'd2) ||
            (commit_value  !== 32'd200))

            $display("ERROR: Older ROB entry did not commit first");

        else

            $display("PASS: Older ROB entry committed before younger entry");


        // Commit ROB 1.

        @(posedge clk);
        #1;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b010) ||
            (commit_dest   !== 5'd3) ||
            (commit_value  !== 32'd300))

            $display("ERROR: Younger ROB entry did not commit second");

        else

            $display("PASS: Younger ROB entry committed after older entry");


        // Commit ROB 2.

        @(posedge clk);
        #1;

        if (empty !== 1'b1)

            $display("ERROR: ROB did not become empty");

        else

            $display("PASS: ROB empty after both commits");


        // ==================================================
        // TEST 6: CIRCULAR BUFFER
        //
        // Current tail is 3.
        //
        // Allocate:
        //   ROB 3
        //   ROB 4
        //   ROB 5
        //   ROB 6
        //   ROB 7
        //
        // Then complete and commit each one in order.
        //
        // After ROB 7, the circular pointer has wrapped.
        // ==================================================

        // --------------------------------------------------
        // Allocate ROB 3
        // --------------------------------------------------

        allocate_enable = 1'b1;
        allocate_dest   = 5'd4;

        #1;

        if (allocate_tag !== 3'b011)

            $display("ERROR: Expected allocation tag 3");

        else

            $display("PASS: Wrap allocation tag 3");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Allocate ROB 4
        // --------------------------------------------------

        allocate_dest = 5'd5;

        #1;

        if (allocate_tag !== 3'b100)

            $display("ERROR: Expected allocation tag 4");

        else

            $display("PASS: Wrap allocation tag 4");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Allocate ROB 5
        // --------------------------------------------------

        allocate_dest = 5'd6;

        #1;

        if (allocate_tag !== 3'b101)

            $display("ERROR: Expected allocation tag 5");

        else

            $display("PASS: Wrap allocation tag 5");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Allocate ROB 6
        // --------------------------------------------------

        allocate_dest = 5'd7;

        #1;

        if (allocate_tag !== 3'b110)

            $display("ERROR: Expected allocation tag 6");

        else

            $display("PASS: Wrap allocation tag 6");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Allocate ROB 7
        // --------------------------------------------------

        allocate_dest = 5'd8;

        #1;

        if (allocate_tag !== 3'b111)

            $display("ERROR: Expected allocation tag 7");

        else

            $display("PASS: Wrap allocation tag 7");

        @(posedge clk);
        #1;

        allocate_enable = 1'b0;


        // --------------------------------------------------
        // ROB 3
        // --------------------------------------------------

        result_enable = 1'b1;
        result_tag    = 3'b011;
        result_value  = 32'd400;

        @(posedge clk);
        #1;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b011) ||
            (commit_dest   !== 5'd4) ||
            (commit_value  !== 32'd400))

            $display("ERROR: Wraparound commit tag 3 failed");

        else

            $display("PASS: Wraparound commit tag 3");


        // --------------------------------------------------
        // ROB 4
        // --------------------------------------------------

        result_tag   = 3'b100;
        result_value = 32'd500;

        @(posedge clk);
        #1;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b100) ||
            (commit_dest   !== 5'd5) ||
            (commit_value  !== 32'd500))

            $display("ERROR: Wraparound commit tag 4 failed");

        else

            $display("PASS: Wraparound commit tag 4");


        // --------------------------------------------------
        // ROB 5
        // --------------------------------------------------

        result_tag   = 3'b101;
        result_value = 32'd600;

        @(posedge clk);
        #1;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b101) ||
            (commit_dest   !== 5'd6) ||
            (commit_value  !== 32'd600))

            $display("ERROR: Wraparound commit tag 5 failed");

        else

            $display("PASS: Wraparound commit tag 5");


        // --------------------------------------------------
        // ROB 6
        // --------------------------------------------------

        result_tag   = 3'b110;
        result_value = 32'd700;

        @(posedge clk);
        #1;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b110) ||
            (commit_dest   !== 5'd7) ||
            (commit_value  !== 32'd700))

            $display("ERROR: Wraparound commit tag 6 failed");

        else

            $display("PASS: Wraparound commit tag 6");


        // --------------------------------------------------
        // ROB 7
        // --------------------------------------------------

        result_tag   = 3'b111;
        result_value = 32'd800;

        @(posedge clk);
        #1;

        result_enable = 1'b0;

        if ((commit_enable !== 1'b1) ||
            (commit_tag    !== 3'b111) ||
            (commit_dest   !== 5'd8) ||
            (commit_value  !== 32'd800))

            $display("ERROR: Wraparound commit tag 7 failed");

        else

            $display("PASS: Wraparound commit tag 7");


        // Final clock commits ROB 7.

        @(posedge clk);
        #1;

        if (empty !== 1'b1)

            $display("ERROR: ROB not empty after circular test");

        else

            $display("PASS: ROB circular operation completed");


        // ==================================================
        // TEST 7: FULL CONDITION
        //
        // Fill all 8 entries.
        // ==================================================

        allocate_enable = 1'b1;
        allocate_dest   = 5'd1;


        // --------------------------------------------------
        // Tag 0
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b000)
            $display("ERROR: Full-test tag 0 incorrect");
        else
            $display("PASS: Full-test tag 0");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 1
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b001)
            $display("ERROR: Full-test tag 1 incorrect");
        else
            $display("PASS: Full-test tag 1");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 2
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b010)
            $display("ERROR: Full-test tag 2 incorrect");
        else
            $display("PASS: Full-test tag 2");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 3
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b011)
            $display("ERROR: Full-test tag 3 incorrect");
        else
            $display("PASS: Full-test tag 3");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 4
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b100)
            $display("ERROR: Full-test tag 4 incorrect");
        else
            $display("PASS: Full-test tag 4");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 5
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b101)
            $display("ERROR: Full-test tag 5 incorrect");
        else
            $display("PASS: Full-test tag 5");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 6
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b110)
            $display("ERROR: Full-test tag 6 incorrect");
        else
            $display("PASS: Full-test tag 6");

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Tag 7
        // --------------------------------------------------

        #1;

        if (allocate_tag !== 3'b111)
            $display("ERROR: Full-test tag 7 incorrect");
        else
            $display("PASS: Full-test tag 7");

        @(posedge clk);
        #1;

        allocate_enable = 1'b0;


        // --------------------------------------------------
        // ROB must now be full.
        // --------------------------------------------------

        if (full !== 1'b1)

            $display("ERROR: ROB full flag failed");

        else

            $display("PASS: ROB full after eight allocations");


        // --------------------------------------------------
        // Allocation must be blocked while full.
        // --------------------------------------------------

        allocate_enable = 1'b1;

        #1;

        if (allocate_valid !== 1'b0)

            $display("ERROR: ROB allowed allocation while full");

        else

            $display("PASS: ROB correctly blocked allocation while full");

        allocate_enable = 1'b0;


        // ==================================================
        // COMPLETE
        // ==================================================

        $display("--------------------------------");
        $display("REORDER BUFFER TESTBENCH COMPLETE");
        $display("--------------------------------");

        $finish;

    end

endmodule