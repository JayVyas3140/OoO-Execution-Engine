`timescale 1ns/1ps

module tb_execution_unit;

    logic        clk;
    logic        reset;

    logic        issue_enable;
    logic [2:0]  issue_opcode;
    logic [31:0] issue_vj;
    logic [31:0] issue_vk;
    logic [2:0]  issue_rob_tag;

    logic        busy;

    logic        result_enable;
    logic [31:0] result;
    logic [2:0]  result_tag;


    // ============================================================
    // DUT
    // ============================================================

    execution_unit #(
        .EXEC_LATENCY(3)
    ) dut (
        .clk           (clk),
        .reset         (reset),

        .issue_enable  (issue_enable),
        .issue_opcode  (issue_opcode),
        .issue_vj      (issue_vj),
        .issue_vk      (issue_vk),
        .issue_rob_tag (issue_rob_tag),

        .busy          (busy),

        .result_enable (result_enable),
        .result        (result),
        .result_tag    (result_tag)
    );


    // ============================================================
    // Clock
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // Main Testbench
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        issue_enable  = 1'b0;
        issue_opcode  = 3'b000;
        issue_vj      = 32'd0;
        issue_vk      = 32'd0;
        issue_rob_tag = 3'b000;

        reset = 1'b1;


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        reset = 1'b0;


        // ========================================================
        // TEST 1
        // ADD
        //
        // 10 + 20 = 30
        // ROB tag = 3
        //
        // Execution latency = 3 cycles
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 1: ADD");
        $display("----------------------------------------");

        @(negedge clk);

        issue_enable  = 1'b1;
        issue_opcode  = 3'b000;
        issue_vj      = 32'd10;
        issue_vk      = 32'd20;
        issue_rob_tag = 3'd3;

        // Accept instruction
        @(posedge clk);

        #1;

        issue_enable = 1'b0;

        if (busy === 1'b1)
            $display(
                "PASS: Instruction accepted and execution started"
            );
        else
            $display(
                "ERROR: Execution unit did not become busy"
            );


        // --------------------------------------------------------
        // Execution Cycle 1
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (busy === 1'b1)
            $display(
                "PASS: Execution cycle 1 active"
            );
        else
            $display(
                "ERROR: Execution ended too early"
            );

        if (result_enable === 1'b0)
            $display(
                "PASS: No result during execution cycle 1"
            );
        else
            $display(
                "ERROR: Result appeared too early"
            );


        // --------------------------------------------------------
        // Execution Cycle 2
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (busy === 1'b1)
            $display(
                "PASS: Execution cycle 2 active"
            );
        else
            $display(
                "ERROR: Execution ended too early"
            );

        if (result_enable === 1'b0)
            $display(
                "PASS: No result during execution cycle 2"
            );
        else
            $display(
                "ERROR: Result appeared too early"
            );


        // --------------------------------------------------------
        // Execution Cycle 3
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (result_enable === 1'b1)
            $display(
                "PASS: Result became available after 3 cycles"
            );
        else
            $display(
                "ERROR: Result was not produced after 3 cycles"
            );

        if (result === 32'd30)
            $display(
                "PASS: ALU result = 30"
            );
        else
            $display(
                "ERROR: Expected result 30, got %0d",
                result
            );

        if (result_tag === 3'd3)
            $display(
                "PASS: ROB tag preserved = 3"
            );
        else
            $display(
                "ERROR: Expected ROB tag 3, got %0d",
                result_tag
            );


        // --------------------------------------------------------
        // Verify return to idle
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (busy === 1'b0)
            $display(
                "PASS: Execution unit returned to idle"
            );
        else
            $display(
                "ERROR: Execution unit remained busy"
            );


        // ========================================================
        // TEST 2
        // SUB
        //
        // 50 - 8 = 42
        // ROB tag = 5
        //
        // Execution latency = 3 cycles
        // ========================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 2: SUB");
        $display("----------------------------------------");

        @(negedge clk);

        issue_enable  = 1'b1;
        issue_opcode  = 3'b001;
        issue_vj      = 32'd50;
        issue_vk      = 32'd8;
        issue_rob_tag = 3'd5;

        // Accept SUB instruction
        @(posedge clk);

        #1;

        issue_enable = 1'b0;

        if (busy === 1'b1)
            $display(
                "PASS: SUB instruction accepted"
            );
        else
            $display(
                "ERROR: SUB instruction was not accepted"
            );


        // --------------------------------------------------------
        // SUB Execution Cycle 1
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (busy === 1'b1)
            $display(
                "PASS: SUB execution cycle 1 active"
            );
        else
            $display(
                "ERROR: SUB execution ended too early"
            );

        if (result_enable === 1'b0)
            $display(
                "PASS: No SUB result during cycle 1"
            );
        else
            $display(
                "ERROR: SUB result appeared too early"
            );


        // --------------------------------------------------------
        // SUB Execution Cycle 2
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (busy === 1'b1)
            $display(
                "PASS: SUB execution cycle 2 active"
            );
        else
            $display(
                "ERROR: SUB execution ended too early"
            );

        if (result_enable === 1'b0)
            $display(
                "PASS: No SUB result during cycle 2"
            );
        else
            $display(
                "ERROR: SUB result appeared too early"
            );


        // --------------------------------------------------------
        // SUB Execution Cycle 3
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (result_enable === 1'b1)
            $display(
                "PASS: SUB result became available after 3 cycles"
            );
        else
            $display(
                "ERROR: SUB result timing incorrect"
            );

        if (result === 32'd42)
            $display(
                "PASS: SUB result = 42"
            );
        else
            $display(
                "ERROR: Expected SUB result 42, got %0d",
                result
            );

        if (result_tag === 3'd5)
            $display(
                "PASS: SUB ROB tag preserved = 5"
            );
        else
            $display(
                "ERROR: Expected SUB ROB tag 5, got %0d",
                result_tag
            );


        // --------------------------------------------------------
        // Verify SUB execution unit returns to idle
        // --------------------------------------------------------

        @(posedge clk);

        #1;

        if (busy === 1'b0)
            $display(
                "PASS: Execution unit idle after SUB"
            );
        else
            $display(
                "ERROR: Execution unit remained busy after SUB"
            );


        // ========================================================
        // Complete
        // ========================================================

        $display("");
        $display("========================================");
        $display("EXECUTION UNIT TESTBENCH COMPLETE");
        $display("========================================");

        $finish;

    end

endmodule