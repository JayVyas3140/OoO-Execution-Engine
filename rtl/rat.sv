module rat (
    input  logic       clk,
    input  logic       reset,

    // Source register 1
    input  logic [4:0] src1_arch,
    output logic       src1_valid,
    output logic [2:0] src1_tag,

    // Source register 2
    input  logic [4:0] src2_arch,
    output logic       src2_valid,
    output logic [2:0] src2_tag,

    // Rename destination
    input  logic       rename_enable,
    input  logic [4:0] dest_arch,
    input  logic [2:0] dest_tag,

    // Commit information
    input  logic       commit_enable,
    input  logic [4:0] commit_arch,
    input  logic [2:0] commit_tag
);

    logic       mapping_valid [0:31];
    logic [2:0] mapping_tag   [0:31];

    integer i;

    // Combinational lookup
    always_comb begin

        src1_valid = mapping_valid[src1_arch];
        src1_tag   = mapping_tag[src1_arch];

        src2_valid = mapping_valid[src2_arch];
        src2_tag   = mapping_tag[src2_arch];

    end

    // Rename and commit updates
    always_ff @(posedge clk) begin

        if (reset) begin

            for (i = 0; i < 32; i = i + 1) begin
                mapping_valid[i] <= 1'b0;
                mapping_tag[i]   <= 3'b000;
            end

        end
        else begin

            // New instruction becomes the producer
            // of the destination register.
            if (rename_enable) begin
                mapping_valid[dest_arch] <= 1'b1;
                mapping_tag[dest_arch]   <= dest_tag;
            end

            // Remove the mapping when its producer commits.
            // Only clear it if the mapping still belongs
            // to that exact ROB entry.
            if (commit_enable) begin

                if (mapping_valid[commit_arch] &&
                    (mapping_tag[commit_arch] == commit_tag)) begin

                    mapping_valid[commit_arch] <= 1'b0;
                    mapping_tag[commit_arch]   <= 3'b000;

                end

            end

        end

    end

endmodule