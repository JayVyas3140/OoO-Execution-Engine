module alu (
    input  logic        enable,

    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  opcode,

    // ROB tag belonging to the instruction being executed
    input  logic [2:0]  rob_tag,

    // Result sent toward the CDB
    output logic        result_enable,
    output logic [31:0] result,
    output logic [2:0]  result_tag
);

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_XOR = 3'b100;
    localparam OP_SLL = 3'b101;
    localparam OP_SRL = 3'b110;
    localparam OP_SLT = 3'b111;

    always_comb begin

        // Default outputs
        result        = 32'b0;
        result_tag    = rob_tag;
        result_enable = enable;

        case (opcode)

            OP_ADD: result = A + B;

            OP_SUB: result = A - B;

            OP_AND: result = A & B;

            OP_OR:  result = A | B;

            OP_XOR: result = A ^ B;

            OP_SLL: result = A << B;

            OP_SRL: result = A >> B;

            OP_SLT: result = (A < B) ? 32'd1 : 32'd0;

            default: result = 32'b0;

        endcase

    end

endmodule