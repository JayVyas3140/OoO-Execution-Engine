module reorder_buffer (
    input  logic        clk,
    input  logic        reset,

    // Allocate a new instruction
    input  logic        allocate_enable,
    input  logic [4:0]  allocate_dest,
    output logic        allocate_valid,
    output logic [2:0]  allocate_tag,

    // Execution result / CDB
    input  logic        result_enable,
    input  logic [2:0]  result_tag,
    input  logic [31:0] result_value,

    // Commit
    output logic        commit_enable,
    output logic [4:0]  commit_dest,
    output logic [31:0] commit_value,
    output logic [2:0]  commit_tag,

    // Status
    output logic        full,
    output logic        empty
);

    // --------------------------------------------------
    // ROB ENTRY STORAGE
    // --------------------------------------------------

    logic        busy  [0:7];
    logic        ready [0:7];

    logic [4:0]  dest  [0:7];
    logic [31:0] value [0:7];

    // Oldest instruction
    logic [2:0] head;

    // Next free entry
    logic [2:0] tail;

    // Number of occupied entries
    logic [3:0] count;

    integer i;


    // --------------------------------------------------
    // STATUS
    // --------------------------------------------------

    always_comb begin

        empty = (count == 4'd0);
        full  = (count == 4'd8);

    end


    // --------------------------------------------------
    // ALLOCATION
    // --------------------------------------------------

    always_comb begin

        allocate_valid = allocate_enable && !full;
        allocate_tag   = tail;

    end


    // --------------------------------------------------
    // COMMIT
    // --------------------------------------------------

    always_comb begin

        commit_enable = 1'b0;
        commit_dest   = 5'b00000;
        commit_value  = 32'b0;
        commit_tag    = head;

        // Only the oldest ROB entry can commit.
        if (!empty && busy[head] && ready[head]) begin

            commit_enable = 1'b1;
            commit_dest   = dest[head];
            commit_value  = value[head];

        end

    end


    // --------------------------------------------------
    // ROB STATE
    // --------------------------------------------------

    always_ff @(posedge clk) begin

        if (reset) begin

            head  <= 3'b000;
            tail  <= 3'b000;
            count <= 4'd0;

            for (i = 0; i < 8; i = i + 1) begin

                busy[i]  <= 1'b0;
                ready[i] <= 1'b0;
                dest[i]  <= 5'b00000;
                value[i] <= 32'b0;

            end

        end

        else begin

            // ------------------------------------------
            // ALLOCATE
            // ------------------------------------------

            if (allocate_valid) begin

                busy[tail]  <= 1'b1;
                ready[tail] <= 1'b0;
                dest[tail]  <= allocate_dest;
                value[tail] <= 32'b0;

                tail <= tail + 3'd1;

            end


            // ------------------------------------------
            // RESULT WRITEBACK
            // ------------------------------------------

            if (result_enable) begin

                value[result_tag] <= result_value;
                ready[result_tag] <= 1'b1;

            end


            // ------------------------------------------
            // COMMIT
            // ------------------------------------------

            if (commit_enable) begin

                busy[head]  <= 1'b0;
                ready[head] <= 1'b0;

                head <= head + 3'd1;

            end


            // ------------------------------------------
            // OCCUPANCY COUNT
            // ------------------------------------------

            if (allocate_valid && !commit_enable) begin

                count <= count + 4'd1;

            end

            else if (!allocate_valid && commit_enable) begin

                count <= count - 4'd1;

            end

        end

    end

endmodule