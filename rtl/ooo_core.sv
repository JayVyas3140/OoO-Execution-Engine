module ooo_core (
    input  logic        clk,
    input  logic        reset,

    input  logic        instr_valid,
    output logic        instr_ready,
    input  logic [2:0]  instr_opcode,
    input  logic [4:0]  instr_src1,
    input  logic [4:0]  instr_src2,
    input  logic [4:0]  instr_dest
);

    // ==================================================
    // ROB SIGNALS
    // ==================================================

    logic        rob_allocate_valid;
    logic [2:0]  rob_allocate_tag;

    logic        rob_full;
    logic        rob_empty;
    logic        rs_dispatch_ready;

    logic        rob_result_enable;
    logic [2:0]  rob_result_tag;
    logic [31:0] rob_result_value;

    logic        rob_commit_enable;
    logic [4:0]  rob_commit_dest;
    logic [31:0] rob_commit_value;
    logic [2:0]  rob_commit_tag;


    // ==================================================
    // RAT SIGNALS
    // ==================================================

    logic        rat_src1_valid;
    logic [2:0]  rat_src1_tag;

    logic        rat_src2_valid;
    logic [2:0]  rat_src2_tag;


    // ==================================================
    // REGISTER FILE SIGNALS
    // ==================================================

    logic [31:0] rf_src1_data;
    logic [31:0] rf_src2_data;


    // ==================================================
    // RESERVATION STATION SIGNALS
    // ==================================================

    logic        rs_dispatch_enable;
    logic [2:0]  rs_dispatch_opcode;

    logic [31:0] rs_dispatch_vj;
    logic [31:0] rs_dispatch_vk;

    logic        rs_dispatch_qj_valid;
    logic [2:0]  rs_dispatch_qj;

    logic        rs_dispatch_qk_valid;
    logic [2:0]  rs_dispatch_qk;

    logic [2:0]  rs_dispatch_rob_tag;


    logic        rs_issue_enable;
    logic [2:0]  rs_issue_opcode;
    logic [31:0] rs_issue_vj;
    logic [31:0] rs_issue_vk;
    logic [2:0]  rs_issue_rob_tag;


    // ==================================================
    // ISSUE UNIT SIGNALS
    // ==================================================

    logic        issue_enable;
    logic [2:0]  issue_opcode;
    logic [31:0] issue_vj;
    logic [31:0] issue_vk;
    logic [2:0]  issue_rob_tag;


    // ==================================================
    // EXECUTION UNIT SIGNALS
    // ==================================================

    logic        execution_busy;

    logic        execution_result_enable;
    logic [31:0] execution_result;
    logic [2:0]  execution_result_tag;


    // ==================================================
    // REGISTER FILE
    // ==================================================

    register_file rf (
        .clk          (clk),

        .read_addr1   (instr_src1),
        .read_addr2   (instr_src2),

        .read_data1   (rf_src1_data),
        .read_data2   (rf_src2_data),

        .write_enable (rob_commit_enable),
        .write_addr   (rob_commit_dest),
        .write_data   (rob_commit_value)
    );


    // ==================================================
    // RAT
    // ==================================================

    rat rat_unit (
        .clk           (clk),
        .reset         (reset),

        .src1_arch     (instr_src1),
        .src1_valid    (rat_src1_valid),
        .src1_tag      (rat_src1_tag),

        .src2_arch     (instr_src2),
        .src2_valid    (rat_src2_valid),
        .src2_tag      (rat_src2_tag),

        .rename_enable (rob_allocate_valid),
        .dest_arch     (instr_dest),
        .dest_tag      (rob_allocate_tag),

        .commit_enable (rob_commit_enable),
        .commit_arch   (rob_commit_dest),
        .commit_tag    (rob_commit_tag)
    );


    // ==================================================
    // REORDER BUFFER
    // ==================================================

    reorder_buffer rob (
        .clk             (clk),
        .reset           (reset),

        .allocate_enable (instr_valid && instr_ready),
        .allocate_dest   (instr_dest),

        .allocate_valid  (rob_allocate_valid),
        .allocate_tag    (rob_allocate_tag),

        .result_enable   (rob_result_enable),
        .result_tag      (rob_result_tag),
        .result_value    (rob_result_value),

        .commit_enable   (rob_commit_enable),
        .commit_dest     (rob_commit_dest),
        .commit_value    (rob_commit_value),
        .commit_tag      (rob_commit_tag),

        .full            (rob_full),
        .empty           (rob_empty)
    );


    // ==================================================
    // SOURCE OPERAND SELECTION
    //
    // If RAT contains a producer for a source register,
    // the source is represented by a ROB dependency tag.
    //
    // Otherwise, the current value is read directly
    // from the Register File.
    // ==================================================

    always_comb begin

        // --------------------------------------------------
        // Source 1
        // --------------------------------------------------

        if (rat_src1_valid) begin

            rs_dispatch_vj       = 32'd0;
            rs_dispatch_qj_valid = 1'b1;
            rs_dispatch_qj       = rat_src1_tag;

        end
        else begin

            rs_dispatch_vj       = rf_src1_data;
            rs_dispatch_qj_valid = 1'b0;
            rs_dispatch_qj       = 3'b000;

        end


        // --------------------------------------------------
        // Source 2
        // --------------------------------------------------

        if (rat_src2_valid) begin

            rs_dispatch_vk       = 32'd0;
            rs_dispatch_qk_valid = 1'b1;
            rs_dispatch_qk       = rat_src2_tag;

        end
        else begin

            rs_dispatch_vk       = rf_src2_data;
            rs_dispatch_qk_valid = 1'b0;
            rs_dispatch_qk       = 3'b000;

        end

    end


    // ==================================================
    // RESERVATION STATION CONTROL
    // ==================================================

    // A new instruction is dispatched only when the ROB
    // successfully allocates an entry.

    assign instr_ready = rs_dispatch_ready && !rob_full;

    assign rs_dispatch_enable = rob_allocate_valid;

    assign rs_dispatch_opcode = instr_opcode;

    assign rs_dispatch_rob_tag = rob_allocate_tag;


    // --------------------------------------------------
    // Execution-unit backpressure
    //
    // The RS may issue only when the Execution Unit is idle.
    // --------------------------------------------------

    logic rs_issue_allow;

    assign rs_issue_allow = !execution_busy;


    // ==================================================
    // RESERVATION STATION
    // ==================================================

    reservation_station rs (
        .clk               (clk),
        .reset             (reset),

        .dispatch_enable   (rs_dispatch_enable),
        .dispatch_opcode   (rs_dispatch_opcode),

        .dispatch_vj       (rs_dispatch_vj),
        .dispatch_vk       (rs_dispatch_vk),

        .dispatch_qj_valid (rs_dispatch_qj_valid),
        .dispatch_qj       (rs_dispatch_qj),

        .dispatch_qk_valid (rs_dispatch_qk_valid),
        .dispatch_qk       (rs_dispatch_qk),

        .dispatch_rob_tag  (rs_dispatch_rob_tag),

        // CDB
        .cdb_enable        (execution_result_enable),
        .cdb_tag           (execution_result_tag),
        .cdb_value         (execution_result),

        // Issue control
        .issue_allow       (rs_issue_allow),

        .dispatch_ready    (rs_dispatch_ready),

        // Issue output
        .issue_enable      (rs_issue_enable),
        .issue_opcode      (rs_issue_opcode),
        .issue_vj          (rs_issue_vj),
        .issue_vk          (rs_issue_vk),
        .issue_rob_tag     (rs_issue_rob_tag)
    );


    // ==================================================
    // ISSUE UNIT
    // ==================================================

    issue_unit issue (
        .rs_issue_enable (rs_issue_enable),
        .rs_opcode       (rs_issue_opcode),
        .rs_vj           (rs_issue_vj),
        .rs_vk           (rs_issue_vk),
        .rs_rob_tag      (rs_issue_rob_tag),

        .issue_enable    (issue_enable),
        .issue_opcode    (issue_opcode),
        .issue_vj        (issue_vj),
        .issue_vk        (issue_vk),
        .issue_rob_tag   (issue_rob_tag)
    );


    // ==================================================
    // EXECUTION UNIT
    //
    // The Execution Unit provides the 3-cycle execution
    // latency around the combinational ALU.
    //
    // Issue:
    //
    //     Issue Unit
    //          ↓
    //     Execution Unit
    //          ↓
    //         ALU
    //
    // Result:
    //
    //         ALU
    //          ↓
    //     Execution Unit
    //          ↓
    //         CDB
    // ==================================================

    execution_unit #(
        .EXEC_LATENCY(3)
    ) execution (
        .clk           (clk),
        .reset         (reset),

        .issue_enable  (issue_enable),
        .issue_opcode  (issue_opcode),
        .issue_vj      (issue_vj),
        .issue_vk      (issue_vk),
        .issue_rob_tag (issue_rob_tag),

        .busy          (execution_busy),

        .result_enable (execution_result_enable),
        .result        (execution_result),
        .result_tag    (execution_result_tag)
    );


    // ==================================================
    // CDB → ROB
    //
    // Execution Unit result is broadcast to the ROB.
    // ==================================================

    assign rob_result_enable = execution_result_enable;
    assign rob_result_tag    = execution_result_tag;
    assign rob_result_value  = execution_result;


endmodule