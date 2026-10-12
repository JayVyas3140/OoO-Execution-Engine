module issue_unit (
    // From Reservation Station
    input  logic        rs_issue_enable,
    input  logic [2:0]  rs_opcode,
    input  logic [31:0] rs_vj,
    input  logic [31:0] rs_vk,
    input  logic [2:0]  rs_rob_tag,

    // To ALU
    output logic        issue_enable,
    output logic [2:0]  issue_opcode,
    output logic [31:0] issue_vj,
    output logic [31:0] issue_vk,
    output logic [2:0]  issue_rob_tag
);

    always_comb begin

        issue_enable  = rs_issue_enable;
        issue_opcode  = rs_opcode;
        issue_vj      = rs_vj;
        issue_vk      = rs_vk;
        issue_rob_tag = rs_rob_tag;

    end

endmodule