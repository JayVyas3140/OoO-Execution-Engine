module reservation_station (

    input  logic        clk,
    input  logic        reset,

    // ------------------------------------------------------------
    // Dispatch
    // ------------------------------------------------------------

    input  logic        dispatch_enable,
    input  logic [2:0]  dispatch_opcode,

    input  logic [31:0] dispatch_vj,
    input  logic [31:0] dispatch_vk,

    input  logic        dispatch_qj_valid,
    input  logic [2:0]  dispatch_qj,

    input  logic        dispatch_qk_valid,
    input  logic [2:0]  dispatch_qk,

    input  logic [2:0]  dispatch_rob_tag,

    // ------------------------------------------------------------
    // Common Data Bus
    // ------------------------------------------------------------

    input  logic        cdb_enable,
    input  logic [2:0]  cdb_tag,
    input  logic [31:0] cdb_value,

    // ------------------------------------------------------------
    // Issue control
    // ------------------------------------------------------------

    input  logic        issue_allow,

    // ------------------------------------------------------------
    // Dispatch status
    //
    // HIGH = at least one RS entry is available.
    // LOW  = all four RS entries are occupied.
    // ------------------------------------------------------------

    output logic        dispatch_ready,

    // ------------------------------------------------------------
    // Issue output
    // ------------------------------------------------------------

    output logic        issue_enable,
    output logic [2:0]  issue_opcode,
    output logic [31:0] issue_vj,
    output logic [31:0] issue_vk,
    output logic [2:0]  issue_rob_tag
);


    // ============================================================
    // RS ENTRY 0
    // ============================================================

    logic        busy0;
    logic [2:0]  opcode0;
    logic [31:0] vj0;
    logic [31:0] vk0;

    logic        qj_valid0;
    logic        qk_valid0;
    logic [2:0]  qj0;
    logic [2:0]  qk0;

    logic [2:0]  rob_tag0;


    // ============================================================
    // RS ENTRY 1
    // ============================================================

    logic        busy1;
    logic [2:0]  opcode1;
    logic [31:0] vj1;
    logic [31:0] vk1;

    logic        qj_valid1;
    logic        qk_valid1;
    logic [2:0]  qj1;
    logic [2:0]  qk1;

    logic [2:0]  rob_tag1;


    // ============================================================
    // RS ENTRY 2
    // ============================================================

    logic        busy2;
    logic [2:0]  opcode2;
    logic [31:0] vj2;
    logic [31:0] vk2;

    logic        qj_valid2;
    logic        qk_valid2;
    logic [2:0]  qj2;
    logic [2:0]  qk2;

    logic [2:0]  rob_tag2;


    // ============================================================
    // RS ENTRY 3
    // ============================================================

    logic        busy3;
    logic [2:0]  opcode3;
    logic [31:0] vj3;
    logic [31:0] vk3;

    logic        qj_valid3;
    logic        qk_valid3;
    logic [2:0]  qj3;
    logic [2:0]  qk3;

    logic [2:0]  rob_tag3;


    // ============================================================
    // DISPATCH READY
    //
    // The RS can accept an instruction whenever at least one
    // of its four entries is currently free.
    //
    // This uses the CURRENT state of the RS.
    //
    // If the RS is full but an instruction is being issued on
    // the same clock edge, dispatch_ready remains LOW for that
    // cycle. The following cycle sees the freed entry.
    //
    // This introduces at most one cycle of backpressure and,
    // more importantly, prevents an instruction from being
    // allocated into the ROB without somewhere to go in the RS.
    // ============================================================

    always_comb begin

        if (!busy0 ||
            !busy1 ||
            !busy2 ||
            !busy3) begin

            dispatch_ready = 1'b1;

        end
        else begin

            dispatch_ready = 1'b0;

        end

    end


    // ============================================================
    // ISSUE SELECTION
    //
    // The RS selects the first ready entry.
    //
    // issue_allow prevents an instruction from being removed
    // while the Execution Unit is busy.
    // ============================================================

    always_comb begin

        issue_enable  = 1'b0;
        issue_opcode  = 3'b000;
        issue_vj      = 32'd0;
        issue_vk      = 32'd0;
        issue_rob_tag = 3'b000;

        if (issue_allow) begin

            if (busy0 && !qj_valid0 && !qk_valid0) begin

                issue_enable  = 1'b1;
                issue_opcode  = opcode0;
                issue_vj      = vj0;
                issue_vk      = vk0;
                issue_rob_tag = rob_tag0;

            end

            else if (busy1 && !qj_valid1 && !qk_valid1) begin

                issue_enable  = 1'b1;
                issue_opcode  = opcode1;
                issue_vj      = vj1;
                issue_vk      = vk1;
                issue_rob_tag = rob_tag1;

            end

            else if (busy2 && !qj_valid2 && !qk_valid2) begin

                issue_enable  = 1'b1;
                issue_opcode  = opcode2;
                issue_vj      = vj2;
                issue_vk      = vk2;
                issue_rob_tag = rob_tag2;

            end

            else if (busy3 && !qj_valid3 && !qk_valid3) begin

                issue_enable  = 1'b1;
                issue_opcode  = opcode3;
                issue_vj      = vj3;
                issue_vk      = vk3;
                issue_rob_tag = rob_tag3;

            end

        end

    end


    // ============================================================
    // STATE UPDATE
    // ============================================================

    always_ff @(posedge clk) begin

        if (reset) begin

            busy0 <= 1'b0;
            busy1 <= 1'b0;
            busy2 <= 1'b0;
            busy3 <= 1'b0;

            opcode0 <= 3'b000;
            opcode1 <= 3'b000;
            opcode2 <= 3'b000;
            opcode3 <= 3'b000;

            vj0 <= 32'd0;
            vj1 <= 32'd0;
            vj2 <= 32'd0;
            vj3 <= 32'd0;

            vk0 <= 32'd0;
            vk1 <= 32'd0;
            vk2 <= 32'd0;
            vk3 <= 32'd0;

            qj_valid0 <= 1'b0;
            qj_valid1 <= 1'b0;
            qj_valid2 <= 1'b0;
            qj_valid3 <= 1'b0;

            qk_valid0 <= 1'b0;
            qk_valid1 <= 1'b0;
            qk_valid2 <= 1'b0;
            qk_valid3 <= 1'b0;

            qj0 <= 3'b000;
            qj1 <= 3'b000;
            qj2 <= 3'b000;
            qj3 <= 3'b000;

            qk0 <= 3'b000;
            qk1 <= 3'b000;
            qk2 <= 3'b000;
            qk3 <= 3'b000;

            rob_tag0 <= 3'b000;
            rob_tag1 <= 3'b000;
            rob_tag2 <= 3'b000;
            rob_tag3 <= 3'b000;

        end

        else begin

            // ====================================================
            // DISPATCH
            //
            // Dispatch is only accepted when dispatch_enable is
            // asserted by the top-level core.
            //
            // The core will only assert this after confirming
            // dispatch_ready.
            // ====================================================

            if (dispatch_enable) begin

                if (!busy0) begin

                    busy0   <= 1'b1;
                    opcode0 <= dispatch_opcode;

                    vj0 <= dispatch_vj;
                    vk0 <= dispatch_vk;

                    rob_tag0 <= dispatch_rob_tag;

                    // --------------------------------------------
                    // Same-cycle CDB capture
                    // --------------------------------------------

                    if (dispatch_qj_valid &&
                        cdb_enable &&
                        (dispatch_qj == cdb_tag)) begin

                        vj0       <= cdb_value;
                        qj_valid0 <= 1'b0;

                    end
                    else begin

                        qj_valid0 <= dispatch_qj_valid;

                    end


                    if (dispatch_qk_valid &&
                        cdb_enable &&
                        (dispatch_qk == cdb_tag)) begin

                        vk0       <= cdb_value;
                        qk_valid0 <= 1'b0;

                    end
                    else begin

                        qk_valid0 <= dispatch_qk_valid;

                    end

                    qj0 <= dispatch_qj;
                    qk0 <= dispatch_qk;

                end

                else if (!busy1) begin

                    busy1   <= 1'b1;
                    opcode1 <= dispatch_opcode;

                    vj1 <= dispatch_vj;
                    vk1 <= dispatch_vk;

                    rob_tag1 <= dispatch_rob_tag;

                    if (dispatch_qj_valid &&
                        cdb_enable &&
                        (dispatch_qj == cdb_tag)) begin

                        vj1       <= cdb_value;
                        qj_valid1 <= 1'b0;

                    end
                    else begin

                        qj_valid1 <= dispatch_qj_valid;

                    end


                    if (dispatch_qk_valid &&
                        cdb_enable &&
                        (dispatch_qk == cdb_tag)) begin

                        vk1       <= cdb_value;
                        qk_valid1 <= 1'b0;

                    end
                    else begin

                        qk_valid1 <= dispatch_qk_valid;

                    end

                    qj1 <= dispatch_qj;
                    qk1 <= dispatch_qk;

                end

                else if (!busy2) begin

                    busy2   <= 1'b1;
                    opcode2 <= dispatch_opcode;

                    vj2 <= dispatch_vj;
                    vk2 <= dispatch_vk;

                    rob_tag2 <= dispatch_rob_tag;

                    if (dispatch_qj_valid &&
                        cdb_enable &&
                        (dispatch_qj == cdb_tag)) begin

                        vj2       <= cdb_value;
                        qj_valid2 <= 1'b0;

                    end
                    else begin

                        qj_valid2 <= dispatch_qj_valid;

                    end


                    if (dispatch_qk_valid &&
                        cdb_enable &&
                        (dispatch_qk == cdb_tag)) begin

                        vk2       <= cdb_value;
                        qk_valid2 <= 1'b0;

                    end
                    else begin

                        qk_valid2 <= dispatch_qk_valid;

                    end

                    qj2 <= dispatch_qj;
                    qk2 <= dispatch_qk;

                end

                else if (!busy3) begin

                    busy3   <= 1'b1;
                    opcode3 <= dispatch_opcode;

                    vj3 <= dispatch_vj;
                    vk3 <= dispatch_vk;

                    rob_tag3 <= dispatch_rob_tag;

                    if (dispatch_qj_valid &&
                        cdb_enable &&
                        (dispatch_qj == cdb_tag)) begin

                        vj3       <= cdb_value;
                        qj_valid3 <= 1'b0;

                    end
                    else begin

                        qj_valid3 <= dispatch_qj_valid;

                    end


                    if (dispatch_qk_valid &&
                        cdb_enable &&
                        (dispatch_qk == cdb_tag)) begin

                        vk3       <= cdb_value;
                        qk_valid3 <= 1'b0;

                    end
                    else begin

                        qk_valid3 <= dispatch_qk_valid;

                    end

                    qj3 <= dispatch_qj;
                    qk3 <= dispatch_qk;

                end

            end


            // ====================================================
            // CDB WAKE-UP
            //
            // Wake existing RS entries.
            //
            // Newly dispatched entries are already handled above,
            // including the same-cycle CDB capture case.
            // ====================================================

            if (cdb_enable) begin

                if (busy0) begin

                    if (qj_valid0 && (qj0 == cdb_tag)) begin

                        vj0       <= cdb_value;
                        qj_valid0 <= 1'b0;

                    end

                    if (qk_valid0 && (qk0 == cdb_tag)) begin

                        vk0       <= cdb_value;
                        qk_valid0 <= 1'b0;

                    end

                end


                if (busy1) begin

                    if (qj_valid1 && (qj1 == cdb_tag)) begin

                        vj1       <= cdb_value;
                        qj_valid1 <= 1'b0;

                    end

                    if (qk_valid1 && (qk1 == cdb_tag)) begin

                        vk1       <= cdb_value;
                        qk_valid1 <= 1'b0;

                    end

                end


                if (busy2) begin

                    if (qj_valid2 && (qj2 == cdb_tag)) begin

                        vj2       <= cdb_value;
                        qj_valid2 <= 1'b0;

                    end

                    if (qk_valid2 && (qk2 == cdb_tag)) begin

                        vk2       <= cdb_value;
                        qk_valid2 <= 1'b0;

                    end

                end


                if (busy3) begin

                    if (qj_valid3 && (qj3 == cdb_tag)) begin

                        vj3       <= cdb_value;
                        qj_valid3 <= 1'b0;

                    end

                    if (qk_valid3 && (qk3 == cdb_tag)) begin

                        vk3       <= cdb_value;
                        qk_valid3 <= 1'b0;

                    end

                end

            end


            // ====================================================
            // REMOVE ISSUED INSTRUCTION
            //
            // The instruction is removed only when issue_allow is
            // asserted and the selected instruction is actually
            // being issued.
            // ====================================================

            if (issue_enable && issue_allow) begin

                if (busy0 && !qj_valid0 && !qk_valid0) begin

                    busy0 <= 1'b0;

                end

                else if (busy1 && !qj_valid1 && !qk_valid1) begin

                    busy1 <= 1'b0;

                end

                else if (busy2 && !qj_valid2 && !qk_valid2) begin

                    busy2 <= 1'b0;

                end

                else if (busy3 && !qj_valid3 && !qk_valid3) begin

                    busy3 <= 1'b0;

                end

            end

        end

    end

endmodule