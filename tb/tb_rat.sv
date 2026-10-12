`timescale 1ns/1ps

module tb_rat;

    logic clk;
    logic reset;

    // Source register 1
    logic [4:0] src1_arch;
    logic       src1_valid;
    logic [2:0] src1_tag;

    // Source register 2
    logic [4:0] src2_arch;
    logic       src2_valid;
    logic [2:0] src2_tag;

    // Rename destination
    logic       rename_enable;
    logic [4:0] dest_arch;
    logic [2:0] dest_tag;

    // Commit information
    logic       commit_enable;
    logic [4:0] commit_arch;
    logic [2:0] commit_tag;

    rat dut (
        .clk           (clk),
        .reset         (reset),

        .src1_arch     (src1_arch),
        .src1_valid    (src1_valid),
        .src1_tag      (src1_tag),

        .src2_arch     (src2_arch),
        .src2_valid    (src2_valid),
        .src2_tag      (src2_tag),

        .rename_enable (rename_enable),
        .dest_arch     (dest_arch),
        .dest_tag      (dest_tag),

        .commit_enable (commit_enable),
        .commit_arch   (commit_arch),
        .commit_tag    (commit_tag)
    );

    always #5 clk = ~clk;

    initial begin

        // ------------------------------------------------
        // INITIALIZATION
        // ------------------------------------------------

        clk           = 1'b0;
        reset         = 1'b1;

        src1_arch     = 5'd0;
        src2_arch     = 5'd0;

        rename_enable = 1'b0;
        dest_arch     = 5'd0;
        dest_tag      = 3'b000;

        commit_enable = 1'b0;
        commit_arch   = 5'd0;
        commit_tag    = 3'b000;

        // ------------------------------------------------
        // TEST 1: RESET
        // ------------------------------------------------

        #10;
        reset = 1'b0;

        src1_arch = 5'd1;
        src2_arch = 5'd2;

        #1;

        if ((src1_valid !== 1'b0) ||
            (src2_valid !== 1'b0))
            $display("ERROR: RAT reset failed");
        else
            $display("PASS: RAT reset");

        // ------------------------------------------------
        // TEST 2: RENAME R1 -> ROB TAG 3
        // ------------------------------------------------

        rename_enable = 1'b1;
        dest_arch     = 5'd1;
        dest_tag      = 3'b011;

        @(posedge clk);
        #1;

        rename_enable = 1'b0;

        src1_arch = 5'd1;
        #1;

        if ((src1_valid !== 1'b1) ||
            (src1_tag !== 3'b011))
            $display("ERROR: R1 rename failed. Valid=%b Tag=%b",
                     src1_valid, src1_tag);
        else
            $display("PASS: R1 mapped to ROB tag 3");

        // ------------------------------------------------
        // TEST 3: RENAME R2 -> ROB TAG 5
        // ------------------------------------------------

        rename_enable = 1'b1;
        dest_arch     = 5'd2;
        dest_tag      = 3'b101;

        @(posedge clk);
        #1;

        rename_enable = 1'b0;

        src2_arch = 5'd2;
        #1;

        if ((src2_valid !== 1'b1) ||
            (src2_tag !== 3'b101))
            $display("ERROR: R2 rename failed. Valid=%b Tag=%b",
                     src2_valid, src2_tag);
        else
            $display("PASS: R2 mapped to ROB tag 5");

        // ------------------------------------------------
        // TEST 4: TWO MAPPINGS EXIST SIMULTANEOUSLY
        // ------------------------------------------------

        src1_arch = 5'd1;
        src2_arch = 5'd2;

        #1;

        if ((src1_valid !== 1'b1) ||
            (src1_tag !== 3'b011) ||
            (src2_valid !== 1'b1) ||
            (src2_tag !== 3'b101))
            $display("ERROR: Multiple RAT mappings failed");
        else
            $display("PASS: R1->3 and R2->5 exist simultaneously");

        // ------------------------------------------------
        // TEST 5: NEWER INSTRUCTION RENAMES R1
        // R1: ROB 3 -> ROB 6
        // ------------------------------------------------

        rename_enable = 1'b1;
        dest_arch     = 5'd1;
        dest_tag      = 3'b110;

        @(posedge clk);
        #1;

        rename_enable = 1'b0;

        src1_arch = 5'd1;
        #1;

        if ((src1_valid !== 1'b1) ||
            (src1_tag !== 3'b110))
            $display("ERROR: RAT mapping replacement failed. Tag=%b",
                     src1_tag);
        else
            $display("PASS: R1 remapped from ROB 3 to ROB 6");

        // ------------------------------------------------
        // TEST 6: OLD PRODUCER COMMITS
        // R1 still belongs to ROB 6
        //
        // Committing ROB 3 must NOT clear R1's
        // newer mapping to ROB 6.
        // ------------------------------------------------

        commit_enable = 1'b1;
        commit_arch   = 5'd1;
        commit_tag    = 3'b011;

        @(posedge clk);
        #1;

        commit_enable = 1'b0;

        src1_arch = 5'd1;
        #1;

        if ((src1_valid !== 1'b1) ||
            (src1_tag !== 3'b110))
            $display("ERROR: Old commit incorrectly cleared newer mapping");
        else
            $display("PASS: Old ROB 3 commit did not clear newer ROB 6 mapping");

        // ------------------------------------------------
        // TEST 7: CURRENT PRODUCER COMMITS
        // ROB 6 is the current producer of R1.
        // Its commit should clear the mapping.
        // ------------------------------------------------

        commit_enable = 1'b1;
        commit_arch   = 5'd1;
        commit_tag    = 3'b110;

        @(posedge clk);
        #1;

        commit_enable = 1'b0;

        src1_arch = 5'd1;
        #1;

        if (src1_valid !== 1'b0)
            $display("ERROR: Current commit failed to clear R1 mapping");
        else
            $display("PASS: Current ROB 6 commit cleared R1 mapping");

        // ------------------------------------------------
        // TEST 8: R2 MAPPING STILL EXISTS
        // ------------------------------------------------

        src2_arch = 5'd2;
        #1;

        if ((src2_valid !== 1'b1) ||
            (src2_tag !== 3'b101))
            $display("ERROR: R2 mapping was incorrectly affected");
        else
            $display("PASS: R2 mapping remains intact");

        // ------------------------------------------------
        // COMPLETE
        // ------------------------------------------------

        $display("--------------------------------");
        $display("RAT TESTBENCH COMPLETE");
        $display("--------------------------------");

        $finish;

    end

endmodule