module execution_unit #(
    parameter integer EXEC_LATENCY = 3
) (
    input  logic        clk,
    input  logic        reset,

    // Issue interface
    input  logic        issue_enable,
    input  logic [2:0]  issue_opcode,
    input  logic [31:0] issue_vj,
    input  logic [31:0] issue_vk,
    input  logic [2:0]  issue_rob_tag,

    // Execution status
    output logic        busy,

    // Result / CDB interface
    output logic        result_enable,
    output logic [31:0] result,
    output logic [2:0]  result_tag
);

    // ============================================================
    // Latched instruction
    // ============================================================

    logic [2:0]  opcode_reg;
    logic [31:0] vj_reg;
    logic [31:0] vk_reg;
    logic [2:0]  rob_tag_reg;

    integer cycle_count;


    // ============================================================
    // ALU signals
    // ============================================================

    logic        alu_result_enable;
    logic [31:0] alu_result;
    logic [2:0]  alu_result_tag;


    // ============================================================
    // ALU
    //
    // The ALU remains combinational.
    // The Execution Unit provides the timing/state around it.
    // ============================================================

    alu alu_unit (
        .enable        (busy),
        .A             (vj_reg),
        .B             (vk_reg),
        .opcode        (opcode_reg),
        .rob_tag       (rob_tag_reg),

        .result_enable (alu_result_enable),
        .result        (alu_result),
        .result_tag    (alu_result_tag)
    );


    // ============================================================
    // Execution state machine
    //
    // EXEC_LATENCY = 3
    //
    // Accept instruction
    //       ↓
    // Cycle 1
    //       ↓
    // Cycle 2
    //       ↓
    // Cycle 3
    //       ↓
    // Produce result
    //       ↓
    // Idle
    // ============================================================

    always_ff @(posedge clk) begin

        if (reset) begin

            busy         <= 1'b0;

            opcode_reg   <= 3'b000;
            vj_reg       <= 32'd0;
            vk_reg       <= 32'd0;
            rob_tag_reg  <= 3'b000;

            cycle_count  <= 0;

            result_enable <= 1'b0;
            result        <= 32'd0;
            result_tag    <= 3'b000;

        end

        else begin

            // Result is a one-cycle pulse.
            result_enable <= 1'b0;


            // ====================================================
            // IDLE
            // ====================================================

            if (!busy) begin

                if (issue_enable) begin

                    // Latch instruction
                    busy        <= 1'b1;

                    opcode_reg  <= issue_opcode;
                    vj_reg      <= issue_vj;
                    vk_reg      <= issue_vk;
                    rob_tag_reg <= issue_rob_tag;

                    // Start execution latency
                    cycle_count <= EXEC_LATENCY;

                end

            end


            // ====================================================
            // EXECUTING
            // ====================================================

            else begin

                // Still have execution cycles remaining
                if (cycle_count > 1) begin

                    cycle_count <= cycle_count - 1;

                end


                // Final execution cycle
                else begin

                    // Capture ALU result
                    result        <= alu_result;
                    result_tag    <= alu_result_tag;

                    // Broadcast result
                    result_enable <= 1'b1;

                    // Return to idle
                    busy         <= 1'b0;
                    cycle_count  <= 0;

                end

            end

        end

    end

endmodule