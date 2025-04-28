module sign_extend(
    input [15:0] in,
    output reg [31:0] out
);

    always @(*) begin
        out = {{16{in[15]}}, in};
    end
endmodule

module zero_extend(
    input [15:0] in,
    output reg [31:0] out
);

    always @(*) begin
        out = {16'b0, in};
    end
endmodule