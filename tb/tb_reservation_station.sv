`timescale 1ns/1ps

module tb_reservation_station;

    logic clk;
    logic reset;

    // --------------------------------------------------
    // DISPATCH
    // --------------------------------------------------

    logic        dispatch_enable;
    logic [2:0]  dispatch_opcode;

    logic [31:0] dispatch_vj;
    logic [31:0] dispatch_vk;

    logic        dispatch_qj_valid;
    logic [2:0]  dispatch_qj;

    logic        dispatch_qk_valid;
    logic [2:0]  dispatch_qk;

    logic [2:0]  dispatch_rob_tag;

    // --------------------------------------------------
    // COMMON DATA BUS
    // --------------------------------------------------

    logic        cdb_enable;
    logic [2:0]  cdb_tag;
    logic [31:0] cdb_value;

    // --------------------------------------------------
    // ISSUE
    // --------------------------------------------------

    logic        issue_allow;

    logic        issue_enable;
    logic [2:0]  issue_opcode;
    logic [31:0] issue_vj;
    logic [31:0] issue_vk;
    logic [2:0]  issue_rob_tag;


    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    reservation_station dut (

        .clk               (clk),
        .reset             (reset),

        .dispatch_enable   (dispatch_enable),
        .dispatch_opcode   (dispatch_opcode),

        .dispatch_vj       (dispatch_vj),
        .dispatch_vk       (dispatch_vk),

        .dispatch_qj_valid (dispatch_qj_valid),
        .dispatch_qj       (dispatch_qj),

        .dispatch_qk_valid (dispatch_qk_valid),
        .dispatch_qk       (dispatch_qk),

        .dispatch_rob_tag  (dispatch_rob_tag),

        .cdb_enable        (cdb_enable),
        .cdb_tag           (cdb_tag),
        .cdb_value         (cdb_value),

        .issue_allow       (issue_allow),

        .issue_enable      (issue_enable),
        .issue_opcode      (issue_opcode),
        .issue_vj          (issue_vj),
        .issue_vk          (issue_vk),
        .issue_rob_tag     (issue_rob_tag)
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

        clk               = 1'b0;
        reset             = 1'b1;

        dispatch_enable   = 1'b0;
        dispatch_opcode   = 3'b000;

        dispatch_vj       = 32'd0;
        dispatch_vk       = 32'd0;

        dispatch_qj_valid = 1'b0;
        dispatch_qj       = 3'b000;

        dispatch_qk_valid = 1'b0;
        dispatch_qk       = 3'b000;

        dispatch_rob_tag  = 3'b000;

        cdb_enable        = 1'b0;
        cdb_tag           = 3'b000;
        cdb_value         = 32'd0;

        // Execution Unit is initially allowed to accept
        // an instruction.
        issue_allow       = 1'b1;


        // ==================================================
        // TEST 1: RESET
        // ==================================================

        #10;

        reset = 1'b0;

        #1;

        if (issue_enable !== 1'b0)
            $display("ERROR: RS reset failed");
        else
            $display("PASS: RS reset");


        // ==================================================
        // TEST 2: ISSUE BACKPRESSURE
        //
        // A ready instruction is dispatched while
        // issue_allow = 0.
        //
        // The instruction must remain inside the RS.
        //
        // Once issue_allow becomes 1, the instruction
        // should become available for issue.
        // ==================================================

        issue_allow = 1'b0;

        dispatch_enable   = 1'b1;

        dispatch_opcode   = 3'b000;       // ADD

        dispatch_vj       = 32'd15;
        dispatch_vk       = 32'd25;

        dispatch_qj_valid = 1'b0;
        dispatch_qj       = 3'b000;

        dispatch_qk_valid = 1'b0;
        dispatch_qk       = 3'b000;

        dispatch_rob_tag  = 3'b001;


        @(posedge clk);
        #1;

        dispatch_enable = 1'b0;


        if (issue_enable !== 1'b0)

            $display("ERROR: RS issued instruction while issue_allow = 0");

        else

            $display("PASS: Ready instruction held while execution unit is busy");


        // Allow the instruction to issue.

        issue_allow = 1'b1;

        #1;


        if ((issue_enable  !== 1'b1) ||
            (issue_opcode  !== 3'b000) ||
            (issue_vj      !== 32'd15) ||
            (issue_vk      !== 32'd25) ||
            (issue_rob_tag !== 3'b001))

            $display("ERROR: Held instruction did not issue after issue_allow");

        else

            $display("PASS: Held instruction issued after execution unit became available");


        // Remove the instruction.

        @(posedge clk);
        #1;


        if (issue_enable !== 1'b0)

            $display("ERROR: Backpressure test instruction was not removed");

        else

            $display("PASS: Backpressure test instruction removed correctly");


        // ==================================================
        // TEST 3: READY INSTRUCTION
        //
        // ADD 10 + 20
        //
        // No dependencies.
        // ROB tag = 1
        // ==================================================

        dispatch_enable   = 1'b1;

        dispatch_opcode   = 3'b000;       // ADD

        dispatch_vj       = 32'd10;
        dispatch_vk       = 32'd20;

        dispatch_qj_valid = 1'b0;
        dispatch_qj       = 3'b000;

        dispatch_qk_valid = 1'b0;
        dispatch_qk       = 3'b000;

        dispatch_rob_tag  = 3'b001;


        @(posedge clk);
        #1;

        dispatch_enable = 1'b0;


        if ((issue_enable  !== 1'b1) ||
            (issue_opcode  !== 3'b000) ||
            (issue_vj      !== 32'd10) ||
            (issue_vk      !== 32'd20) ||
            (issue_rob_tag !== 3'b001))

            $display("ERROR: Ready instruction dispatch/issue failed");

        else

            $display("PASS: Ready instruction dispatched and selected");


        // The instruction should be removed
        // at the next clock edge.

        @(posedge clk);
        #1;


        if (issue_enable !== 1'b0)

            $display("ERROR: Issued instruction was not removed");

        else

            $display("PASS: Issued instruction removed from RS");


        // ==================================================
        // TEST 4: ONE OPERAND WAITING
        //
        // ADD ?
        //
        // Vj waits for ROB tag 2.
        // Vk = 7 is already available.
        //
        // Instruction ROB tag = 3
        // ==================================================

        dispatch_enable   = 1'b1;

        dispatch_opcode   = 3'b000;       // ADD

        dispatch_vj       = 32'd0;
        dispatch_vk       = 32'd7;

        dispatch_qj_valid = 1'b1;
        dispatch_qj       = 3'b010;       // ROB 2

        dispatch_qk_valid = 1'b0;
        dispatch_qk       = 3'b000;

        dispatch_rob_tag  = 3'b011;       // ROB 3


        @(posedge clk);
        #1;

        dispatch_enable = 1'b0;


        if (issue_enable !== 1'b0)

            $display("ERROR: RS issued instruction with missing operand");

        else

            $display("PASS: Instruction waits for dependent operand");


        // ==================================================
        // TEST 5: CDB WAKE-UP
        //
        // ROB tag 2 produces value 50.
        //
        // Vj should become 50.
        // The instruction should become ready.
        // ==================================================

        cdb_enable = 1'b1;
        cdb_tag    = 3'b010;
        cdb_value  = 32'd50;


        @(posedge clk);
        #1;

        cdb_enable = 1'b0;


        if ((issue_enable  !== 1'b1) ||
            (issue_vj      !== 32'd50) ||
            (issue_vk      !== 32'd7) ||
            (issue_rob_tag !== 3'b011))

            $display("ERROR: CDB wakeup failed");

        else

            $display("PASS: CDB woke dependent operand");


        // Remove the instruction.

        @(posedge clk);
        #1;


        if (issue_enable !== 1'b0)

            $display("ERROR: Woken instruction was not removed");

        else

            $display("PASS: Woken instruction issued and removed");


        // ==================================================
        // TEST 6: TWO OPERANDS WAITING
        //
        // SUB ?
        //
        // Vj waits for ROB 4.
        // Vk waits for ROB 5.
        //
        // Instruction ROB tag = 6
        // ==================================================

        dispatch_enable   = 1'b1;

        dispatch_opcode   = 3'b001;       // SUB

        dispatch_vj       = 32'd0;
        dispatch_vk       = 32'd0;

        dispatch_qj_valid = 1'b1;
        dispatch_qj       = 3'b100;       // ROB 4

        dispatch_qk_valid = 1'b1;
        dispatch_qk       = 3'b101;       // ROB 5

        dispatch_rob_tag  = 3'b110;       // ROB 6


        @(posedge clk);
        #1;

        dispatch_enable = 1'b0;


        if (issue_enable !== 1'b0)

            $display("ERROR: Instruction issued with two missing operands");

        else

            $display("PASS: Instruction waits for both operands");


        // ==================================================
        // TEST 7: FIRST OPERAND ARRIVES
        //
        // ROB 4 -> 100
        //
        // ROB 5 is still missing.
        // Therefore instruction must NOT issue.
        // ==================================================

        cdb_enable = 1'b1;
        cdb_tag    = 3'b100;
        cdb_value  = 32'd100;


        @(posedge clk);
        #1;

        cdb_enable = 1'b0;


        if (issue_enable !== 1'b0)

            $display("ERROR: Instruction issued before second operand");

        else

            $display("PASS: First operand captured, second still pending");


        // ==================================================
        // TEST 8: SECOND OPERAND ARRIVES
        //
        // ROB 5 -> 25
        //
        // Now both operands are ready.
        // ==================================================

        cdb_enable = 1'b1;
        cdb_tag    = 3'b101;
        cdb_value  = 32'd25;


        @(posedge clk);
        #1;

        cdb_enable = 1'b0;


        if ((issue_enable  !== 1'b1) ||
            (issue_opcode  !== 3'b001) ||
            (issue_vj      !== 32'd100) ||
            (issue_vk      !== 32'd25) ||
            (issue_rob_tag !== 3'b110))

            $display("ERROR: Two-operand CDB wakeup failed");

        else

            $display("PASS: Both operands captured and instruction became ready");


        // Remove instruction.

        @(posedge clk);
        #1;


        // ==================================================
        // TEST 9: MULTIPLE DEPENDENT ENTRIES
        //
        // Entry 0:
        //   ADD
        //   Vj waits for ROB 1
        //   Vk = 10
        //   Instruction ROB tag = 2
        //
        // Entry 1:
        //   AND
        //   Vj waits for ROB 1
        //   Vk = 7
        //   Instruction ROB tag = 3
        //
        // Both depend on ROB 1.
        //
        // One CDB broadcast should wake BOTH entries.
        //
        // Entry 0 has priority because the issue logic
        // checks entry 0 before entry 1.
        // ==================================================


        // --------------------------------------------------
        // Dispatch instruction into entry 0
        // --------------------------------------------------

        dispatch_enable   = 1'b1;

        dispatch_opcode   = 3'b000;       // ADD

        dispatch_vj       = 32'd0;
        dispatch_vk       = 32'd10;

        dispatch_qj_valid = 1'b1;
        dispatch_qj       = 3'b001;       // ROB 1

        dispatch_qk_valid = 1'b0;
        dispatch_qk       = 3'b000;

        dispatch_rob_tag  = 3'b010;       // ROB 2


        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Dispatch instruction into entry 1
        // --------------------------------------------------

        dispatch_opcode   = 3'b010;       // AND

        dispatch_vj       = 32'd0;
        dispatch_vk       = 32'd7;

        dispatch_qj_valid = 1'b1;
        dispatch_qj       = 3'b001;       // ROB 1

        dispatch_qk_valid = 1'b0;
        dispatch_qk       = 3'b000;

        dispatch_rob_tag  = 3'b011;       // ROB 3


        @(posedge clk);
        #1;

        dispatch_enable = 1'b0;


        // Neither instruction should be ready yet.

        if (issue_enable !== 1'b0)

            $display("ERROR: Waiting instructions became ready too early");

        else

            $display("PASS: Multiple dependent instructions waiting");


        // ==================================================
        // BROADCAST ROB 1
        //
        // Both entries should wake up.
        // ==================================================

        cdb_enable = 1'b1;
        cdb_tag    = 3'b001;
        cdb_value  = 32'd50;


        @(posedge clk);
        #1;

        cdb_enable = 1'b0;


        // --------------------------------------------------
        // Entry 0 should have priority.
        // --------------------------------------------------

        if ((issue_enable  !== 1'b1) ||
            (issue_opcode  !== 3'b000) ||
            (issue_vj      !== 32'd50) ||
            (issue_vk      !== 32'd10) ||
            (issue_rob_tag !== 3'b010))

            $display("ERROR: First ready RS entry was not selected");

        else

            $display("PASS: First ready RS entry selected");


        // Entry 0 is removed here.

        @(posedge clk);
        #1;


        // --------------------------------------------------
        // Entry 1 should now be selected.
        // --------------------------------------------------

        if ((issue_enable  !== 1'b1) ||
            (issue_opcode  !== 3'b010) ||
            (issue_vj      !== 32'd50) ||
            (issue_vk      !== 32'd7) ||
            (issue_rob_tag !== 3'b011))

            $display("ERROR: Second ready RS entry was not selected");

        else

            $display("PASS: Second ready RS entry selected");


        // Remove entry 1.

        @(posedge clk);
        #1;


        if (issue_enable !== 1'b0)

            $display("ERROR: Second issued instruction was not removed");

        else

            $display("PASS: Both ready entries issued correctly");


        // ==================================================
        // COMPLETE
        // ==================================================

        $display("--------------------------------");
        $display("RESERVATION STATION TESTBENCH COMPLETE");
        $display("--------------------------------");

        $finish;

    end

endmodule