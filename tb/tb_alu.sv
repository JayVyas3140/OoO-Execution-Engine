`timescale 1ns/1ps

module tb_alu;

    logic        enable;
    logic [31:0] A;
    logic [31:0] B;
    logic [2:0]  opcode;
    logic [2:0]  rob_tag;

    logic        result_enable;
    logic [31:0] result;
    logic [2:0]  result_tag;

    // --------------------------------------------------
    // ALU DUT
    // --------------------------------------------------

    alu dut (
        .enable        (enable),

        .A             (A),
        .B             (B),
        .opcode        (opcode),

        .rob_tag       (rob_tag),

        .result_enable (result_enable),
        .result        (result),
        .result_tag    (result_tag)
    );

    // --------------------------------------------------
    // Test
    // --------------------------------------------------

    initial begin

        enable  = 1'b0;
        A       = 32'd0;
        B       = 32'd0;
        opcode  = 3'b000;
        rob_tag = 3'b000;

        #10;

        // --------------------------------------------------
        // ADD
        // --------------------------------------------------

        enable  = 1'b1;
        A       = 32'd5;
        B       = 32'd7;
        opcode  = 3'b000;
        rob_tag = 3'b001;

        #10;

        if (result !== 32'd12)
            $display("ERROR: ADD failed. Expected 12, got %d", result);
        else
            $display("PASS: ADD");

        // --------------------------------------------------
        // SUB
        // --------------------------------------------------

        A       = 32'd10;
        B       = 32'd4;
        opcode  = 3'b001;
        rob_tag = 3'b010;

        #10;

        if (result !== 32'd6)
            $display("ERROR: SUB failed. Expected 6, got %d", result);
        else
            $display("PASS: SUB");

        // --------------------------------------------------
        // AND
        // --------------------------------------------------

        A       = 32'b1010;
        B       = 32'b1100;
        opcode  = 3'b010;
        rob_tag = 3'b011;

        #10;

        if (result !== 32'b1000)
            $display("ERROR: AND failed");
        else
            $display("PASS: AND");

        // --------------------------------------------------
        // OR
        // --------------------------------------------------

        A       = 32'b1010;
        B       = 32'b1100;
        opcode  = 3'b011;
        rob_tag = 3'b100;

        #10;

        if (result !== 32'b1110)
            $display("ERROR: OR failed");
        else
            $display("PASS: OR");

        // --------------------------------------------------
        // XOR
        // --------------------------------------------------

        A       = 32'b1010;
        B       = 32'b1100;
        opcode  = 3'b100;
        rob_tag = 3'b101;

        #10;

        if (result !== 32'b0110)
            $display("ERROR: XOR failed");
        else
            $display("PASS: XOR");

        // --------------------------------------------------
        // SLL
        // --------------------------------------------------

        A       = 32'd5;
        B       = 32'd2;
        opcode  = 3'b101;
        rob_tag = 3'b110;

        #10;

        if (result !== 32'd20)
            $display("ERROR: SLL failed. Expected 20, got %d", result);
        else
            $display("PASS: SLL");

        // --------------------------------------------------
        // SRL
        // --------------------------------------------------

        A       = 32'd20;
        B       = 32'd2;
        opcode  = 3'b110;
        rob_tag = 3'b111;

        #10;

        if (result !== 32'd5)
            $display("ERROR: SRL failed. Expected 5, got %d", result);
        else
            $display("PASS: SRL");

        // --------------------------------------------------
        // SLT: A < B
        // --------------------------------------------------

        A       = 32'd5;
        B       = 32'd7;
        opcode  = 3'b111;
        rob_tag = 3'b001;

        #10;

        if (result !== 32'd1)
            $display("ERROR: SLT failed for A < B");
        else
            $display("PASS: SLT (A < B)");

        // --------------------------------------------------
        // SLT: A >= B
        // --------------------------------------------------

        A = 32'd10;
        B = 32'd7;

        #10;

        if (result !== 32'd0)
            $display("ERROR: SLT failed for A >= B");
        else
            $display("PASS: SLT (A >= B)");

        // --------------------------------------------------
        // ENABLE
        // --------------------------------------------------

        enable = 1'b0;

        #10;

        if (result_enable !== 1'b0)
            $display("ERROR: result_enable should be 0");
        else
            $display("PASS: ENABLE");

        // --------------------------------------------------
        // ROB TAG propagation
        // --------------------------------------------------

        enable  = 1'b1;
        A       = 32'd10;
        B       = 32'd20;
        opcode  = 3'b000;
        rob_tag = 3'b101;
  
        #10;

        if (result_tag !== 3'b101)
            $display("ERROR: ROB tag propagation failed");
        else
            $display("PASS: ROB TAG");

        // --------------------------------------------------
        // Test complete
        // --------------------------------------------------

        $display("--------------------------------");
        $display("ALU TESTBENCH COMPLETE");
        $display("--------------------------------");

        $finish;

    end

endmodule