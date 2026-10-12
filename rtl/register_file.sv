module register_file (
    input  logic        clk,

    input  logic [4:0]  read_addr1,
    input  logic [4:0]  read_addr2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    input  logic        write_enable,
    input  logic [4:0]  write_addr,
    input  logic [31:0] write_data
);

    logic [31:0] registers [0:31];

    // Combinational read ports.
    // Register 0 is permanently zero.
    always_comb begin

        if (read_addr1 == 5'd0)
            read_data1 = 32'd0;
        else
            read_data1 = registers[read_addr1];

        if (read_addr2 == 5'd0)
            read_data2 = 32'd0;
        else
            read_data2 = registers[read_addr2];

    end

    // Synchronous write port.
    // Writes to register 0 are ignored.
    always_ff @(posedge clk) begin

        if (write_enable && (write_addr != 5'd0))
            registers[write_addr] <= write_data;

    end

endmodule