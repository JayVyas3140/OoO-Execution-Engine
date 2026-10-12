`timescale 1ns/1ps

module tb_issue_unit;

    logic        rs_issue_enable;
    logic [2:0]  rs_opcode;
    logic [31:0] rs_vj;
    logic [31:0] rs_vk;
    logic [2:0]  rs_rob_tag;

    logic        issue_enable;
    logic [2:0]  issue_opcode;
    logic [31:0] issue_vj;
    logic [31:0] issue_vk;
    logic [2:0]  issue_rob_tag;


    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    issue_unit dut (
        .rs_issue_enable (rs_issue_enable),
        .rs_opcode       (rs_opcode),
        .rs_vj           (rs_vj),
        .rs_vk           (rs_vk),
        .rs_rob_tag      (rs_rob_tag),

        .issue_enable    (issue_enable),
        .issue_opcode    (issue_opcode),
        .issue_vj        (issue_vj),
        .issue_vk        (issue_vk),
        .issue_rob_tag   (issue_rob_tag)
    );


    // --------------------------------------------------
    // TEST
    // --------------------------------------------------

    initial begin

        // Default values
        rs_issue_enable = 1'b0;
        rs_opcode       = 3'b000;
        rs_vj           = 32'd0;
        rs_vk           = 32'd0;
        rs_rob_tag      = 3'b000;

        #1;


        // ==================================================
        // TEST 1: Disabled issue
        // ==================================================

        if (issue_enable !== 1'b0)
            $display("ERROR: Issue enable should be 0");

        else
            $display("PASS: Issue disabled correctly");


        // ==================================================
        // TEST 2: ADD instruction
        // ==================================================

        rs_issue_enable = 1'b1;
        rs_opcode       = 3'b000;
        rs_vj           = 32'd100;
        rs_vk           = 32'd50;
        rs_rob_tag      = 3'b011;

        #1;

        if ((issue_enable !== 1'b1) ||
            (issue_opcode !== 3'b000) ||
            (issue_vj !== 32'd100) ||
            (issue_vk !== 32'd50) ||
            (issue_rob_tag !== 3'b011))

            $display("ERROR: ADD instruction not passed correctly");

        else

            $display("PASS: ADD instruction passed correctly");


        // ==================================================
        // TEST 3: SUB instruction
        // ==================================================

        rs_opcode = 3'b001;
        rs_vj     = 32'd200;
        rs_vk     = 32'd75;
        rs_rob_tag = 3'b101;

        #1;

        if ((issue_opcode !== 3'b001) ||
            (issue_vj !== 32'd200) ||
            (issue_vk !== 32'd75) ||
            (issue_rob_tag !== 3'b101))

            $display("ERROR: SUB instruction not passed correctly");

        else

            $display("PASS: SUB instruction passed correctly");


        // ==================================================
        // TEST 4: Different operands and ROB tag
        // ==================================================

        rs_opcode = 3'b100;
        rs_vj     = 32'hAAAAAAAA;
        rs_vk     = 32'h55555555;
        rs_rob_tag = 3'b111;

        #1;

        if ((issue_opcode !== 3'b100) ||
            (issue_vj !== 32'hAAAAAAAA) ||
            (issue_vk !== 32'h55555555) ||
            (issue_rob_tag !== 3'b111))

            $display("ERROR: Operand/tag propagation failed");

        else

            $display("PASS: Operand and ROB tag propagation correct");


        // ==================================================
        // TEST 5: Disable again
        // ==================================================

        rs_issue_enable = 1'b0;

        #1;

        if (issue_enable !== 1'b0)

            $display("ERROR: Issue enable did not disable");

        else

            $display("PASS: Issue disabled correctly");


        // ==================================================
        // COMPLETE
        // ==================================================

        $display("--------------------------------");
        $display("ISSUE UNIT TESTBENCH COMPLETE");
        $display("--------------------------------");

        $finish;

    end

endmodule