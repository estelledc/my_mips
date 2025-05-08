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
    
    // ��ʼ�����ݴ洢��
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            mem[i] = i * 4;
        end
    end
    
    // ������д����� - �������½���
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                mem[i] <= i * 4;
            end
        end
        else if (write_en) begin
            mem[addr] <= write_data;
        end
    end
    
    // ������߼���ȡ - ������Ӧ��ַ�仯
    always @(*) begin
        read_data = mem[addr];
    end
endmodule