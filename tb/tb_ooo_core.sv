`timescale 1ns/1ps

module tb_ooo_core;

    logic        clk;
    logic        reset;
    logic        instr_valid;
    logic        instr_ready;
    logic [2:0]  instr_opcode;
    logic [4:0]  instr_src1;
    logic [4:0]  instr_src2;
    logic [4:0]  instr_dest;

    integer commit_log_count;
    integer commit_search_index;
    logic [2:0]  commit_log_tag   [0:31];
    logic [4:0]  commit_log_dest  [0:31];
    logic [31:0] commit_log_value [0:31];

    ooo_core dut (
        .clk          (clk),
        .reset        (reset),
        .instr_valid  (instr_valid),
        .instr_ready  (instr_ready),
        .instr_opcode (instr_opcode),
        .instr_src1   (instr_src1),
        .instr_src2   (instr_src2),
        .instr_dest   (instr_dest)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(negedge clk) begin
        if (!reset && dut.rob_commit_enable === 1'b1) begin
            if (commit_log_count < 32) begin
                commit_log_tag[commit_log_count]   = dut.rob_commit_tag;
                commit_log_dest[commit_log_count]  = dut.rob_commit_dest;
                commit_log_value[commit_log_count] = dut.rob_commit_value;
                commit_log_count = commit_log_count + 1;
            end
        end
    end

    task clear_commit_log;
    begin
        commit_log_count   = 0;
        commit_search_index = 0;
    end
    endtask

    task reset_dut;
    begin
        instr_valid  = 1'b0;
        instr_opcode = 3'b000;
        instr_src1   = 5'd0;
        instr_src2   = 5'd0;
        instr_dest   = 5'd0;
        reset        = 1'b1;

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;
        @(posedge clk);
        #1;
    end
    endtask

    // Hold the instruction until the top-level accepts it.
    // Acceptance occurs only when instr_valid && instr_ready.
    task send_instr(
        input logic [2:0] opcode,
        input logic [4:0] src1,
        input logic [4:0] src2,
        input logic [4:0] dest
    );
    begin
        @(negedge clk);

        instr_valid  = 1'b1;
        instr_opcode = opcode;
        instr_src1   = src1;
        instr_src2   = src2;
        instr_dest   = dest;

        while (instr_ready !== 1'b1)
            @(posedge clk);

        // instr_ready is sampled during this clock edge.
        @(posedge clk);
        #1;

        instr_valid  = 1'b0;
        instr_opcode = 3'b000;
        instr_src1   = 5'd0;
        instr_src2   = 5'd0;
        instr_dest   = 5'd0;
    end
    endtask

    task wait_for_commit(
        input logic [2:0]  expected_tag,
        input logic [4:0]  expected_dest,
        input logic [31:0] expected_value
    );
        integer i;
        integer timeout_count;
        logic found_commit;
    begin
        found_commit  = 1'b0;
        timeout_count = 0;

        while (!found_commit) begin
            for (i = commit_search_index; i < commit_log_count; i = i + 1) begin
                if ((commit_log_tag[i] === expected_tag) &&
                    (commit_log_dest[i] === expected_dest) &&
                    (commit_log_value[i] === expected_value)) begin
                    $display("PASS: COMMIT TAG = %0d", expected_tag);
                    $display("PASS: COMMIT DEST = R%0d", expected_dest);
                    $display("PASS: COMMIT VALUE = %0d", expected_value);
                    commit_search_index = i + 1;
                    found_commit = 1'b1;
                end
            end

            if (!found_commit) begin
                @(negedge clk);
                #1;
                timeout_count = timeout_count + 1;
                if (timeout_count > 100) begin
                    $display("ERROR: TIMEOUT WAITING FOR COMMIT");
                    $display("Expected TAG = %0d DEST = R%0d VALUE = %0d",
                             expected_tag, expected_dest, expected_value);
                    $finish;
                end
            end
        end
    end
    endtask

    task wait_for_commit_count(input integer expected_count);
        integer timeout_count;
    begin
        timeout_count = 0;
        while (commit_log_count < expected_count) begin
            @(negedge clk);
            #1;
            timeout_count = timeout_count + 1;
            if (timeout_count > 150) begin
                $display("ERROR: TIMEOUT WAITING FOR %0d COMMITS, GOT %0d",
                         expected_count, commit_log_count);
                $finish;
            end
        end
    end
    endtask

    task check_commit_value(
        input logic [4:0]  expected_dest,
        input logic [31:0] expected_value
    );
        integer i;
        logic found;
    begin
        found = 1'b0;
        for (i = 0; i < commit_log_count; i = i + 1) begin
            if ((commit_log_dest[i] === expected_dest) &&
                (commit_log_value[i] === expected_value)) begin
                found = 1'b1;
            end
        end

        if (found)
            $display("PASS: COMMIT R%0d = %0d", expected_dest, expected_value);
        else
            $display("ERROR: MISSING COMMIT R%0d = %0d",
                     expected_dest, expected_value);
    end
    endtask

    task test_basic;
    begin
        $display("");
        $display("========================================");
        $display("TEST 1: BASIC EXECUTION");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1] = 32'd10;
        dut.rf.registers[2] = 32'd20;

        send_instr(3'b000, 5'd1, 5'd2, 5'd3);
        wait_for_commit(3'd0, 5'd3, 32'd30);

    end
    endtask

    task test_raw;
    begin
        $display("");
        $display("========================================");
        $display("TEST 2: RAW DEPENDENCY");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1] = 32'd10;
        dut.rf.registers[2] = 32'd20;
        dut.rf.registers[5] = 32'd7;

        send_instr(3'b000, 5'd1, 5'd2, 5'd3);
        send_instr(3'b000, 5'd3, 5'd5, 5'd4);

        wait_for_commit(3'd0, 5'd3, 32'd30);
        wait_for_commit(3'd1, 5'd4, 32'd37);
    end
    endtask

    task test_independent;
    begin
        $display("");
        $display("========================================");
        $display("TEST 3: INDEPENDENT INSTRUCTIONS");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1] = 32'd10;
        dut.rf.registers[2] = 32'd20;
        dut.rf.registers[7] = 32'd12;
        dut.rf.registers[8] = 32'd30;

        send_instr(3'b000, 5'd1, 5'd2, 5'd3);
        send_instr(3'b000, 5'd7, 5'd8, 5'd6);

        wait_for_commit(3'd0, 5'd3, 32'd30);
        wait_for_commit(3'd1, 5'd6, 32'd42);

    end
    endtask

    task test_rob_order;
    begin
        $display("");
        $display("========================================");
        $display("TEST 4: ROB RETIREMENT ORDER");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1] = 32'd10;
        dut.rf.registers[2] = 32'd20;
        dut.rf.registers[4] = 32'd30;
        dut.rf.registers[5] = 32'd40;
        dut.rf.registers[7] = 32'd12;
        dut.rf.registers[8] = 32'd30;

        send_instr(3'b000, 5'd1, 5'd2, 5'd3);
        send_instr(3'b000, 5'd4, 5'd5, 5'd6);
        send_instr(3'b000, 5'd7, 5'd8, 5'd9);

        wait_for_commit(3'd0, 5'd3, 32'd30);
        wait_for_commit(3'd1, 5'd6, 32'd70);
        wait_for_commit(3'd2, 5'd9, 32'd42);

    end
    endtask

    task test_waw;
    begin
        $display("");
        $display("========================================");
        $display("TEST 5: WAW / REGISTER RENAMING");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1] = 32'd10;
        dut.rf.registers[2] = 32'd20;
        dut.rf.registers[4] = 32'd100;
        dut.rf.registers[5] = 32'd50;

        send_instr(3'b000, 5'd1, 5'd2, 5'd3);
        send_instr(3'b000, 5'd4, 5'd5, 5'd3);

        wait_for_commit(3'd0, 5'd3, 32'd30);
        wait_for_commit(3'd1, 5'd3, 32'd150);

    end
    endtask

    task test_multiple_inflight;
    begin
        $display("");
        $display("========================================");
        $display("TEST 6: MULTIPLE IN-FLIGHT INSTRUCTIONS");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1] = 32'd10;
        dut.rf.registers[2] = 32'd20;
        dut.rf.registers[4] = 32'd30;
        dut.rf.registers[5] = 32'd40;
        dut.rf.registers[7] = 32'd12;
        dut.rf.registers[8] = 32'd30;

        send_instr(3'b000, 5'd1, 5'd2, 5'd3);
        send_instr(3'b000, 5'd4, 5'd5, 5'd6);
        send_instr(3'b000, 5'd7, 5'd8, 5'd9);

        @(negedge clk);
        #1;
        if (dut.execution_busy === 1'b1)
            $display("PASS: Execution Unit occupied by in-flight instruction");
        else
            $display("ERROR: Execution Unit unexpectedly idle");

        wait_for_commit(3'd0, 5'd3, 32'd30);
        wait_for_commit(3'd1, 5'd6, 32'd70);
        wait_for_commit(3'd2, 5'd9, 32'd42);

    end
    endtask

    // This test deliberately presents a stream faster than the
    // four-entry RS can accept it. send_instr() must hold each
    // instruction until instr_ready goes high. Ten accepted
    // allocations also force ROB tag reuse: 0..7, then 0..1.
    task test_rob_wraparound;
        integer i;
        integer tag0_count;
        integer tag1_count;
    begin
        $display("");
        $display("========================================");
        $display("TEST 7: ROB WRAPAROUND + INPUT BACKPRESSURE");
        $display("========================================");
        clear_commit_log();
        reset_dut();

        dut.rf.registers[1]  = 32'd10;  dut.rf.registers[2]  = 32'd20;
        dut.rf.registers[4]  = 32'd30;  dut.rf.registers[5]  = 32'd40;
        dut.rf.registers[7]  = 32'd50;  dut.rf.registers[8]  = 32'd60;
        dut.rf.registers[10] = 32'd70;  dut.rf.registers[11] = 32'd80;
        dut.rf.registers[13] = 32'd90;  dut.rf.registers[14] = 32'd100;
        dut.rf.registers[16] = 32'd110; dut.rf.registers[17] = 32'd120;
        dut.rf.registers[19] = 32'd130; dut.rf.registers[20] = 32'd140;
        dut.rf.registers[22] = 32'd150; dut.rf.registers[23] = 32'd160;
        dut.rf.registers[25] = 32'd170; dut.rf.registers[26] = 32'd180;
        dut.rf.registers[28] = 32'd190; dut.rf.registers[29] = 32'd200;

        // Ten instructions are intentionally sent without waiting
        // for commits. The sender stalls only when the DUT says the
        // backend cannot accept another instruction.
        send_instr(3'b000, 5'd1,  5'd2,  5'd3);   // 30
        send_instr(3'b000, 5'd4,  5'd5,  5'd6);   // 70
        send_instr(3'b000, 5'd7,  5'd8,  5'd9);   // 110
        send_instr(3'b000, 5'd10, 5'd11, 5'd12);  // 150
        send_instr(3'b000, 5'd13, 5'd14, 5'd15);  // 190
        send_instr(3'b000, 5'd16, 5'd17, 5'd18);  // 230
        send_instr(3'b000, 5'd19, 5'd20, 5'd21);  // 270
        send_instr(3'b000, 5'd22, 5'd23, 5'd24);  // 310
        send_instr(3'b000, 5'd25, 5'd26, 5'd27);  // 350
        send_instr(3'b000, 5'd28, 5'd29, 5'd30);  // 390

        wait_for_commit_count(10);

        check_commit_value(5'd3,  32'd30);
        check_commit_value(5'd6,  32'd70);
        check_commit_value(5'd9,  32'd110);
        check_commit_value(5'd12, 32'd150);
        check_commit_value(5'd15, 32'd190);
        check_commit_value(5'd18, 32'd230);
        check_commit_value(5'd21, 32'd270);
        check_commit_value(5'd24, 32'd310);
        check_commit_value(5'd27, 32'd350);
        check_commit_value(5'd30, 32'd390);

        tag0_count = 0;
        tag1_count = 0;
        for (i = 0; i < commit_log_count; i = i + 1) begin
            if (commit_log_tag[i] === 3'd0) tag0_count = tag0_count + 1;
            if (commit_log_tag[i] === 3'd1) tag1_count = tag1_count + 1;
        end

        if ((tag0_count >= 2) && (tag1_count >= 2))
            $display("PASS: ROB TAG REUSE VERIFIED (0 and 1 reused)");
        else
            $display("ERROR: ROB TAG REUSE NOT OBSERVED: tag0=%0d tag1=%0d",
                     tag0_count, tag1_count);

        @(posedge clk);
        #1;

        if ((dut.rf.registers[18] === 32'd230) &&
            (dut.rf.registers[24] === 32'd310) &&
            (dut.rf.registers[30] === 32'd390))
            $display("PASS: BACKPRESSURE STREAM COMPLETED WITHOUT DROPPED INSTRUCTIONS");
        else
            $display("ERROR: BACKPRESSURE STREAM FINAL REGISTER CHECK FAILED");
    end
    endtask

    initial begin
        reset = 1'b0;
        instr_valid = 1'b0;
        instr_opcode = 3'b000;
        instr_src1 = 5'd0;
        instr_src2 = 5'd0;
        instr_dest = 5'd0;
        commit_log_count = 0;
        commit_search_index = 0;

        test_basic();
        test_raw();
        test_independent();
        test_rob_order();
        test_waw();
        test_multiple_inflight();
        test_rob_wraparound();

        $display("");
        $display("========================================");
        $display("ALL OOO CORE TESTS COMPLETE");
        $display("========================================");
        $finish;
    end

endmodule
