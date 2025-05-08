module data_memory(
    input clk,
    input reset,
    input [5:0] addr,
    input [31:0] write_data,
    input write_en,
    output reg [31:0] read_data
);

    reg [31:0] mem [0:63];
    integer i;
    
    // 初始化数据存储器
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            mem[i] = i * 4;
        end
    end
    
    // 仅处理写入操作 - 保持在下降沿
    always @(negedge clk) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                mem[i] <= i * 4;
            end
        end
        else if (write_en) begin
            mem[addr] <= write_data;
        end
    end
    
    // 纯组合逻辑读取 - 立即响应地址变化
    always @(*) begin
        read_data = mem[addr];
    end
endmodule