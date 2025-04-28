module reg_file(
    input clk,
    input reset,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    input write_en,
    output reg [31:0] read_data1,
    output reg [31:0] read_data2
);

    reg [31:0] registers [0:31];
    integer i;
    
    // 初始化寄存器文件
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = i * 4;
        end
    end
    
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= i * 4;
            end
        end
        else if (write_en && write_reg != 0) begin
            registers[write_reg] <= write_data;
        end
    end
    
    always @(*) begin
        read_data1 = (read_reg1 == 0) ? 32'b0 : registers[read_reg1];
        read_data2 = (read_reg2 == 0) ? 32'b0 : registers[read_reg2];
    end
endmodule